require "spec_helper"

describe Mongoid::Fields::Custom::Boolean do

  let(:field) do
    described_class.new(:test, :type => Boolean)
  end

  [ :deserialize, :get ].each do |method|

    describe "##{method}" do

      it "returns the value" do
        field.send(method, true).should be_true
      end
    end
  end

  [ :serialize, :set ].each do |method|

    describe "##{method}" do

      context "when provided true" do

        it "returns true" do
          field.send(method, "true").should be_true
        end
      end

      context "when provided false" do

        it "returns false" do
          field.send(method, "false").should be_false
        end
      end

      context "when provided 0" do

        it "returns false" do
          field.send(method, "0").should be_false
        end
      end

      context "when provided 1" do

        it "returns true" do
          field.send(method, "1").should be_true
        end
      end

      context "when provided nil" do

        it "returns nil" do
          field.send(method, nil).should be_nil
        end
      end
    end
  end
end
