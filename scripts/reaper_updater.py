#!/usr/bin/python
# -*- coding: utf-8 -*-

import os, gtk, gobject, gtk.glade, subprocess, sys, threading, urllib, time, locale, re


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
