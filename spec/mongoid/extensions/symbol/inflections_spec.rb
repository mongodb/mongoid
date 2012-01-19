require "spec_helper"

describe Mongoid::Extensions::Symbol::Inflections do

  describe "invert" do

    context "when :asc" do

      it "returns :desc" do
        :asc.invert.should eq(:desc)
      end
    end

    context "when :ascending" do

      it "returns :descending" do
        :ascending.invert.should eq(:descending)
      end
    end

    context "when :desc" do

      it "returns :asc" do
        :desc.invert.should eq(:asc)
      end
    end

    context "when :descending" do

      it "returns :ascending" do
        :descending.invert.should eq(:ascending)
      end
    end
  end

  describe "#gt" do

    it 'returns :"foo $gt"' do
      ret = :foo.gt
      ret.key.should eq(:foo)
      ret.operator.should eq("gt")
    end
  end

  describe "#near" do

    it 'returns :"foo $near"' do
      ret = :foo.near
      ret.key.should eq(:foo)
      ret.operator.should eq("near")
    end
  end

  describe "#not" do

    it 'returns :"foo $not"' do
      ret = :foo.not
      ret.key.should eq(:foo)
      ret.operator.should eq("not")
    end
  end

  describe "#within" do

    it "returns :foo $within" do
      ret = :foo.within
      ret.key.should eq(:foo)
      ret.operator.should eq("within")
    end
  end
end
