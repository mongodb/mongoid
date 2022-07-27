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

  shared_examples "maintains class" do
    it "keeps the type of the array" do
      expect(pushed).to be_a(described_class)
      expect(typed_array).to be_a(described_class)
    end
  end

  shared_examples "maintains original array" do
    it "has the correct values" do
      expect(typed_array).to eq(pushed)
    end
  end

  describe "#<<" do

    let(:typed_array) { described_class.new(Integer, [ 1 ]) }

    context "when the item is of the correct type" do

      let!(:pushed) { typed_array << 2 }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when the item is castable" do

      let!(:pushed) { typed_array << "2" }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when the item is uncastable" do

      let!(:pushed) { typed_array << "bogus" }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, nil ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending no items" do

      let(:pushed) { typed_array.<< }

      it "raises an error" do
        expect do
          pushed
        end.to raise_error(ArgumentError, /wrong number of arguments/)
      end
    end
  end

  [ :push, :append ].each do |method|
    describe "##{method}" do

      let(:typed_array) { described_class.new(Integer, [ 1 ]) }

      context "when the item is of the correct type" do

        let!(:pushed) { typed_array.send(method, 2) }

        it "returns the correct elements" do
          expect(pushed).to eq([ 1, 2 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when the item is castable" do

        let!(:pushed) { typed_array.send(method, "2") }

        it "returns the correct elements" do
          expect(pushed).to eq([ 1, 2 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when the item is uncastable" do

        let!(:pushed) { typed_array.send(method, "bogus") }

        it "returns the correct elements" do
          expect(pushed).to eq([ 1, nil ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when sending multiple items" do

        let!(:pushed) { typed_array.send(method, 2, "3", "bogus") }

        it "returns the correct elements" do
          expect(pushed).to eq([ 1, 2, 3, nil ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when sending no items" do

        let!(:pushed) { typed_array.send(method) }

        it "returns the same elements" do
          expect(pushed).to eq([ 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end
    end
  end

  [ :unshift, :prepend ].each do |method|
    describe "##{method}" do

      let(:typed_array) { described_class.new(Integer, [ 1 ]) }

      context "when the item is of the correct type" do

        let!(:pushed) { typed_array.send(method, 2) }

        it "returns the correct elements" do
          expect(pushed).to eq([ 2, 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when the item is castable" do

        let!(:pushed) { typed_array.send(method, "2") }

        it "returns the correct elements" do
          expect(pushed).to eq([ 2, 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when the item is uncastable" do

        let!(:pushed) { typed_array.send(method, "bogus") }

        it "returns the correct elements" do
          expect(pushed).to eq([ nil, 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when sending multiple items" do

        let!(:pushed) { typed_array.send(method, 2, "3", "bogus") }

        it "returns the correct elements" do
          expect(pushed).to eq([ 2, 3, nil, 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end

      context "when sending no items" do

        let!(:pushed) { typed_array.send(method) }

        it "returns the same elements" do
          expect(pushed).to eq([ 1 ])
        end

        include_examples "maintains original array"
        include_examples "maintains class"
      end
    end
  end

  describe "#insert" do

    let(:typed_array) { described_class.new(Integer, [ 1, 2 ]) }

    context "when the item is of the correct type" do

      let!(:pushed) { typed_array.insert(1, 3) }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 3, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when the item is castable" do

      let!(:pushed) { typed_array.insert(1, "3") }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 3, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when the item is uncastable" do

      let!(:pushed) { typed_array.insert(1, "bogus") }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, nil, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending multiple items" do

      let!(:pushed) { typed_array.insert(1, "3", "bogus") }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 3, nil, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending one item" do

      let(:pushed) { typed_array.insert(2) }

      it "returns the same elements" do
        expect(pushed).to eq([ 1, 2 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending one item of the wrong type" do

      let(:pushed) { typed_array.insert("bogus") }

      it "raises a type error" do
        expect do
          pushed
        end.to raise_error(TypeError, /no implicit conversion of String into Integer/)
      end
    end
  end

  describe "#fill" do

    let(:typed_array) { described_class.new(Integer, [ 1, 2, 3 ]) }

    context "when passing one item of the correct type" do

      let!(:pushed) { typed_array.fill(4) }

      it "returns the correct elements" do
        expect(pushed).to eq([ 4, 4, 4 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when passing on item that is castable" do

      let!(:pushed) { typed_array.fill("4") }

      it "returns the correct elements" do
        expect(pushed).to eq([ 4, 4, 4 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when passing one item that is uncastable" do

      let!(:pushed) { typed_array.fill("bogus") }

      it "returns the correct elements" do
        expect(pushed).to eq([ nil, nil, nil ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending a range" do

      let!(:pushed) { typed_array.fill("4", 0..1) }

      it "returns the correct elements" do
        expect(pushed).to eq([ 4, 4, 3 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending a start and end" do

      let!(:pushed) { typed_array.fill("4", 0, 1) }

      it "returns the correct elements" do
        expect(pushed).to eq([ 4, 2, 3 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending a block" do

      let(:pushed) { typed_array.fill(2) { |i| "#{i * i}" } }

      it "returns and mongoizes the correct elements" do
        expect(pushed).to eq([ 1, 2, 4 ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending an item of the wrong type with a block" do

      let(:pushed) { typed_array.fill("bogus") { |i| i * i } }

      it "raises a type error" do
        expect do
          pushed
        end.to raise_error(TypeError, /no implicit conversion of String into Integer/)
      end
    end

    context "when sending an item of the wrong type to other args" do

      let(:pushed) { typed_array.fill(1, "bogus") }

      it "raises a type error" do
        expect do
          pushed
        end.to raise_error(TypeError, /no implicit conversion of String into Integer/)
      end
    end
  end

  describe "#replace" do

    let(:typed_array) { described_class.new(Integer, [ 1, 2 ]) }


    context "when sending multiple items" do

      let!(:pushed) { typed_array.replace([ 1, "2", "bogus" ]) }

      it "returns the correct elements" do
        expect(pushed).to eq([ 1, 2, nil ])
      end

      include_examples "maintains original array"
      include_examples "maintains class"
    end

    context "when sending one item" do

      let(:pushed) { typed_array.replace(2) }

      it "raises an error" do
        expect do
          pushed
        end.to raise_error(TypeError, /no implicit conversion of Integer into Array/)
      end
    end

    context "when multiple args" do

      let(:pushed) { typed_array.replace([1], [2]) }

      it "raises an error" do
        expect do
          pushed
        end.to raise_error(ArgumentError, /wrong number of arguments/)
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
        end.to raise_error(ArgumentError, /wrong number of arguments/)
      end
    end

    context "when giving too many arguments" do

      it "raises an ArgumentError" do
        expect do
          typed_array.[]=(1,2,3,4)
        end.to raise_error(ArgumentError, /wrong number of arguments/)
      end
    end
  end
end
