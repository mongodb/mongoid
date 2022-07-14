# frozen_string_literal: true

require "spec_helper"

# This file is for testing the functionality of uncastable values for all
# mongoizable classes.
describe "mongoize/demongoize/evolve methods" do

  shared_examples "handles unmongoizable values" do

    context "when passing an invalid value" do
      context "to mongoize" do
        it "returns nil" do
          expect(klass.mongoize(invalid_value)).to be_nil
        end
      end

      context "when assigning an invalid value to a field" do
        let(:catalog) { Catalog.create!(field_name => invalid_value) }

        it "returns nil" do
          catalog.attributes[field_name].should be_nil
        end

        it "persists nil" do
          Catalog.find(catalog._id).attributes[field_name].should be_nil
        end
      end
    end
  end

  shared_examples "handles undemongoizable values" do

    context "when passing an invalid value" do
      context "to demongoize" do
        it "returns nil" do
          expect(klass.demongoize(invalid_value)).to be_nil
        end
      end

      context "when retrieving an invalid value from the db" do

        before do
          Catalog.collection.insert_one(field_name => invalid_value)
        end

        let(:catalog) { Catalog.first }

        it "returns nil" do
          catalog.send(field_name).should be_nil
        end
      end
    end
  end

  shared_examples "pushes through unmongoizable values" do

    context "when passing an invalid value" do
      context "to mongoize" do
        it "returns that value" do
          expect(klass.mongoize(invalid_value)).to eq(mongoized_value)
        end
      end
    end

    context "when assigning an invalid value to a field" do
      let!(:catalog) { Catalog.create!(field_name => invalid_value) }
      let(:from_db) { Catalog.find(catalog._id) }

      it "returns the inputted value" do
        catalog.attributes[field_name].should be_nil
      end

      it "persists the inputted value" do
        from_db.attributes[field_name].should be_nil
      end
    end
  end

  shared_examples "pushes through undemongoizable values" do

    context "when reading an invalid value from the db" do
      before do
        Catalog.collection.insert_one(field_name => invalid_value)
      end

      let(:from_db) { Catalog.first }

      it "reads the inputted value" do
        from_db.send(field_name).should eq(demongoized_value)
      end
    end
  end

  shared_examples "pushes through unevolvable values" do

    context "when passing an uncastable value to evolve" do

      it "pushes the value through" do
        expect(klass.evolve(invalid_value)).to eq(mongoized_value)
      end
    end
  end

  shared_examples "pushes through uncastable values" do
    include_examples "pushes through unmongoizable values"
    include_examples "pushes through undemongoizable values"
  end

  shared_examples "handles uncastable values" do
    include_examples "handles unmongoizable values"
    include_examples "handles undemongoizable values"
  end

  let(:mongoized_value) { invalid_value }
  let(:demongoized_value) { invalid_value }

  describe Array do
    let(:invalid_value) { 1 }
    let(:klass) { Array }
    let(:field_name) { :array_field }

    include_examples "handles unmongoizable values"
    include_examples "pushes through undemongoizable values"
    include_examples "pushes through unevolvable values"
  end

  describe BigDecimal do
    let(:invalid_value) { "bogus" }
    let(:klass) { described_class }
    let(:field_name) { :big_decimal_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Mongoid::Boolean do
    let(:invalid_value) { "invalid_value" }
    let(:klass) { described_class }
    let(:field_name) { :boolean_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Date do
    let(:invalid_value) { :hello }
    let(:klass) { described_class }
    let(:field_name) { :date_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe DateTime do
    let(:invalid_value) { :hello }
    let(:klass) { described_class }
    let(:field_name) { :date_time_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Float do
    let(:invalid_value) { [] }
    let(:klass) { described_class }
    let(:field_name) { :float_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Hash do
    let(:invalid_value) { 1 }
    let(:klass) { described_class }
    let(:field_name) { :hash_field }

    include_examples "handles unmongoizable values"
    include_examples "pushes through undemongoizable values"
    include_examples "pushes through unevolvable values"
  end

  describe Integer do
    let(:invalid_value) { [] }
    let(:klass) { described_class }
    let(:field_name) { :integer_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe BSON::ObjectId do
    let(:invalid_value) { "invalid value" }
    let(:klass) { described_class }
    let(:field_name) { :object_id_field }

    include_examples "pushes through uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe BSON::Binary do
    let(:invalid_value) { true }
    let(:klass) { described_class }
    let(:field_name) { :binary_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Range do
    let(:invalid_value) { "invalid value" }
    let(:klass) { described_class }
    let(:field_name) { :range_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Regexp do
    let(:invalid_value) { 1 }
    let(:klass) { described_class }
    let(:field_name) { :regexp_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Set do
    let(:invalid_value) { 1 }
    let(:klass) { described_class }
    let(:field_name) { :set_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe String do
    let(:invalid_value) { 1 }
    let(:mongoized_value) { "1" }
    let(:demongoized_value) { "1" }
    let(:klass) { described_class }
    let(:field_name) { :string_field }

    include_examples "pushes through uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Mongoid::StringifiedSymbol do
    let(:invalid_value) { [] }
    let(:mongoized_value) { "[]" }
    let(:demongoized_value) { :[] }
    let(:klass) { described_class }
    let(:field_name) { :stringified_symbol_field }

    include_examples "pushes through uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Symbol do
    let(:invalid_value) { Time.new }
    let(:klass) { described_class }
    let(:field_name) { :symbol_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe Time do
    let(:invalid_value) { "invalid value" }
    let(:klass) { described_class }
    let(:field_name) { :time_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end

  describe ActiveSupport::TimeWithZone do
    let(:invalid_value) { "invalid value" }
    let(:klass) { described_class }
    let(:field_name) { :time_with_zone_field }

    include_examples "handles uncastable values"
    include_examples "pushes through unevolvable values"
  end
end
