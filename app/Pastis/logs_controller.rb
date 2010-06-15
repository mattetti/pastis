# logs_controller.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.

class LogsController < NSWindowController
  NIB = 'Logs'
  
  attr_accessor :logs
  
  def initWithWindowNibName(nibName)
    super
    # make the logger instance available via class itself
    self.class.instance_variable_set("@singleton_instance", self)
    self
  end
  
  def windowDidLoad
    log(Pastis.logger.history)
  end
  
  def self.log(val)
    if @singleton_instance
      @singleton_instance.log(val)
    end
  end
  
  def log(data_string)
    if logs 
      ts = logs.textStorage
      range = NSMakeRange(ts.length, 0)
      ts.replaceCharactersInRange(range, withString:data_string)
      logs.scrollRangeToVisible(range, 0)
    end
  end  
  
end