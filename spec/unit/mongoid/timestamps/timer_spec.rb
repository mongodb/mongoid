require "spec_helper"

describe Mongoid::Timestamps::Timer do

  describe ".time" do

    context "when Time.now.utc? return false" do
      it "should return getlocal" do
        Time.now.stubs(:utc?).returns false
        described_class.time.should be_within(10).of(Time.now)
      end
    end

    context "when Time.now.utc? return true" do
      it "should return getlocal" do
        Time.now.stubs(:utc?).returns true
        described_class.time.should be_within(10).of(Time.now.utc)
      end
    end
  end
end

