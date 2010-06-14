# filter_window_controller.rb
# filterer
#
# Created by Matt Aimonetti on 10/23/09.
# Copyright 2010 m|a agile. All rights reserved.

require 'yaml'
require 'table_filter'

class FilterWindowController < NSWindowController
 # windows/panels
 attr_accessor :add_sheet, :main_window
 # table view
 attr_accessor :filterTableView
 # fields
 attr_accessor :inclusive_name, :exclusive_name, :close_button, :location

  # def awakeFromNib
  # end
  
  def windowDidLoad
    retrieve_filters
    # define the selector to call when the user double clicks
    filterTableView.doubleAction = "edit:" 
  end
  
  def windowWillClose(sender)
    exit
  end
  
  def orderFrontStandardAboutPanel(sender)
    puts "orderFrontStandardAboutPanel"
  end

  def show(sender)
    window.center
    showWindow(sender)
  end
  
  def yaml_file
    yaml_file = Pastis.new.filters_path #File.expand_path('~/pastis_filters.yml')
    unless File.exist?(yaml_file)
      File.open(yaml_file, 'w+'){|f| f << [{:inclusive_rules => ['TED'], :exclusive_rules => ['720p'], :location => File.expand_path("~/Downloads") }].to_yaml}
    end
    yaml_file
  end
  
  def retrieve_filters
    @filters = YAML.load_file(yaml_file).map{|data| TableFilter.new(data)} || []
    sortable_filters
    self.filterTableView.dataSource = self
  end
  
  def sortable_filters
    def @filters.sorted_order=(val); @sorted_order = val; end
    def @filters.sorted_order; @sorted_order; end
    @filters.sorted_order = 'asc'
    @filters.sort!{|a,b| a.filter_key <=> b.filter_key}
  end
  
  def numberOfRowsInTableView(view)
    @filters.size
  end
  
  def tableView(view, sortDescriptorsDidChange: descriptors)
    if @filters.sorted_order == 'asc'
      @filters.sort!{|b,a| a.filter_key <=> b.filter_key}
      @filters.sorted_order = 'desc'
    else
      @filters.sort!{|a,b| a.filter_key <=> b.filter_key}
      @filters.sorted_order = 'asc'
    end
    filterTableView.reloadData
  end

  def tableView(view, objectValueForTableColumn:column, row:index)
    filter = @filters[index]
    case column.identifier
      when 'inclusive'
        filter.inclusive_rules ? filter.inclusive_rules.join(', ') : ""
      when 'exclusive'
        filter.exclusive_rules ? filter.exclusive_rules.join(', ') : ""
      when 'location'
        filter.location || ""
    end
  end

#   def add(sender)
#    add(sender, nil)
#   end
  
  def add(sender, mode=nil)
    # use a flag to set if the view should be in add or edit mode
    # this is a hack that breaks IB
    change_sheet_mode(mode)
    exclusive_name.stringValue ||= '720p'
		NSApp.beginSheet(@add_sheet, 
			modalForWindow:@main_window, 
			modalDelegate:self, 
			didEndSelector:nil,
			contextInfo:nil)
	end
  
  def edit(sender)
    if self.filterTableView.selectedRow != -1
      inclusive_name.stringValue = @filters[filterTableView.selectedRow].stringified_inclusive_rules
      exclusive_name.stringValue = @filters[filterTableView.selectedRow].stringified_exclusive_rules
      location.stringValue =  @filters[filterTableView.selectedRow].location || ''
      add(nil, :update)
    elsif sender.class == NSButton
      alert
    end
  end
  
  def close_add(sender)
    if @sheet_mode == :add
      add_filter!
    else
      edit_filter!
    end
		@add_sheet.orderOut(nil)
    NSApp.endSheet(@add_sheet)
	end
  
  def change_sheet_mode(mode)
    mode = :add if mode.class == NSButton
    @sheet_mode = mode || :add
    close_button.title = @sheet_mode.to_s.capitalizedString
  end
  
  def cancel(sender)
    @add_sheet.orderOut(nil)
    NSApp.endSheet(@add_sheet)
  end
  
  def remove(sender)
    if filterTableView.selectedRow != -1
      @filters.delete_at(filterTableView.selectedRow)
      save_filters
    else
      alert
    end
  end
  
  def browse(sender)
    # Create the File Open Dialog class.
    dialog = NSOpenPanel.openPanel
    # Disable the selection of files in the dialog.
    dialog.canChooseFiles = false
    # Enable the selection of directories in the dialog.
    dialog.canChooseDirectories = true
    # Disable the selection of multiple items in the dialog.
    dialog.allowsMultipleSelection = false

    # Display the dialog and process the selected folder
    if dialog.runModalForDirectory(nil, file:nil) == NSOKButton 
      selection = dialog.filenames.first
      location.stringValue = dialog.filenames.first.to_s
    end
  end
  
  def add_filter!
    new_filter = TableFilter.new
    new_filter.inclusive_rules = inclusive_name.stringValue.split(',').map{|rule| rule.strip} unless inclusive_name.stringValue.empty?
    new_filter.exclusive_rules = exclusive_name.stringValue.split(',').map{|rule| rule.strip} unless exclusive_name.stringValue.empty?
    new_filter.location        = location.stringValue
    unless new_filter.inclusive_rules.nil?
     @filters << new_filter
     save_filters
    end
  end
  
  def edit_filter!
    updated_rule = TableFilter.new
    updated_rule.inclusive_rules = inclusive_name.stringValue.split(',').map{|rule| rule.strip}
    updated_rule.exclusive_rules = exclusive_name.stringValue.split(',').map{|rule| rule.strip}
    updated_rule.location        = location.stringValue
    @filters[filterTableView.selectedRow] = updated_rule
    save_filters
  end
  
  def save_filters    
    File.open(yaml_file, 'w'){|f| f << @filters.map{|filter| filter.to_hash}.to_yaml}
    retrieve_filters
    filterTableView.reloadData
  end
  
  def alert(title='Nothing Selected', message='You need to select a row before clicking on this button.')
    NSAlert.alertWithMessageText(title, 
                                    defaultButton: 'OK',
                                    alternateButton: nil, 
                                    otherButton: 'Cancel',
                                    informativeTextWithFormat: message).runModal
  end
  
end
