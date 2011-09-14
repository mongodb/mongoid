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
          definable.should eq(Mongoid::Fields::Serializable::ForeignKeys::Array)
        end
      end

      context "when passed no foreign key option" do

        let(:klass) do
          Array
        end

        it "returns the standard definable field" do
          definable.should eq(Mongoid::Fields::Serializable::Array)
        end
      end
    end

    context "when given a BigDecimal" do

      let(:klass) do
        BigDecimal
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::BigDecimal)
      end
    end

    context "when given a Binary" do

      let(:klass) do
        Binary
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Binary)
      end
    end

    context "when given a Boolean" do

      let(:klass) do
        Boolean
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Boolean)
      end
    end

    context "when given a DateTime" do

      let(:klass) do
        DateTime
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::DateTime)
      end
    end

    context "when given a Date" do

      let(:klass) do
        Date
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Date)
      end
    end

    context "when given a Float" do

      let(:klass) do
        Float
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Float)
      end
    end

    context "when given a Hash" do

      let(:klass) do
        Hash
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Hash)
      end
    end

    context "when given an Integer" do

      let(:klass) do
        Integer
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Integer)
      end
    end

    context "when given an Object" do

      let(:klass) do
        Object
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Object)
      end
    end

    context "when given a BSON::ObjectId" do

      let(:klass) do
        BSON::ObjectId
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::ObjectId)
      end
    end

    context "when given a Range" do

      let(:klass) do
        Range
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Range)
      end
    end

    context "when given a Set" do

      let(:klass) do
        Set
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Set)
      end
    end

    context "when given a String" do

      let(:klass) do
        String
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::String)
      end
    end

    context "when given a Symbol" do

      let(:klass) do
        Symbol
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Symbol)
      end
    end

    context "when given a Time" do

      let(:klass) do
        Time
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::Time)
      end
    end

    context "when given a TimeWithZone" do

      let(:klass) do
        ActiveSupport::TimeWithZone
      end

      it "returns the standard definable field" do
        definable.should eq(Mongoid::Fields::Serializable::TimeWithZone)
      end
    end

    context "when given a custom type" do

      let(:klass) do
        Person
      end

      it "returns the class of the custom type" do
        definable.should eq(Person)
      end
    end

    context "when given nil" do

      let(:klass) do
        nil
      end

      it "returns the object standard type" do
        definable.should eq(Mongoid::Fields::Serializable::Object)
      end
    end
  end
end
