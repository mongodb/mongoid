require "spec_helper"

describe Mongoid::Relations::Accessors do

  # let(:klass) do
    # Class.new do
      # include Mongoid::Relations
    # end
  # end

  # let(:relation) do
    # Mongoid::Relations::Embedded::Many
  # end

  # describe ".getter" do

    # let(:document) do
      # klass.new
    # end

    # let(:metadata) do
      # Mongoid::Relations::Metadata.new(
        # :name => :addresses,
        # :relation => relation
      # )
    # end

    # before do
      # klass.getter(:addresses, metadata)
    # end

    # it "defines a getter method" do
      # document.should respond_to(:addresses)
    # end

    # it "returns self" do
      # klass.getter("name", metadata).should == klass
    # end

    # context "defined methods" do

      # describe "#\{relation\}" do

        # context "when the instance variable is not set" do

          # before do
            # klass.setter(:addresses, metadata)
          # end

          # context "when relation attributes exist" do

            # let(:attributes) do
              # { "addresses" => [
                  # { "city" => "London" }
                # ]
              # }
            # end

            # before do
              # document.instance_variable_set(:@attributes, attributes)
            # end

            # it "returns a new relation" do
              # document.addresses.size.should == 1
            # end
          # end

          # context "when relation attributes do not exist" do

            # before do
              # document.instance_variable_set(:@attributes, {})
            # end

            # it "returns the empty relation" do
              # document.addresses.should == []
            # end
          # end
        # end

        # context "when the instance variable is set" do

          # before do
            # document.instance_variable_set(:@addresses, relation)
          # end

          # it "returns the variable" do
            # document.addresses.should == relation
          # end
        # end
      # end
    # end
  # end

  # describe ".setter" do

    # let(:document) do
      # klass.new
    # end

    # let(:metadata) do
      # Mongoid::Relations::Metadata.new(
        # :name => :addresses,
        # :relation => relation
      # )
    # end

    # before do
      # klass.setter(
        # "addresses",
        # metadata
      # )
    # end

    # it "defines a setter method" do
      # document.should respond_to(:addresses=)
    # end

    # it "returns self" do
      # klass.setter(
        # "preferences",
        # metadata
      # ).should == klass
    # end

    # context "defined methods" do
      # describe "#\{relation=\}" do

        # let(:address) do
          # Address.new
        # end

        # context "when no relation exists" do

          # before do
            # klass.getter("addresses", metadata)
            # document.instance_variable_set(:@addresses, nil)
            # document.addresses = [ address ]
          # end

          # it "creates a new relation" do
            # document.instance_variable_get(:@addresses).should == [ address ]
          # end
        # end

        # context "when a relation exists" do

          # before do
            # klass.getter("addresses", metadata)
          # end

          # context "when new target is not nil" do

            # before do
              # document.instance_variable_set(
                # :@addresses,
                # Mongoid::Relations::Embedded::Many.new(document, [], metadata)
              # )
              # document.addresses = [ address ]
            # end

            # it "replaces the target of the relation" do
              # document.instance_variable_get(:@addresses).should == [ address ]
            # end
          # end

          # context "when new target is nil" do

            # before do
              # document.instance_variable_set(
                # :@addresses,
                # Mongoid::Relations::Embedded::Many.new(document, [], metadata)
              # )
              # document.addresses = nil
            # end

            # context "when relation is one-to-one" do

              # let(:relation) do
                # Mongoid::Relations::Embedded::One
              # end

              # let(:metadata) do
                # Mongoid::Relations::Metadata.new(
                  # :name => :name,
                  # :relation => relation
                # )
              # end

              # before do
                # document.instance_variable_set(:@attributes, {})
                # klass.setter(:name, metadata).getter("name", metadata)
                # document.name = nil
              # end

              # it "sets the relation to nil" do
                # document.name.should be_nil
              # end
            # end

            # context "when relation is one-to-many" do

              # it "clears the target of the relation" do
                # document.instance_variable_get(:@addresses).should == []
              # end
            # end
          # end
        # end
      # end
    # end
  # end
end
