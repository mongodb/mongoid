# frozen_string_literal: true

require "spec_helper"

describe Mongoid::TypedArray do

  describe "#initialize" do

    context "when creating a typed array" do

      let(:typed_array) { described_class.new(Integer, [1, 2, 3]) }

      it "has class typed array" do
        expect(typed_array).to be_a(described_class)
      end

      it "has all of the correct elements" do
        expect(typed_array).to eq([1, 2, 3])
      end

      it "has the correct element_klass" do
        expect(typed_array.element_klass).to eq(Integer)
      end
    end

    context "when creating with castable elements of the wrong type" do

      let(:typed_array) { described_class.new(Integer, [1, "2", 3.0]) }

      it "has class typed array" do
        expect(typed_array).to be_a(described_class)
      end

      it "has all of the correct elements" do
        expect(typed_array).to eq([1, 2, 3])
      end

      it "has the correct element_klass" do
        expect(typed_array.element_klass).to eq(Integer)
      end
    end

    context "when creating with uncastable elements" do

      let(:typed_array) { described_class.new(Integer, [{}, []]) }

      it "has class typed array" do
        expect(typed_array).to be_a(described_class)
      end

      it "has all of the correct elements" do
        expect(typed_array).to eq([nil, nil])
      end
    end
  end

  describe "#<<" do

    let(:typed_array) { described_class.new(Integer, [1]) }

    context "when the item is of the correct type" do

      let!(:pushed) { typed_array << 2 }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 2 ])
      end

      it "returns an array of the correct type" do
        expect(pushed).to be_a(described_class)
      end

      it "modifies the original array" do
        expect(typed_array).to eq([ 1, 2 ])
      end

      it "keeps the type of the original array" do
        expect(typed_array).to be_a(described_class)
      end
    end
  end

  describe "#[]=" do

    let(:typed_array) { described_class.new(Integer, [ 1, 2, 3 ]) }

    context "when assigning with one argument" do

      context "when giving the correct type" do

        before do
          typed_array[1] = 4
        end

        it "assigns the value" do
          expect(typed_array).to eq([1, 4, 3])
        end
      end

      context "when giving a castable type" do

        before do
          typed_array[1] = '4'
        end

        it "assigns the value" do
          expect(typed_array).to eq([1, 4, 3])
        end
      end

      context "when giving an uncastable type" do

        before do
          typed_array[1] = []
        end

        it "assigns the value" do
          expect(typed_array).to eq([1, nil, 3])
        end
      end
    end

    context "when assigning with a range" do

      context "when assigning a single value" do

        context "when giving the correct type" do

          before do
            typed_array[1..2] = 4
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4])
          end
        end

        context "when giving a castable type" do

          before do
            typed_array[1..2] = '4'
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4])
          end
        end

        context "when giving an uncastable type" do

          before do
            typed_array[1..2] = {}
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, nil])
          end
        end
      end

      context "when assigning an array" do

        context "when giving the correct type" do

          before do
            typed_array[1..2] = [4, 5]
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4, 5])
          end
        end

        context "when giving a castable type" do

          before do
            typed_array[1..2] = ['4', '5']
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4, 5])
          end
        end

        context "when giving an uncastable type" do

          before do
            typed_array[1..2] = [ {}, :hello ]
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, nil, nil])
          end
        end
      end
    end

    context "when assigning with two arguments" do

      context "when assigning a single value" do

        context "when giving the correct type" do

          before do
            typed_array[1, 2] = 4
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4])
          end
        end

        context "when giving a castable type" do

          before do
            typed_array[1, 2] = '4'
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4])
          end
        end

        context "when giving an uncastable type" do

          before do
            typed_array[1, 2] = {}
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, nil])
          end
        end
      end

      context "when assigning an array" do

        context "when giving the correct type" do

          before do
            typed_array[1, 2] = [4, 5]
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4, 5])
          end
        end

        context "when giving a castable type" do

          before do
            typed_array[1, 2] = ['4', '5']
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, 4, 5])
          end
        end

        context "when giving an uncastable type" do

          before do
            typed_array[1, 2] = [ {}, :hello ]
          end

          it "assigns the value" do
            expect(typed_array).to eq([1, nil, nil])
          end
        end
      end
    end

    context "when giving too few arguments" do

      it "raises an ArgumentError" do
        expect do
          typed_array.[]=(1)
        end.to raise_error(ArgumentError)
      end
    end

    context "when giving too many arguments" do

      it "raises an ArgumentError" do
        expect do
          typed_array.[]=(1,2,3,4)
        end.to raise_error(ArgumentError)
      end
    end
  end
end
