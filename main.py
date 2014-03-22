#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, gtk, gobject, gtk.glade, subprocess, sys, threading, urllib, time, locale, re

class Main:
	def _exit(self, *args):
		gtk.main_quit()
		exit()
	
	def __init__(self):
		self.default_installpath_global = "/usr/local/reaper"
		self.default_installpath_local = os.environ['HOME']+"/.local"
		
		self.reaperfilelocal = None
		self.option_install_local = True
		
		self.option_shortcuts = True
		self.option_wineasio = True
		
		self.errorlog = ""
		
		self.widgets = CreateWidgets(self)
		icons = map(lambda i: gtk.gdk.pixbuf_new_from_file("./scripts/gnome/"+str(i)+"x"+str(i)+"/apps/reaper.png"), [16,32,48,96,128,256])
		self.widgets['window'].set_icon_list(*icons)
		self.widgets['image-icon'].set_from_pixbuf(icons[1])
		
		# Select the home folder as the base for choosing the Reaper installer
		self.widgets['filechooserbutton-installer'].set_current_folder(os.environ['HOME'])
		# Select the option to install locally
		self.widgets['filechooserbutton-path'].set_current_folder(self.default_installpath_local)
		
		if len(sys.argv) > 1:
			self.reaperfilelocal = os.path.abspath(sys.argv[1])
			self.widgets['filechooserbutton-installer'].set_filename(self.reaperfilelocal)
			self.widgets['radiobutton-installer-file'].set_active(True)
			self.select_local_installer(True)
		
		# Set the default install options
		self.widgets['checkbutton_shortcuts'].set_active(self.option_shortcuts)
		### Deprecated ###
		#self.widgets['checkbutton_wineasio'].set_active(self.option_wineasio)
		
		self.widgets['progressbar_install'].set_pulse_step(0.01)
	
	def select_version(self, treeview):
		# If we were called from inside the program, assume that the first row was selected
		if treeview.get_selection().get_selected()[1] == None:
			self.selected_version = self.versions[0]
		else:
			selected = treeview.get_model().get_path(treeview.get_selection().get_selected()[1])[0]
			self.selected_version = self.versions[selected]
	
	def select_local_installer(self, button):
		if type(button) == type(True):
			self.local_installer = button
		else:
			self.local_installer = button.get_active()
		
		if self.local_installer:
			self.widgets['filechooserbutton-installer'].set_sensitive(True)
			self.widgets['button_next'].set_sensitive(False)
			if self.reaperfilelocal != None:
				self.widgets['button_next'].set_sensitive(True)
			else:
				self.widgets['button_next'].set_sensitive(False)
		else:
			self.widgets['filechooserbutton-installer'].set_sensitive(False)
			self.widgets['button_next'].set_sensitive(True)
	
	def set_local_installer(self, filechooser):
		filenames = filechooser.get_filenames()
		if len(filenames):
			self.reaperfilelocal = filechooser.get_filenames()[0]
			self.widgets['button_next'].set_sensitive(True)
		else:
			self.widgets['button_next'].set_sensitive(False)
	
	def select_installation_path(self, button):
		# If globally
		if button.get_active():
			self.installpath = self.default_installpath_global
			self.widgets['filechooserbutton-installer'].set_sensitive(False)
		else:
			self.widgets['filechooserbutton-installer'].set_sensitive(True)
			self.installpath = (self.widgets['filechooserbutton-installer'].get_filename() or self.default_installpath_local) + '/' + ( self.widgets['entry_install_local'].get_text() or "reaper")
	
	def select_local_path(self, filechooser):
		self.installpath = filechooser.get_current_folder() + '/' + self.widgets['entry_install_local'].get_text()
	
	def change_installation_path(self, entry):
		self.installpath = self.widgets['filechooserbutton-installer'].get_filename() + '/' + entry.get_text()
	
	def select_shortcuts(self, button):
		self.option_shortcuts = button.get_active()
	
	def select_wineasio(self, button):
		self.option_wineasio = button.get_active()
	
	
	def next(self, button):
		self.widgets['notebook'].next_page()
		if self.widgets['notebook'].get_current_page() == 1:
			if self.reaperfilelocal == None:
				self.select_local_installer(False)
			else:
				self.selected_version = "local"
				self.select_local_installer(True)
				self.widgets['check_local_installer'].set_active(True)
		elif self.widgets['notebook'].get_current_page() == 2:
			do_install()

def do_install():	
	main.rundir = os.path.dirname(os.path.abspath(sys.argv[0]))
	
	main.widgets['button_next'].set_sensitive(False)
	
	# If set to use local installer
	#if main.widgets['check_local_installer'].get_active() is True:
	if main.local_installer is True:
		print "Using local Reaper installer"
		main.reaperfile = main.reaperfilelocal
		do_install_run()
	else:
		print "Downloading Reaper"
		main.widgets['label_install'].set_text("Downloading Reaper...")
		#main.reaperfile = "/tmp/"+os.path.basename(main.selected_version['url'])
		#main.reaperurl = get_version_url()
		#main.reaperfile = "/tmp/"+os.path.basename(main.reaperurl)
		run(main.rundir+"/scripts/get_reaper.sh", [], do_install_run, do_error)

