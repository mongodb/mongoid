require "spec_helper"

describe Mongoid::Criterion::Complex do

  let(:complex) { Mongoid::Criterion::Complex.new(:key => :field, :operator => "$gt") }

  describe "#initialize" do

    it "sets the key" do
      complex.key.should == :field
    end

    it "sets the operator" do
      complex.operator.should == "$gt"
    end

  end

end
