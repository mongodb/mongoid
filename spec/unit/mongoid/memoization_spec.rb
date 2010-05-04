require "spec_helper"

describe Mongoid::Memoization do

  let(:memo) { "Memo" }

  before do
    @person = Person.new
  end

  describe "#memoized" do

    context "when variable has been defined" do

      before do
        @person.instance_variable_set("@memo", memo)
      end

      it "returns the memoized value" do
        @person.memoized(:memo) { nil }.should == memo
      end

    end

    context "when variable has not been defined" do

      it "returns the new value" do
        @person.memoized(:memo) { memo }.should == memo
      end

      it "memoizes the new value" do
        @person.memoized(:memo) { memo }
        @person.instance_variable_get("@memo").should == memo
      end

    end

  end

  describe "#reset" do

    context "when variable has been defined" do

      before do
        @person.instance_variable_set("@memo", memo)
      end

      it "removes the memoized value" do
        @person.reset(:memo) { nil }
        @person.instance_variable_defined?("@memo").should be_false
      end

      it "returns the new value" do
        @person.reset(:memo) { memo }.should == memo
      end

    end

    context "when variable has not been defined" do

      it "memoizes the new value" do
        @person.reset(:memo) { memo }
        @person.instance_variable_get("@memo").should == memo
      end

      it "returns the value" do
        @person.reset(:memo) { memo }.should == memo
      end

    end


  end

end
