require "spec_helper"

describe Mongoid::Extensions::Hash::CriteriaHelpers do

  describe "#expand_complex_criteria" do

    before do
      @hash = {:age.gt => 40, :title => "Title"}
    end

    it "expands complex criteria to form a valid `where` hash" do
      @hash.expand_complex_criteria.should == {:age => {"$gt" => 40}, :title => "Title"}
    end

  end

end