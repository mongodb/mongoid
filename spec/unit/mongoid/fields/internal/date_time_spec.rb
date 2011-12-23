require "spec_helper"

describe Mongoid::Fields::Internal::DateTime do

  let(:field) do
    described_class.instantiate(:test, :type => DateTime)
  end

  let!(:time) do
    Time.now.utc
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    it "converts to a datetime" do
      field.deserialize(time).should be_kind_of(DateTime)
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to a utc time" do
        field.selection(time.utc.to_s).should be_within(1).of(time.utc)
      end
    end

    context "when providing a complex criteria" do

      let(:criteria) do
        { "$ne" => "test" }
      end

      it "returns the criteria" do
        field.selection(criteria).should eq(criteria)
      end
    end
  end

  describe "#serialize" do

    # This is ridiculous - Ruby 1.8.x returns the current time when calling
    # parse with a string that is not the time.
    unless RUBY_VERSION =~ /1.8/

      context "when the string is an invalid time" do

        it "raises an error" do
          expect {
            field.serialize("shitty time")
          }.to raise_error(Mongoid::Errors::InvalidTime)
        end
      end
    end
  end
end
