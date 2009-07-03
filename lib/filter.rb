class Pastis
  
  # Simple filter using strings and regexps
  class Filter
    attr_reader :inclusive_rules
    attr_reader :exclusive_rules
    
    class WrongArguments < StandardError; end
    
    # INCLUSIVE_FILTER_REGEXPS = [/.*Weeds\s.*/i] 
    # EXCLUSIVE_FILTER_REGEXPS = [/.*HDTV.*/i]  
    
    def initialize(attrs={})
      raise(WrongArguments, "you need to pass at least an inclusive and an exclusive rule") unless (attrs.has_key?(:inclusive_rules) && attrs.has_key?(:exclusive_rules))
      @inclusive_rules = attrs[:inclusive_rules].is_a?(Array) ? attrs[:inclusive_rules] : [attrs[:inclusive_rules]]
      @exclusive_rules = attrs[:exclusive_rules].is_a?(Array) ? attrs[:exclusive_rules] : [attrs[:exclusive_rules]]
      @inclusive_rules.each{|rule| raise(WrongArguments, "A regexp is required") unless rule.is_a?(Regexp)}
      self
    end     
    
    def to_download?(string)
      if inclusive_rules.map{|rule| string =~ rule }.compact.first.nil?
        false 
      elsif exclusive_rules.map{|rule| string =~ rule }.compact.first.nil?
        true
      else
        false
      end 
    end
    
  end 
    
end