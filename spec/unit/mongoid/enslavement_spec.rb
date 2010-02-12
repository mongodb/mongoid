require "spec_helper"

describe Mongoid::Enslavement do

  before do
    @klass = Class.new do
      include Mongoid::Enslavement
    end
  end

  describe ".enslave" do

    before do
      @klass.enslave
    end

    it "sets the enslaved boolean on the class" do
      @klass.enslaved.should be_true
    end

  end

  describe ".enslaved" do

    it "defaults to false" do
      @klass.enslaved.should be_false
    end
  end

  describe ".enslaved?" do

    context "when the class is enslaved" do

      before do
        @klass.enslave
      end

      it "returns true" do
        @klass.should be_enslaved
      end
    end

    context "when the class is not enslaved" do

      it "returns false" do
        @klass.should_not be_enslaved
      end
    end

  end

  describe "#enslaved?" do

    before do
      @klass.enslave
      @doc = @klass.new
    end

    it "returns the class enslaved? value" do
      @doc.should be_enslaved
    end
  end
end
