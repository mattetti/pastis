# settings_controller.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.

class SettingsController < NSWindowController
  NIB = 'Settings'
  
  attr_accessor :torrents_location, :filters_location, :rss_feed
  
  def windowDidLoad
    pastaga = Pastis.new
    torrents_location.stringValue = pastaga.torrents_local_path
    filters_location.stringValue = pastaga.filters_path
    rss_feed.stringValue = pastaga.torrent_rss
  end
  
  def torrents_browse(sender)
    dialog = NSOpenPanel.openPanel
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = false

    # Display the dialog and process the selected folder
    if dialog.runModalForDirectory(nil, file:nil) == NSOKButton 
      selection = dialog.filenames.first
      torrents_location.stringValue = dialog.filenames.first.to_s
    end
  end
  
  def filters_browse(sender)
    dialog = NSOpenPanel.openPanel
    dialog.canChooseFiles = true
    dialog.canChooseDirectories = false
    dialog.allowsMultipleSelection = false
    
    # Display the dialog and process the selected folder
    if dialog.runModalForDirectory(nil, file:nil) == NSOKButton 
      selection = dialog.filenames.first
      filters_location.stringValue = dialog.filenames.first.to_s
    end
  end
  
  def save_settings(sender)
    pastaga = Pastis.new
    unless torrents_location.stringValue.size < 3
      NSUserDefaults.standardUserDefaults['pastis.torrents_path'] = torrents_location.stringValue
    end
    unless filters_location.stringValue.size < 3
      NSUserDefaults.standardUserDefaults['pastis.filters_path'] = filters_location.stringValue
    end
    unless rss_feed.stringValue == nil || rss_feed.stringValue.size < 3
      NSUserDefaults.standardUserDefaults['pastis.torrent_rss'] = rss_feed.stringValue
      NSUserDefaults.standardUserDefaults.synchronize
    end
    Pastis.logger << "Settings updated"
  end
  
  def reset_rsslogs(sender)
    Pastis::Logs.clear
  end
  
  private
  
end
