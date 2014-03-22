#!/usr/bin/python
# -*- coding: utf-8 -*-

import pygtk
pygtk.require('2.0')
import gtk, gobject, gtk.glade, os, sys, subprocess
import locale, gettext

class Main:
	def _exit(self, *args):
		gtk.main_quit()
		exit()
	
	def __init__(self):
		self.filename = None
		self.path = os.path.abspath(os.path.dirname(sys.argv[0]))
		
		self.widgets = CreateWidgets(self)
		
		self.widgets['vbox_win_install'].drag_dest_set(gtk.DEST_DEFAULT_MOTION | gtk.DEST_DEFAULT_HIGHLIGHT | gtk.DEST_DEFAULT_DROP, [ ( "text/plain", 0, 80 ), ( "text/uri-list", 0, 80 ) ], gtk.gdk.ACTION_COPY)

		filter = gtk.FileFilter()
		filter.set_name("Windows executables")
		#filter.add_mime_type("application/x-executable")
		filter.add_pattern("*.[eE][xX][eE]")
		filter.add_pattern("*.[mM][sS][iI]")
		self.widgets['filechooserbutton_win_install'].add_filter(filter)

		filter = gtk.FileFilter()
		filter.set_name("All files")
		filter.add_pattern("*")
		self.widgets['filechooserbutton_win_install'].add_filter(filter)
		
		
		filter = gtk.FileFilter()
		filter.set_name("Reaper Projects")
		#filter.add_mime_type("application/x-executable")
		filter.add_pattern("*.[rR][pP][pP]")
		filter.add_pattern("*.[rR][pP][pP]-[bB][aA][kK]")
		self.widgets['filechooserbutton_render'].add_filter(filter)

		filter = gtk.FileFilter()
		filter.set_name("All files")
		filter.add_pattern("*")
		self.widgets['filechooserbutton_render'].add_filter(filter)
		
		
		filter = gtk.FileFilter()
		filter.set_name("Reaper Configuration Files")
		#filter.add_mime_type("application/x-executable")
		filter.add_pattern("*.[iI][nN][iI]")
		filter.add_pattern("*.[tT][xX][tT]")
		self.widgets['filechooserbutton_conf'].add_filter(filter)

		filter = gtk.FileFilter()
		filter.set_name("All files")
		filter.add_pattern("*")
		self.widgets['filechooserbutton_conf'].add_filter(filter)

	def motion_cb(self, wid, context, x, y, time):	
		context.drag_status(gtk.gdk.ACTION_COPY, time)
		return True

	def drop_cb(self, wid, context, x, y, time):
		#l.set_text('\n'.join([str(t) for t in context.targets]))
		context.finish(True, False, time)
		return True


	def data_received(self, wid, context, x, y, selection, targettype, time):
		if targettype == 80:
			text = selection.data
			if text.startswith('file://'): text = text.split('file://')[1][:-2]
			self.filename = text.replace('%20', ' ')
			self.widgets['filechooserbutton_win_install'].set_filename(self.filename)
			self.widgets['button_run'].set_sensitive(True)


	def filechooser_selected(self, filechooser):
		filenames = filechooser.get_filenames()
		if len(filenames):
			self.filename = filenames[0]
			self.widgets['button_run'].set_sensitive(True)
		else:
			self.widgets['button_run'].set_sensitive(False)
	
	def render_selection_changed(self, filechooser):
		filenames = filechooser.get_filenames()
		if len(filenames):
			self.filename_render = filenames[0]
			self.widgets['button_reaper_render'].set_sensitive(True)
		else:
			self.widgets['button_reaper_render'].set_sensitive(False)
	
	def conf_selection_changed(self, filechooser):
		filenames = filechooser.get_filenames()
		if len(filenames):
			self.filename_conf = filenames[0]
			self.widgets['button_reaper_conf'].set_sensitive(True)
		else:
			self.widgets['button_reaper_conf'].set_sensitive(False)

	
	def open_reaper_render(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__RENDER__", self.filename_render]).pid
	
	def open_reaper_audio(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__AUDIOCONF__"]).pid
	
	def open_reaper_conf(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__CONF__", self.filename_conf]).pid
	
	def open_vst(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__VSTFOLDER__"]).pid

	def open_js(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__JSFOLDER__"]).pid
	
	def open_winecfg(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__WINECFG__"]).pid

	def open_regedit(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, "__REGEDIT__"]).pid

	def run_installer(self, *args):
		self.pid = subprocess.Popen(["%s/.conftool.sh" % self.path, self.filename]).pid



class CreateWidgets:
	def __init__(self, handlerclass, file=".conf.glade", name="linreaper"):
		self.widgets = gtk.glade.XML("%s/%s" % (handlerclass.path, file), None, name)
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
