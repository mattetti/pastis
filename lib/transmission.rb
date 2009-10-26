module Transmission
  def self.add_to_queue(file, destination)
    begin
      t = Transmission::Client.new
    rescue
      puts "Couldn't connect to Transmission, make sure it's on."
    else
      puts "adding #{file} to download."
      t.add_torrent(  'filename' => File.expand_path(file), 
                      'download-dir' => File.expand_path(destination))	
    end
  end
end