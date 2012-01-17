require "spec_helper"

describe Mongoid::Javascript do

  let(:js) do
    Mongoid::Javascript
  end

  describe ".aggregate" do

    it "returns the aggregate function" do
      js.aggregate.should == "function(obj, prev) { prev.count++; }"
    end
  end

  describe ".group" do

    it "returns the group function" do
      js.group.should == "function(obj, prev) { prev.group.push(obj); }"
    end
  end

  describe ".max" do

    it "returns the max function" do
      js.max.should == "function(obj, prev) { if (obj.[field] && prev.max == 'start') { " +
        "prev.max = obj.[field]; } if (obj.[field] && prev.max < obj.[field]) { prev.max = " +
        "obj.[field]; } }"
    end
  end

  describe ".min" do

    it "returns the min function" do
      js.min.should == "function(obj, prev) { if (obj.[field] && prev.min == 'start') { " +
        "prev.min = obj.[field]; } if (obj.[field] && prev.min > obj.[field]) { prev.min " +
        "= obj.[field]; } }"
    end
  end

  describe ".sum" do

    it "returns the sum function" do
      js.sum.should == "function(obj, prev) { if (prev.sum == 'start') " +
      "{ prev.sum = 0; } if (obj.[field]) { prev.sum += obj.[field]; } }"
    end
  end
end
