#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2007-2011 Christian Dannie Storgaard
#
# AUTHOR:
# Christian Dannie Storgaard <cybolic@gmail.com>
#

from __future__ import print_function

import gtk, pango, gobject
import os, sys, subprocess, threading, time
import urllib2


def widget_get_char_width(widget):
    pango_context = widget.get_pango_context()
    return int(pango.PIXELS(
        pango_context.get_metrics(
            pango_context.get_font_description()
            ).get_approximate_char_width()))

def widget_get_char_height(widget):
    """
    Return maximum height in pixels of a single character.
    We create a Pango Layout, put in a line of lowercase+uppercase letters
    and read the height of the line."""
    pango_layout = pango.Layout(widget.get_pango_context())
    pango_layout.set_text(sys.modules['string'].ascii_letters)
    extents = pango_layout.get_line(0).get_pixel_extents()
    return int(extents[0][3] - extents[0][1])

class Dialog(gtk.Dialog):
    def __init__(self):

        gtk.Dialog.__init__(self,
            title = "Checking if there's a new version of Reaper available...",
        )

        self.scrolledwindow = gtk.ScrolledWindow()
        self.scrolledwindow.set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)
        self.scrolledwindow.set_size_request(
            widget_get_char_width(self.scrolledwindow)*120,
            widget_get_char_height(self.scrolledwindow)*10
        )

        self.textview = gtk.TextView()
        self.textview.get_buffer().set_text("Checking...")
        fontdescr = pango.FontDescription('monospace 8')
        self.textview.modify_font(fontdescr)
        self.textview.set_cursor_visible(False)
        self.scrolledwindow.add(self.textview)

        self.vbox.pack_start(self.scrolledwindow)

        self.add_button(gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL)

        self.set_default_response(gtk.RESPONSE_CANCEL)

        self.button_cancel = self.action_area.get_children()[0]
        self.button_cancel.connect('clicked', self.__cancel_clicked)

        self.show_all()

        self.errorlog = ""
        self.return_code = 0
        self.changelog = None
        self.thread = start_thread(self.get_changelog, self.show_changes)


    def __cancel_clicked(self, button):
        try:
            gtk.main_quit()
            self.destroy()
        except:
            pass
        exit(self.return_code)

    def get_changelog(self):
        self.current_version = get_current_version()
        #self.changelog = 'v4.30 - ' # for testing
        self.changelog = get_changelog()
        print(self.changelog)

    def show_changes(self):
        self.new_version = float(self.changelog.split(' ')[0][1:])
        if float(self.current_version) < self.new_version:
            self.button_cancel.set_label('gtk-cancel')
            self.button_cancel.set_use_stock(True)
            self.button_cancel.set_label("Ignore")
            self.set_title("There's a new version of Reaper available")
            self.add_button("Go to download page", gtk.RESPONSE_OK)
            self.add_button("Update", gtk.RESPONSE_YES)
            self.button_update = self.action_area.get_children()[0]
            self.button_web = self.action_area.get_children()[1]
            gtk.settings_get_default().set_property('gtk-alternative-button-order', True)
            self.set_alternative_button_order([
                gtk.RESPONSE_OK, gtk.RESPONSE_YES, gtk.RESPONSE_CANCEL
            ])
            self.scrolledwindow.set_size_request(
                widget_get_char_width(self.scrolledwindow)*120,
                widget_get_char_height(self.scrolledwindow)*min(len(self.changelog.split('\n')), 10)
            )
            self.textview.get_buffer().set_text(self.changelog)

            self.button_update.connect('clicked', self.update_clicked)
            self.button_web.connect('clicked', self.web_clicked)
        else:
            self.destroy()
            exit(0)


    def web_clicked(self, button):
        # Go to download page
        subprocess.Popen(
            'xdg-open http://reaper.fm/download.php', shell = True
        )
        self.destroy()
        exit(0)

    def update_clicked(self, button):
        self.button_cancel.set_sensitive(False)
        self.label = gtk.Label("Downloading Reaper {0}".format(self.new_version))
        self.label.set_alignment(0.0, 0.5)
        self.progressbar = gtk.ProgressBar()
        self.progressbar.set_pulse_step(0.01)
        self.vbox.pack_start(self.label)
        self.vbox.pack_start(self.progressbar)
        self.show_all()
        run(
            #get_install_dir()+"/scripts/get_reaper.sh",
            "echo 'Hello'",
            [],
            self.do_install_run,
            self.do_error,
            self.progressbar
        )

    def do_install_run(self):
        self.label.set_text("Installing Reaper {0}".format(self.new_version))
        run(
            get_install_dir()+"/scripts/run_install.sh",
            [get_install_dir()],
            self.do_install_finish,
            self.do_error,
            self.progressbar
        )

    def do_install_finish(self):
        self.label.set_text("Reaper updated succesfully to version {0}".format(self.new_version))
        self.progressbar.set_fraction(1.0)
        self.button_cancel.set_sensitive(True)
        self.button_cancel.set_label('gtk-ok')
        self.button_cancel.set_use_stock(True)
        self.button_cancel.set_label("Run Reaper")
        self.return_code = -1

    def do_error(self):
        main.widgets['label_install'].set_text("An error has occured.\nReaper wasn't updated.")
        self.button_cancel.set_sensitive(True)
        self.button_cancel.set_label('gtk-ok')
        self.button_cancel.set_use_stock(True)
        self.button_cancel.set_label("Run old Reaper")
        self.progressbar.hide()





