require "spec_helper"

describe Mongoid::Extensions::Symbol::Inflections do

  describe "#singular?" do

    context "when singular" do

      it "returns true" do
        :bat.singular?.should be_true
      end

    end

    context "when plural" do

      it "returns false" do
        :bats.singular?.should be_false
      end

    end

  end

  describe "plural?" do

    context "when singular" do

      it "returns false" do
        :bat.plural?.should be_false
      end

    end

    context "when plural" do

      it "returns true" do
        :bats.plural?.should be_true
      end

    end

  end

  describe "invert" do

    context "when :asc" do

      it "returns :desc" do
        :asc.invert.should == :desc
      end

    end

    context "when :ascending" do

      it "returns :descending" do
        :ascending.invert.should == :descending
      end

    end

    context "when :desc" do

      it "returns :asc" do
        :desc.invert.should == :asc
      end

    end

    context "when :descending" do

      it "returns :ascending" do
        :descending.invert.should == :ascending
      end

    end

  end

  describe "#gt" do

    it 'returns :"foo $gt"' do
      ret = :foo.gt
      ret.key.should == :foo
      ret.operator.should == "gt"
    end

  end

end
