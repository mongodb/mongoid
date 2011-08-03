require "spec_helper"

describe Mongoid::Extensions::Object::Reflections do

  describe "#remove_ivar" do

    context "when the instance variable is defined" do

      let(:document) do
        Person.new
      end

      before do
        document.instance_variable_set(:@testing, "testing")
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "removes the instance variable" do
        document.instance_variable_defined?(:@testing).should be_false
      end

      it "returns true" do
        removal.should be_true
      end
    end

    context "when the instance variable is not defined" do

      let(:document) do
        Person.new
      end

      let!(:removal) do
        document.remove_ivar("testing")
      end

      it "returns false" do
        removal.should be_false
      end
    end
  end
end
