require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../pastis'

describe "Filter" do
  
  before(:all) do
    @filter = Pastis::Filter.new(:inclusive_rules => [/.*Weeds\s.*/i], :exclusive_rules => [/.*720p.*/i])
    @filter_2 = Pastis::Filter.new(:inclusive_rules => [/.*The\sPhilanthropist.*/i], :exclusive_rules => [/.*720p.*/i])
  end
  
  it "should be able to match inclusive and excusive regexps" do
    @filter.to_download?("Weeds S05E04 720p HDTV X264-DIMENSION [eztv]").should be_false
    @filter.to_download?("Weeds S05E04 HDTV XviD-SYS [eztv]").should be_true
    @filter_2.to_download?("The Philanthropist S01E02 HDTV XviD-LOL [eztv]").should be_true
  end

end