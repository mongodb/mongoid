require "spec_helper"

describe Mongoid::Extensions::Symbol::Conversions do

  describe ".from_bson" do

    context "when given nil" do

      it "returns nil" do
        Symbol.from_bson(nil).should be_nil
      end
    end

    context "when string is empty" do

      it "returns nil" do
        Symbol.from_bson("").should be_nil
      end
    end

    context "when given a symbol" do

      it "returns the symbol" do
        Symbol.from_bson(:testing).should == :testing
      end
    end

    context "when given a string" do

      it "returns the symbol" do
        Symbol.from_bson("testing").should == :testing
      end
    end
  end

  describe ".try_bson" do

    it "returns a symbol" do
      Symbol.try_bson(:testing).should be_kind_of Symbol
    end

    it 'returns the same symbol' do
      Symbol.try_bson(:testing).should == :testing
    end
  end
end
