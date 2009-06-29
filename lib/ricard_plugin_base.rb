module Ricard
  module PluginBase
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    # returns the available commands
    # for this plugin
    def commands
      self.class.commands
    end
    
    module ClassMethods
      # call made by the server
      def execute(command)
        if commands.include?(command)
          plugin_instance.send(command)
        else
          raise "#{command} not found! for #{self.class.name}"
        end
      end 

      def commands
        self.instance_methods - Object.instance_methods
      end

      def plugin_instance
        @plugin_instance ||= self.new
      end
    end
    
  end
  
end