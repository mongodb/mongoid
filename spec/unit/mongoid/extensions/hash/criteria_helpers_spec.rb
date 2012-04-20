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

    it "expands a nested complex criteria to form a valid `where` hash" do
      hash = { "person.videos".to_sym.matches => { :year.gt => 2000 } }
      hash.expand_complex_criteria.should eq({:"person.videos"=>{"$elemMatch"=>{:year=>{"$gt"=>2000}}}})
    end

    it "expands nested complex criteria in an array to form a valid `where` hash" do
      hash = { "$or" => [{:year.gt => 2000}]}
      hash.expand_complex_criteria.should eq({"$or" => [:year => {"$gt" => 2000}]})
    end
  end
end
