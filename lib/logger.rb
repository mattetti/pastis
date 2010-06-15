class Logger
  
  attr_accessor :cocoa_log_tv
  attr_accessor :history
  
  def initialize
    @history = ""
  end
  
  def <<(val)
    if self.cocoa_log_tv
      # post the logs to the the text view
      puts "[TODO] cocoa output"
      puts val
      history << "#{val}\n"
      clean_history
    else
      # output to the console
      puts "cocoa_log_tv nil"
      puts val
    end
  end
  
  def clean_history
    if history && history.count("\n") > 100
      lines = history.split("\n")
      while lines.size > 100
        lines.shift
      end
      self.history = lines.join("\n")
    end
  end
  
end