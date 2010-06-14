class Pastis
  
  # Simple filter using strings and regexps
  class Filter
    attr_reader :inclusive_rules
    attr_reader :exclusive_rules
    attr_reader :location
    
    class WrongArguments < StandardError; end
    
    def initialize(attrs={})
      raise(WrongArguments, "you need to pass at least an inclusive rule") unless attrs.has_key?(:inclusive_rules)
      @inclusive_rules = attrs[:inclusive_rules].is_a?(Array) ? attrs[:inclusive_rules] : [attrs[:inclusive_rules]]
      if attrs.has_key?(:exclusive_rules)
        @exclusive_rules = attrs[:exclusive_rules].is_a?(Array) ? attrs[:exclusive_rules] : [attrs[:exclusive_rules]]
      end
      @inclusive_rules.each{|rule| raise(WrongArguments, "A string is required") unless rule.is_a?(String)}
      @location = attrs[:location] || "~/Downloads"
      self
    end     
    
    def to_download?(string)
      if inclusive_rules.map{|rule| string.downcase.include?(rule.downcase) }.compact.include?(false)
        false 
      elsif exclusive_rules.nil? || exclusive_rules.empty? || !exclusive_rules.map{|rule| string.downcase.include?(rule.downcase) }.compact.include?(true)
        true
      else
        false
      end 
    end
    
    def self.default
      [{:inclusive_rules => ['Weeds'], :exclusive_rules => ['720p'], :location => nil}]
    end
    
  end 
    
end