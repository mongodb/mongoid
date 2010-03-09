require "spec_helper"

describe Mongoid::Extras do

  before do
    @klass = Class.new do
      include Mongoid::Extras
    end
  end

  describe ".cache" do

    before do
      @klass.cache
    end

    it "sets the cached boolean on the class" do
      @klass.cached.should be_true
    end

  end

  describe ".cached?" do

    context "when the class is cached" do

      before do
        @klass.cache
      end

      it "returns true" do
        @klass.should be_cached
      end
    end

    context "when the class is not cached" do

      it "returns false" do
        @klass.should_not be_cached
      end
    end

  end

  describe "#cached?" do

    before do
      @klass.cache
      @doc = @klass.new
    end

    it "returns the class cached? value" do
      @doc.should be_cached
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
