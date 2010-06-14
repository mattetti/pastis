# application_conroller.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.

class ApplicationController
  
  attr_accessor :menu, :filterWindowController
  
  def quit(sender)
    puts "ciao ciao"
    exit
  end
  
  def applicationDidFinishLaunching(notification)
    puts "done launching"
    @menu = NSMenu.alloc.init   
    create_menu_items
  end
  
  def showFilters(sender)
    unless self.filterWindowController
      self.filterWindowController = FilterWindowController.alloc.initWithWindowNibName("Filters")
    end
    filterWindowController.showWindow(self)
  end
  
  def create_menu_items
    menuItem = menu.addItemWithTitle('Filters', action: 'showFilters:', keyEquivalent: "")
    menu.addItem(NSMenuItem.separatorItem)

    menuItem = menu.addItemWithTitle("Quit", action: 'quit:', keyEquivalent: "q")
    menuItem.toolTip = "Click to Quit this App"
    menuItem.target = self

    statusItem = NSStatusBar.systemStatusBar.statusItemWithLength(NSSquareStatusItemLength)
    statusItem.menu = menu
    statusItem.highlightMode = true
    statusItem.toolTip = "Pastis - Transmission tool"
    statusItem.image = NSImage.imageNamed("mini_pastis")
  end
  
end
