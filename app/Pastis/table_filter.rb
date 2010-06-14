# table_filter.rb
# Pastis
#
# Created by Matt Aimonetti on 6/14/10.
# Copyright 2010 m|a agile. All rights reserved.

class TableFilter
  attr_accessor :inclusive_rules, :exclusive_rules, :location
  
  def initialize(args={})
    args.each{|k,v| self.send("#{k}=", v)}
    self
  end
  
  def filter_key
    inclusive_rules.empty? ? nil : inclusive_rules.first.downcase
  end
  
  def stringified_inclusive_rules
    stringify_array(inclusive_rules || [])
  end
  
  def stringified_exclusive_rules
    stringify_array(exclusive_rules || [])
  end
  
  def to_hash
    {:inclusive_rules => inclusive_rules, :exclusive_rules => exclusive_rules, :location => location}
  end
  
  private
  
  def stringify_array(arr)
    raise TypeError unless arr.respond_to?(:empty?) && arr.respond_to?(:join)
    arr.join(', ')
  end
  
end