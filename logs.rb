module Logs          
  
  LOG_FILE = '.rsslog'
  
  def log
    @log ||= File.exist?(LOG_FILE) ? File.open(LOG_FILE, 'r+') : File.new(LOG_FILE, 'w+')
  end

  def log_data
    @log_data ||=  begin; Marshal.load(log.read); rescue; []; end;
  end 

  def add_to_logs(guid, filename, timestamp) 
    log_data << {:guid => guid, :filename => filename, :timestamp => timestamp, :added_at => Time.now} if not_in_logs?(guid)
  end

  def save_logs
    prune_logs
    log << Marshal.dump(log_data)
    log.close
    @log_data = nil
  end            

  def not_in_logs?(guid)
    !log_data.map{|item| item[:guid]}.include?(guid)
  end 
  
  def prune_logs
    log_data.delete_if{|item| item[:added_at] < (Time.now - (60 * 60 * 24 * 31)) }
  end
  
  def clear_logs
    `rm .rsslog`
  end        
  
end