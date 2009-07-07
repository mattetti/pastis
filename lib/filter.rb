class Pastis
  
  # Simple filter using strings and regexps
  class Filter
    attr_reader :inclusive_rules
    attr_reader :exclusive_rules
    
    class WrongArguments < StandardError; end
    
    def initialize(attrs={})
      raise(WrongArguments, "you need to pass at least an inclusive rule") unless attrs.has_key?(:inclusive_rules)
      @inclusive_rules = attrs[:inclusive_rules].is_a?(Array) ? attrs[:inclusive_rules] : [attrs[:inclusive_rules]]
      if attrs.has_key?(:exclusive_rules)
        @exclusive_rules = attrs[:exclusive_rules].is_a?(Array) ? attrs[:exclusive_rules] : [attrs[:exclusive_rules]]
      end
      @inclusive_rules.each{|rule| raise(WrongArguments, "A string is required") unless rule.is_a?(String)}
      self
    end     
    
    def to_download?(string)
      if inclusive_rules.map{|rule| string.include?(rule) }.compact.include?(false)
        false 
      elsif exclusive_rules.empty? || !exclusive_rules.map{|rule| string.include?(rule) }.compact.include?(true)
        true
      else
        false
      end 
    end
    
  end 
    
end