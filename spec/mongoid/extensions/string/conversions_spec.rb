require "spec_helper"

describe Mongoid::Extensions::String::Conversions do

  describe "#to_a" do

    let(:value) do
      "Disintegration is the best album ever!"
    end

    it "returns an array with the string in it" do
      value.to_a.should == [ value ]
    end
  end
end