def run(command, arguments, finished_function, error_function, progressbar=None):
    thread = threading.Thread(target=run_process, args=[command, arguments, finished_function, error_function, progressbar])
    thread.daemon = True
    thread.start()

def run_process(command, arguments, finished_function, error_function, progressbar=None):
    #print "Running command:",command
    p = subprocess.Popen(command + ' ' + ' '.join(arguments), shell=True,
          stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, close_fds=True)

    output = ""
    while p.poll() == None:
        line = os.read(p.stdout.fileno(), 32)
        procent = None
        if line:
            output += line
            lastline = output.split("\n")[-1].strip()
            if lastline and '%' in lastline:
                if len(lastline.split('%')) > 2:
                    procent = lastline.split('%')[-2].split()[-1]
                else:
                    procent = lastline.split('%')[0].split()[0]
        if progressbar is not None:
            if procent:
                gtk.gdk.threads_enter()
                progressbar.set_fraction( float(procent) / 100 )
                gtk.gdk.threads_leave()
            else:
                gtk.gdk.threads_enter()
                progressbar.pulse()
                gtk.gdk.threads_leave()
            sys.stdout.write(line)

    main.errorlog += output

    if p.returncode != 0:
        error_function()
    else:
        finished_function()


def start_thread(function, finished_function):
    thread = threading.Thread(target=function)
    thread.daemon = True
    thread.start()
    while thread.isAlive():
        while gtk.events_pending():
            gtk.main_iteration()
            time.sleep(0.1)
    finished_function()


def get_internet_available():
    if len(subprocess.Popen(
        'which ip', shell = True, stdout=subprocess.PIPE
    ).communicate()[0].strip()):
        # Try testing for IPv4 with the ip command first
        if len(subprocess.Popen(
            'ip -4 route', shell = True, stdout=subprocess.PIPE
        ).communicate()[0]):
            return True
    return False


def get_install_dir():
    path = os.path.dirname(sys.argv[0])
    if not os.path.exists(os.path.join(path, '.wine')):
        path = os.path.expanduser('~/.local/reaper')
    return path


def get_wine_env(key):
    value = subprocess.Popen(
        'grep \'"{key}"=\' {path}/.wine/system.reg'.format(
            key = key,
            path = get_install_dir()
        ), shell = True, stdout=subprocess.PIPE
    ).communicate()
    value = value[0].strip().split('="')[1][0:-1]
    return value


def get_filename(path, filename):
    """Get the filename of a basename regardless of case.
    Returns "path/filename" if none was found."""
    try:
        matches = [
            name for name
            in os.listdir(path)
            if name.lower() == filename.lower()
        ]
        if len(matches):
            return os.path.join(path, matches[0])
        else:
            return os.path.join(path, filename)
    except OSError:
        return os.path.join(path, filename)


def get_reaper_dir():
    if 'ProgramFilesUnix' in os.environ:
        path_program_files = os.environ['ProgramFilesUnix']
    else:
        path_program_files = get_wine_env('ProgramFiles')
    path_program_files = path_program_files.split('C:\\\\')[1]

    return get_filename(
        os.path.join(get_install_dir(), '.wine', 'drive_c', path_program_files),
        'REAPER'
    )


def get_online_check_setting():
    if 'APPDATA' in os.environ:
        path_settings = os.environ['APPDATA']
    else:
        path_settings = get_wine_env('APPDATA')
    path_settings = path_settings.split('C:\\\\')[1].replace('\\', '/')

    filename = get_filename(
        os.path.join(get_install_dir(), '.wine', 'drive_c', path_settings),
        'REAPER'
    )
    filename = get_filename(filename, 'REAPER.ini')

    with open(filename, 'r') as _file:
        setting = [
            line for line
            in _file
            if line.startswith('verchk=')
        ]
    if len(setting) and setting[0].strip().split('=')[1] == '1':
        return True
    else:
        return False


def get_current_version():
    with open(os.path.join(get_reaper_dir(), 'whatsnew.txt'), 'r') as _file:
        version_current = _file.read().split(' ')[0][1:]
    return version_current


def get_changelog():
    try:
        _file = urllib2.urlopen('http://reaper.fm/whatsnew.txt')
        changelog = []
        for line in _file:
            if len(line.strip()):
                changelog.append(line)
            else:
                break
        return ''.join(changelog)
    except:
        return 'v0.0 - Error'


if __name__ == "__main__":
    try:
        if get_online_check_setting() and get_internet_available():
            gobject.threads_init()
            gtk.gdk.threads_init()
            gtk.gdk.threads_enter()
            main = Dialog()
            gtk.main()
            gtk.gdk.threads_leave()
            exit(main.return_code)
    finally:
        pass

