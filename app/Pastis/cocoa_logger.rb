# cocoa_logger.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.


class Logger

  # overwrite the default logger
  def <<(val)
    NSLog(val)
    LogsController.log("#{val}\n")
    history << "#{val}\n"
    clean_history
  end

end