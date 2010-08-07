require "spec_helper"

describe Mongoid::Relations::Accessors do

  let(:klass) do
    Class.new do
      include Mongoid::Relations::Accessors
    end
  end

  describe ".getter" do

    let(:document) do
      klass.new
    end

    before do
      klass.getter("addresses")
    end

    it "defines a getter method" do
      document.should respond_to(:addresses)
    end

    context "defined methods" do

      describe "#\{relation\}" do

        let(:relation) do
          stub
        end

        context "when the instance variable is not set" do

          before do
            document.instance_variable_set(:@addresses, nil)
          end

          it "returns nil" do
            document.addresses.should be_nil
          end
        end

        context "when the instance variable is set" do

          before do
            document.instance_variable_set(:@addresses, relation)
          end

          it "returns the variable" do
            document.addresses.should == relation
          end
        end
      end
    end
  end

  describe ".setter" do

    let(:document) do
      klass.new
    end

    let(:metadata) do
      Mongoid::Relations::Metadata.new(:name => :addresses)
    end

    before do
      klass.setter(
        "addresses",
        metadata,
        Mongoid::Relations::Embedded::Many
      )
    end

    it "defines a setter method" do
      document.should respond_to(:addresses=)
    end
  end
end
