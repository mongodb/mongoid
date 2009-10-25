require File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb")

describe Mongoid::Extensions::String::Inflections do

  describe "#singular?" do

    context "when singular" do

      it "returns true" do
        "bat".singular?.should be_true
      end

    end

    context "when plural" do

      it "returns false" do
        "bats".singular?.should be_false
      end

    end

  end

  describe "plural?" do

    context "when singular" do

      it "returns false" do
        "bat".plural?.should be_false
      end

    end

    context "when plural" do

      it "returns true" do
        "bats".plural?.should be_true
      end

    end

  end

end
