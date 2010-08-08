require "spec_helper"

describe Mongoid::Relations do

  let(:klass) do
    Class.new do
      include Mongoid::Relations
      def self.name
        "TestClass"
      end
    end
  end

  describe "#embedded?" do

    context "when the class is embedded" do

      before do
        klass.embedded_in(:person)
      end

      it "returns true" do
        klass.allocate.should be_embedded
      end
    end

    context "when the class is not embedded" do

      it "returns false" do
        klass.allocate.should_not be_embedded
      end
    end
  end

  describe ".embedded?" do

    context "when the class is embedded" do

      before do
        klass.embedded_in(:person)
      end

      it "returns true" do
        klass.should be_embedded
      end
    end

    context "when the class is not embedded" do

      it "returns false" do
        klass.should_not be_embedded
      end
    end
  end
end
