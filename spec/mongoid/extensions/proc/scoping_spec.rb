require "spec_helper"

describe Mongoid::Extensions::Proc::Scoping do

  describe "#as_conditions" do

    context "when the proc accessed a hash" do

      let(:pro) do
        lambda { |number| { :where => { :count => number } } }
      end

      it "calls the hash with the args" do
        pro.as_conditions(10).should eq({ :where => { :count => 10 }})
      end
    end

    context "when the proc calls a criteria" do

      let(:pro) do
        lambda { |title| Person.where(:title => title) }
      end

      it "returns the criteria as_conditions" do
        pro.as_conditions("Sir").should eq({ :where => { :title => "Sir" }})
      end
    end
  end
end
