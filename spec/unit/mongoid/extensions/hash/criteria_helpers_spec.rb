require "spec_helper"

describe Mongoid::Extensions::Hash::CriteriaHelpers do

  describe "#expand_complex_criteria" do

    it "expands complex criteria to form a valid `where` hash" do
      hash = {:age.gt => 40, :title => "Title"}
      hash.expand_complex_criteria.should == {:age => {"$gt" => 40}, :title => "Title"}
    end

    it "merges multiple complex criteria to form a valid `where` hash" do
      hash = {:age.gt => 40, :age.lt => 45}
      hash.expand_complex_criteria.should == {:age => {"$gt" => 40, "$lt" => 45}}
    end

  end

end
