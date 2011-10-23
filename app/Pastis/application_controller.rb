# application_conroller.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.

class ApplicationController
  
  attr_accessor :menu, :filterWindowController, :logsController, :settingsController, :splash
  
  def quit(sender)
    exit
  end
  
  def applicationDidFinishLaunching(notification)
    self.logsController = LogsController.alloc.initWithWindowNibName(LogsController::NIB)
    Pastis.logger <<  "done launching"
    @menu = NSMenu.alloc.init   
    create_menu_items
    splash.center
    start_fetching
  end
    
  def show_controller_window(controller)
    controller.showWindow(self)
    controller.window.center
    controller.window.orderFront(self)
    controller.window.makeKeyAndOrderFront(self) 
    controller.window.orderFrontRegardless
  end
  
  def show_filters(sender)
    unless self.filterWindowController
      self.filterWindowController = FilterWindowController.alloc.initWithWindowNibName("Filters")
    end
    show_controller_window(filterWindowController)
  end
  
  def show_logs(sender)
    unless self.logsController
      self.logsController = logsController.alloc.initWithWindowNibName(LogsController::NIB)
    end
    show_controller_window(logsController)
  end
  
  def show_settings(sender)
    unless self.settingsController
      self.settingsController = SettingsController.alloc.initWithWindowNibName(SettingsController::NIB)
    end
    show_controller_window(settingsController)
  end
  
  def show_torrents(sender)
    `open #{Pastis.new.torrents_local_path}`
  end
  
  def force_run(sender=nil)
    Pastis.new.check
  end
  
  def create_menu_items
    menuItem = menu.addItemWithTitle('Edit Filters', action: 'show_filters:', keyEquivalent: "")
    menuItem = menu.addItemWithTitle('Edit Settings', action: 'show_settings:', keyEquivalent: "")
    menu.addItem(NSMenuItem.separatorItem)

    menuItem = menu.addItemWithTitle('Show Torrents', action: 'show_torrents:', keyEquivalent: "")
    menu.addItem(NSMenuItem.separatorItem)
    
    menuItem = menu.addItemWithTitle('Fetch Torrents', action: 'force_run:', keyEquivalent: "")
    menuItem = menu.addItemWithTitle('Show Logs', action: 'show_logs:', keyEquivalent: "")
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
    Pastis.logger << "start fetching RSS items"
    @timer = NSTimer.scheduledTimerWithTimeInterval fetching_interval,
                                           target: self,
                                           selector: 'force_run:',
                                           userInfo: nil,
                                           repeats: true
    force_run
  end 
  
  def fetching_interval
    # TODO: switch to a user preference value
    # 10 minutes
    600
  end
  
end
