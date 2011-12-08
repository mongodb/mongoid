require "spec_helper"

describe Mongoid::Fields::Mappings do

  let(:definable) do
    described_class.for(klass)
  end

  describe ".for" do

    context "when given an Array" do

      context "when asking for a foreign key field" do

        let(:definable) do
          described_class.for(klass, true)
        end

        let(:klass) do
          Array
        end

        it "returns the standard definable field" do
          definable.should eq(Mongoid::Fields::Internal::ForeignKeys::Array)
        end
      end

      context "when passed no foreign key option" do

        let(:klass) do
          Array
        end

        it "returns the standard definable field" do
          definable.should eq(Mongoid::Fields::Internal::Array)
        end
      end
    end

    context "when given a BigDecimal" do

      let(:klass) do
        BigDecimal
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::BigDecimal)
      end
    end

    context "when given a Binary" do

      let(:klass) do
        Binary
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Binary)
      end
    end

    context "when given a Boolean" do

      let(:klass) do
        Boolean
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Boolean)
      end
    end

    context "when given a DateTime" do

      let(:klass) do
        DateTime
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::DateTime)
      end
    end

    context "when given a Date" do

      let(:klass) do
        Date
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Date)
      end
    end

    context "when given a Float" do

      let(:klass) do
        Float
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Float)
      end
    end

    context "when given a Hash" do

      let(:klass) do
        Hash
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Hash)
      end
    end

    context "when given an Integer" do

      let(:klass) do
        Integer
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Integer)
      end
    end

    context "when given an Object" do

      let(:klass) do
        Object
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Object)
      end
    end

    context "when given a BSON::ObjectId" do

      let(:klass) do
        BSON::ObjectId
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::ObjectId)
      end
    end

    context "when given a Range" do

      let(:klass) do
        Range
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Range)
      end
    end

    context "when given a Set" do

      let(:klass) do
        Set
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Set)
      end
    end

    context "when given a String" do

      let(:klass) do
        String
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::String)
      end
    end

    context "when given a Symbol" do

      let(:klass) do
        Symbol
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Symbol)
      end
    end

    context "when given a Time" do

      let(:klass) do
        Time
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::Time)
      end
    end

    context "when given a TimeWithZone" do

      let(:klass) do
        ActiveSupport::TimeWithZone
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Internal::TimeWithZone)
      end
    end

    context "when given a custom type" do

      context "without a module" do

        let(:klass) do
          Person
        end

        it "returns the class of the custom type" do
          definable.should eq(Person)
        end
      end

      context "with a module" do

        context "and a class not matching a defined serializable" do

          let(:klass) do
            Custom::Type
          end

          it "returns the module and class of the custom type" do
            definable.should eq(Custom::Type)
          end
        end

        context "and a class matching a defined serializable" do

          let(:klass) do
            Custom::String
          end

          it "returns the module and class of the custom type" do
            definable.should eq(Custom::String)
          end
        end

        context "inside the Mongoid namespace" do

          let(:klass) do
            Mongoid::MyExtension::Object
          end

          it "returns the module and class of the custom type" do
            definable.should eq(Mongoid::MyExtension::Object)
          end
        end
      end
    end

    context "when given nil" do

      let(:klass) do
        nil
      end

      it "returns the object standard type" do
        definable.should eq(Mongoid::Fields::Internal::Object)
      end
    end
  end
end
