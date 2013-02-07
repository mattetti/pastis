class Logger
  
  attr_accessor :cocoa_log_tv
  attr_accessor :history
  
  def initialize
    @history = ""
  end
  
  def clean_history
    if history && history.count("\n") > 300
      lines = history.split("\n")
      while lines.size > 300
        lines.shift
      end
      self.history = lines.join("\n")
    end
  end
  
end