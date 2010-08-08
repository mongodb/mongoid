require "spec_helper"

describe Mongoid::Relations::Accessors do

  let(:klass) do
    Class.new do
      include Mongoid::Relations
    end
  end

  let(:relation) do
    Mongoid::Relations::Embedded::Many
  end

  describe ".getter" do

    let(:document) do
      klass.new
    end

    before do
      klass.getter(:addresses)
    end

    it "defines a getter method" do
      document.should respond_to(:addresses)
    end

    it "returns self" do
      klass.getter("name").should == klass
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
      Mongoid::Relations::Metadata.new(
        :name => :addresses,
        :relation => relation
      )
    end

    before do
      klass.setter(
        "addresses",
        metadata
      )
    end

    it "defines a setter method" do
      document.should respond_to(:addresses=)
    end

    it "returns self" do
      klass.setter(
        "preferences",
        metadata
      ).should == klass
    end

    context "defined methods" do
      describe "#\{relation=\}" do

        let(:address) do
          Address.new
        end

        context "when no relation exists" do

          before do
            klass.getter("addresses")
            document.instance_variable_set(:@addresses, nil)
            document.addresses = [ address ]
          end

          it "creates a new relation" do
            document.instance_variable_get(:@addresses).should == [ address ]
          end
        end

        context "when a relation exists" do

          before do
            klass.getter("addresses")
          end

          context "when new target is not nil" do

            before do
              document.instance_variable_set(
                :@addresses,
                Mongoid::Relations::Embedded::Many.new(document, [], metadata)
              )
              document.addresses = [ address ]
            end

            it "replaces the target of the relation" do
              document.instance_variable_get(:@addresses).should == [ address ]
            end
          end

          context "when new target is nil" do

            before do
              document.instance_variable_set(
                :@addresses,
                Mongoid::Relations::Embedded::Many.new(document, [], metadata)
              )
              document.addresses = nil
            end

            context "when relation is one-to-one" do

              let(:relation) do
                Mongoid::Relations::Embedded::One
              end

              let(:metadata) do
                Mongoid::Relations::Metadata.new(
                  :name => :name,
                  :relation => relation
                )
              end

              before do
                klass.setter(:name, metadata).getter("name")
                document.name = nil
              end

              it "sets the relation to nil" do
                document.name.should be_nil
              end
            end

            context "when relation is one-to-many" do

              it "clears the target of the relation" do
                document.instance_variable_get(:@addresses).should == []
              end
            end
          end
        end
      end
    end
  end
end
