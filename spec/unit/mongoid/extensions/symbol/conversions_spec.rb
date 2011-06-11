require "spec_helper"

describe Mongoid::Extensions::Symbol::Conversions do

  describe ".set" do

    context "when given nil" do

      it "returns nil" do
        Symbol.set(nil).should be_nil
      end
    end

    context "when string is empty" do

      it "returns nil" do
        Symbol.set("").should be_nil
      end
    end

    context "when given a symbol" do

      it "returns the symbol" do
        Symbol.set(:testing).should == :testing
      end
    end

    context "when given a string" do

      it "returns the symbol" do
        Symbol.set("testing").should == :testing
      end
    end
  end

  describe ".get" do

    it "returns a symbol" do
      Symbol.get(:testing).should be_kind_of Symbol
    end

    it 'returns the same symbol' do
      Symbol.get(:testing).should == :testing
    end
  end
end
