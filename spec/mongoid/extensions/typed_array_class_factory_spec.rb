# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::TypedArrayClassFactory do

  describe '.create' do
    context "when creating a TypedArray class" do
      after do
        Mongoid.send(:remove_const, :IntegerArray)
      end

      before do
        expect(Mongoid.const_defined?("IntegerArray")).to be false
        described_class.create(Integer)
      end

      it "creates the correct class" do
        expect(Mongoid.const_defined?("IntegerArray")).to be true
      end
    end
  end

  describe "Mongoid::.*Array" do
    before(:all) do
      described_class.create(Integer)
      described_class.create(String)
    end

    describe "#initialize" do

      context "creates an array" do

        context "when giving no args" do

          let(:string_array) { Mongoid::StringArray.new }

          it "is an empty array" do
            expect(string_array).to eq([])
          end
        end

        context "when giving args" do

          let(:string_array) { Mongoid::StringArray.new([ 1, 2 ]) }

          it "mongoizes the arguments" do
            expect(string_array).to eq(["1", "2"])
          end
        end
      end
    end

    describe ".mongoize" do

      let(:mongoized) { Mongoid::StringArray.mongoize(arg) }

      context "when passing in an array" do
        let(:arg) { [ "1", 2 ] }

        it "mongoizes the values" do
          expect(mongoized).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(mongoized.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a set" do
        let(:arg) { [ "1", 2 ].to_set }

        it "mongoizes the values" do
          expect(mongoized).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(mongoized.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a bogus value" do
        let(:arg) { "bogus" }

        it "returns nil" do
          expect(mongoized).to eq(nil)
        end
      end

      context "when passing in a Mongoid::StringArray" do
        let(:arg) { Mongoid::StringArray.new([ 1 ]) }

        it "mongoizes and returns the values" do
          expect(mongoized).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(mongoized.class).to eq(Mongoid::StringArray)
        end

        it "doesn't mongoize the values again" do
          arg
          expect(String).to receive(:mongoize).never
          mongoized
        end
      end

      context "when passing in a Mongoid::IntegerArray" do
        let(:arg) { Mongoid::IntegerArray.new([ 1 ]) }

        it "mongoizes and returns the values" do
          expect(mongoized).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(mongoized.class).to eq(Mongoid::StringArray)
        end
      end
    end

    describe ".demongoize" do

      let(:demongoized) { Mongoid::StringArray.demongoize(arg) }

      context "when passing in an array" do
        let(:arg) { [ "1", 2 ] }

        it "mongoizes the values" do
          expect(demongoized).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(demongoized.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a set" do
        let(:arg) { [ "1", 2 ].to_set }

        it "mongoizes the values" do
          expect(demongoized).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(demongoized.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a bogus value" do
        let(:arg) { "bogus" }

        it "returns nil" do
          expect(demongoized).to eq(nil)
        end
      end

      context "when passing in a Mongoid::StringArray" do
        let(:arg) { Mongoid::StringArray.new([ 1 ]) }

        it "mongoizes and returns the values" do
          expect(demongoized).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(demongoized.class).to eq(Mongoid::StringArray)
        end

        it "doesn't call the constructor again" do
          arg
          expect(Mongoid::StringArray).to receive(:new).never
          demongoized
        end
      end

      context "when passing in a Mongoid::IntegerArray" do
        let(:arg) { Mongoid::IntegerArray.new([ 1 ]) }

        it "mongoizes and returns the values" do
          expect(demongoized).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(demongoized.class).to eq(Mongoid::StringArray)
        end
      end
    end

    describe ".evolve" do

      let(:evolved) { Mongoid::StringArray.evolve(arg) }

      context "when passing in an array" do
        let(:arg) { [ "1", 2 ] }

        it "evolves the values" do
          expect(evolved).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(evolved.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a set" do
        let(:arg) { [ "1", 2 ].to_set }

        it "evolves the values" do
          expect(evolved).to eq([ "1", "2" ])
        end

        it "has the correct type" do
          expect(evolved.class).to eq(Mongoid::StringArray)
        end
      end

      context "when passing in a bogus value" do
        let(:arg) { "bogus" }

        it "returns nil" do
          expect(evolved).to eq(arg)
        end
      end

      context "when passing in a Mongoid::StringArray" do
        let(:arg) { Mongoid::StringArray.new([ 1 ]) }

        it "evolves and returns the values" do
          expect(evolved).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(evolved.class).to eq(Mongoid::StringArray)
        end

        it "doesn't evolve the values again" do
          arg
          expect(String).to receive(:evolve).never
          evolved
        end
      end

      context "when passing in a Mongoid::IntegerArray" do
        let(:arg) { Mongoid::IntegerArray.new([ 1 ]) }

        it "mongoizes and returns the values" do
          expect(evolved).to eq([ "1" ])
        end

        it "has the correct type" do
          expect(evolved.class).to eq(Mongoid::StringArray)
        end
      end
    end

    describe "#getter/setter" do
      let(:band) { Band.new }

      context "when assigning an array" do
        before do
          band.mate_ids = [ 1, "2", "bogus" ]
        end

        it "is able to be retrieved with the getter" do
          expect(band.mate_ids).to eq([1, 2, nil])
        end

        it "is demongoized to an IntegerArray" do
          expect(band.mate_ids.class).to eq(Mongoid::IntegerArray)
        end

        it "has the correct types in the attributes hash" do
          expect(band.attributes["mate_ids"]).to eq([ 1, 2, nil ])
        end

        it "mongoizes to an array in the attributes hash" do
          expect(band.attributes["mate_ids"].class).to eq(Mongoid::IntegerArray)
        end
      end

      context "when persisting an array" do
        before do
          band.mate_ids = [ 1, "2", "bogus" ]
          band.save!
        end

        let(:from_db) { band }

        it "is able to be retrieved with the getter" do
          expect(from_db.mate_ids).to eq([1, 2, nil])
        end

        it "is demongoized to an IntegerArray" do
          expect(from_db.mate_ids.class).to eq(Mongoid::IntegerArray)
        end

        it "has the correct types in the attributes hash" do
          expect(from_db.attributes["mate_ids"]).to eq([ 1, 2, nil ])
        end

        it "mongoizes to an array in the attributes hash" do
          expect(from_db.attributes["mate_ids"].class).to eq(Mongoid::IntegerArray)
        end
      end

      context "when assiging a mongoizable typed array field" do
        after do
          Band.fields.delete("range_array")
        end

        before do
          Band.field :range_array, type: Array(Range)
        end

        let!(:band) { Band.create!(range_array: [ 1..3 ]) }
        let(:from_db) { Band.first }

        it "mongoizes to a hash" do
          expect(band.attributes["range_array"]).to eq([ { "min" => 1, "max" => 3 } ])
        end

        it "demongoizes to a hash" do
          expect(band.range_array).to eq([ { "min" => 1, "max" => 3 } ])
        end

        it "is stored as a hash in the database" do
          expect(from_db.attributes["range_array"]).to eq([ { "min" => 1, "max" => 3 } ])
        end

        it "demongoizes to a hash from the database" do
          expect(from_db.range_array).to eq([ { "min" => 1, "max" => 3 } ])
        end
      end

      context "when modifying a typed array" do
        let(:band) { Band.new(mates: [ "1", "2" ]) }

        before do
          band.mates.push(3)
          band.mates.push(4)
        end

        it "adds the element to the array" do
          expect(band.mates).to eq([ "1", "2", "3", "4" ])
        end
      end

      context "when modifying a typed array from the database" do

        before do
          Band.create!(mates: [ "1", "2" ])
        end

        let(:band) do
          Band.first
        end

        before do
          band.mates.push(3)
          band.mates.push(4)
        end

        it "adds the element to the array" do
          pending "MONGOID-2951"
          expect(band.mates).to eq([ "1", "2", "3", "4" ])
        end
      end
    end
  end
end
