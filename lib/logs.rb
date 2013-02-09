class Pastis
  module Logs          
    LOG_FILE = '~/.pastis-rsslog'.stringByStandardizingPath
  
    module_function
  
    def log_file
      @log ||= File.exist?(LOG_FILE) ? File.open(LOG_FILE, 'r+') : File.new(LOG_FILE, 'w+')
    end

    def log_data
      @log_data ||=  begin; Marshal.load(log_file.read); rescue; []; end;
    end 

    def add(guid, filename, timestamp) 
      # puts "logging #{filename}"
      log_data << {:guid => guid, :filename => filename, :timestamp => timestamp, :added_at => Time.now} unless include?(guid)
      #save
    end

    def save
      if log_data.nil? || log_data.empty?
        Pastis.logger << "Nothing to save, odd!"
      else
        Pastis.logger << "Saving logs"
        File.open(log_file, 'w+'){|f| f << Marshal.dump(log_data)}
        #data = Marshal.dump(log_data).to_data
        # data.writeToFile(NSURL.URLWithString(log_file), atomically:true)
        prune
      end
      
    end            

    def include?(guid)
      log_data.find{|item| item[:guid] == guid}
    end 

    def prune
      log_data.delete_if{|item| item[:added_at] < (Time.now - (60 * 60 * 24 * 31)) }
    end

    def clear
      `rm #{LOG_FILE}`
      @log_data = nil
    end        

  end 
end