def do_install_run():
	#print "Create Wine setup and run the installer"
	main.widgets['label_install'].set_text("Creating Wine setup and running the installer\n(just accept the defaults and don't run Reaper if asked)...")
	if hasattr(main, 'reaperfile') and len(main.reaperfile):
		run(main.rundir+"/scripts/run_install.sh", [main.installpath, main.reaperfile], do_install_setup_config, do_error)
	else:
		run(main.rundir+"/scripts/run_install.sh", [main.installpath], do_install_setup_config, do_error)

def do_install_setup_config():
	#print "Setup installation"
	main.widgets['label_install'].set_text("Setting up installation...")
	run(main.rundir+"/scripts/setup_config.sh", [main.installpath], do_install_setup_shortcuts, do_error)

def do_install_setup_shortcuts():
	#print "Add options"
	if main.option_shortcuts == True:
		main.widgets['label_install'].set_text("Creating shortcuts...")
		run(main.rundir+"/scripts/setup_shortcuts.sh", [main.installpath], do_install_setup_wineasio, do_error)
	else:
		do_install_setup_wineasio()

def do_install_setup_wineasio():
	if main.option_wineasio == True:
		main.widgets['label_install'].set_text("Setting up WineAsio...")
		run(main.rundir+"/scripts/setup_wineasio.sh", [main.installpath], do_install_finish, do_error)
	else:
		do_install_finish()

def do_install_finish():
	main.widgets['notebook'].next_page()
	main.widgets['button_next'].set_sensitive(True)
	main.widgets['button_next'].set_label("Done")
	main.widgets['button_next'].connect("clicked", main._exit)

def do_error():
	main.widgets['label_install'].set_text("An error has occured.\nPlease check the console output for more info.")
	main.widgets['progressbar_install'].hide()
	main.widgets['button_cancel'].set_sensitive(False)
	main.widgets['button_next'].set_sensitive(True)
	main.widgets['button_next'].set_label("Quit")
	main.widgets['button_next'].connect("clicked", main._exit)
	
def run(command, arguments, finished_function, error_function):
	thread = threading.Thread(target=run_process, args=[command, arguments, finished_function, error_function])
	thread.start()

def run_process(command, arguments, finished_function, error_function):
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
		if procent:
			gtk.gdk.threads_enter()
			main.widgets['progressbar_install'].set_fraction( float(procent) / 100 )
			gtk.gdk.threads_leave()
		else:
			gtk.gdk.threads_enter()
			main.widgets['progressbar_install'].pulse()
			gtk.gdk.threads_leave()
		sys.stdout.write(line)
	
	main.errorlog += output
	
	if p.returncode != 0:
		error_function()
	else:
		finished_function()


def get_version_url():
    baseurl = 'http://reaper.fm/download.php'
    url = urllib.urlopen(baseurl)
    url = url.read()
    url = re.search('<a href="([^"]*reaper[\d\.\-]+-install.exe)">Windows \(', url).groups()[0]
    if url:
        if '://' not in url[:8]:
            url = 'http://reaper.fm/'+url
        return url
    else:
        return None

def get_version_urls():
	baseurl = 'http://reaper.fm/files/2.x/'
	# Get the HTML listing of the available Reaper versions
	reaperlisting = urllib.urlopen(baseurl)
	reaperlisting = "\n".join( reaperlisting.readlines() )
	
	# Split the HTML so it only contains the table rows with the files
	try:
		reaperlisting = filter(len, reaperlisting.split('<hr></th></tr>')[1].split("\n")[:-2])
	
		# Filter through the table rows, extracting the data we need
		versions = {}
		for row in reaperlisting[1:]:
			url = baseurl + row.split('<a href="')[1].split('">')[0].lower()
			# Skip if this version is for x64, as Wine can't handle it yet - also discard zip, dll and dmg files
			if 'x64' in url or url.endswith('.zip') or url.endswith('.dll') or url.endswith('.dmg'):
				continue
			date = row.split('<td align="right">')[1].split('</td>')[0].strip()
			dateint = int( ''.join(map(lambda i: "%02d" % i, time.strptime(date, "%d-%b-%Y %H:%M")[:3])) )
			try:
				name = "Version 2." + url.split('/')[-1].split('reaper2')[1].split('-install')[0]
				if '_' in name:
					name = name.split('_')[0]+" ("+name.split('_')[1]+")"
			except:
				print "Error, couldn't parse "+url
			versions[dateint] = {'url':url, 'date':date, 'name':name}
		# Get the dates of the versions and sort them
		dates = versions.keys()
		dates.sort()
		# Return the versions as a sorted list
		versions = [ versions[i] for i in dates ]
		versions.reverse()
	except IndexError:
		versions = []
	return versions


class CreateWidgets:
	def __init__(self, handlerclass, file="linreaper.glade", name="linreaper"):
		self.widgets = gtk.glade.XML(file, None, name)
		self.widgets.signal_autoconnect(handlerclass)
		self.ownwidgets = {}
	def __getitem__(self, key):
		if key not in self.ownwidgets:
			return self.widgets.get_widget(key)
		else:
			return self.ownwidgets[key]
	def __setitem__(self, key, value):
		self.ownwidgets[key] = value

if __name__ == "__main__":
	locale.setlocale(locale.LC_ALL, "C")
	try:
		gobject.threads_init()
		gtk.gdk.threads_init()
		global main
		gtk.gdk.threads_enter()
		main = Main()
		gtk.main()
		gtk.gdk.threads_leave()
	finally:
		pass
