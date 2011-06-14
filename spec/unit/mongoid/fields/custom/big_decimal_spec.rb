require "spec_helper"

describe Mongoid::Fields::Custom::BigDecimal do

  let(:field) do
    described_class.new(:test, :type => BigDecimal)
  end

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  [ :deserialize, :get ].each do |method|

    describe "##{method}" do

      context "when the the value is a string" do

        it "returns a big decimal" do
          field.send(method, number.to_s).should == number
        end
      end

      context "when the value is nil" do

        it "returns nil" do
          field.send(method, nil).should be_nil
        end
      end
    end
  end

  [ :serialize, :set ].each do |method|

    describe "##{method}" do

      context "when the value is a big decimal" do

        it "returns a string" do
          field.send(method, number).should == number.to_s
        end
      end

      context "when the value is nil" do

        it "returns nil" do
          field.send(method, nil).should be_nil
        end
      end
    end
  end
end
