# Filter.rb
# Pastis
#
# Created by Matt Aimonetti on 2/4/10.
# Copyright 2010 m|a agile. All rights reserved.


class Filter
  attr_accessor :inclusive_rules, :exclusive_rules, :location
  
  def initialize(args={})
    args.each{|k,v| self.send("#{k}=", v)}
    self
  end
  
  def to_hash
    {:inclusive_rules => inclusive_rules, :exclusive_rules => exclusive_rules, :location => location}
  end
  
end