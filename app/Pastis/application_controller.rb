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
    start_fetching
  end
  
  def show_filters(sender)
    unless self.filterWindowController
      self.filterWindowController = FilterWindowController.alloc.initWithWindowNibName("Filters")
    end
    filterWindowController.showWindow(self)
  end
  
  def show_torrents(sender)
    `open #{Pastis.new.torrents_local_path}`
  end
  
  def force_run(sender=nil)
    Pastis.new.check
  end
  
  def create_menu_items
    menuItem = menu.addItemWithTitle('Edit Filters', action: 'show_filters:', keyEquivalent: "")
    menu.addItem(NSMenuItem.separatorItem)

    menuItem = menu.addItemWithTitle('Show Torrents', action: 'show_torrents:', keyEquivalent: "")
    menu.addItem(NSMenuItem.separatorItem)
    
    menuItem = menu.addItemWithTitle('Fetch Torrents', action: 'force_run:', keyEquivalent: "")
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
  
  def start_fetching
    puts "start fetching RSS items"
    @timer = NSTimer.scheduledTimerWithTimeInterval fetching_interval,
                                           target: self,
                                           selector: 'force_run:',
                                           userInfo: nil,
                                           repeats: true
    force_run
  end 
  
  def fetching_interval
    # TODO: switch to a user preference value
    # 5 minutes
    300
  end
  
end
