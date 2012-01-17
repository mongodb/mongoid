require "spec_helper"

describe Mongoid::Fields::Internal::Hash do

  let(:field) do
    described_class.instantiate(:test, :type => Hash)
  end

  describe "#cast_on_read?" do

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when the default is a proc" do

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :default => lambda { { "field" => "value" } }
        )
      end

      it "calls the proc" do
        field.eval_default(nil).should eq({ "field" => "value" })
      end
    end

    context "when the default is a hash" do

      let(:default) do
        { "field" => "value" }
      end

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Hash,
          :default => default
        )
      end

      it "returns the correct value" do
        field.eval_default(nil).should eq(default)
      end

      it "returns a duped hash" do
        field.eval_default(nil).should_not equal(default)
      end
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "returns the value" do
        field.selection({ "field" => "value" }).should eq({ "field" => "value" })
      end
    end
  end

  describe "#serialize" do

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when the value is a hash" do

      it "returns the hash" do
        field.serialize({ "field" => "value" }).should eq({ "field" => "value" })
      end
    end
  end
end
