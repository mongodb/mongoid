require "spec_helper"

describe Mongoid::Extensions::Hash::ReductionHelpers do

  describe "#expand_reduction_fields" do

    it "expands complex criteria to form a valid `where` hash" do
      hash = {:age => [:min, :max, :sum], :height => :max, :weight => "<custom js>" }
      hash.expand_reduction_fields.should == [
        [:age,    "age_min",    :min ],
        [:age,    "age_max",    :max ],
        [:age,    "age_sum",    :sum ],
        [:height, "height_max", :max ],
        [:weight, "weight",     "<custom js>" ]
      ]
    end
  end
end
