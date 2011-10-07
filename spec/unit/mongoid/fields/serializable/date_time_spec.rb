require "spec_helper"

describe Mongoid::Fields::Serializable::DateTime do

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

  describe "#serialize" do

    context "when the string is an invalid time" do

      it "raises an error" do
        expect {
          field.serialize("shitty time")
        }.to raise_error(Mongoid::Errors::InvalidTime)
      end
    end
  end
end
