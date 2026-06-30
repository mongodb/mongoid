# frozen_string_literal: true

require 'spec_helper'

# BSON::Vector only exists in bson-ruby >= 5.1, so the model and all examples
# are guarded by min_bson_version. The describe argument is a string (not the
# constant) so this file loads cleanly on older bson versions.
if defined?(BSON::Vector)
  class VectorEmbedding
    include Mongoid::Document

    field :embedding, type: BSON::Vector
  end
end

describe 'BSON::Vector field type' do
  min_bson_version '5.1'

  shared_examples 'a vector round-trip' do
    let(:vector) do
      BSON::Vector.new(values, dtype, padding)
    end

    let(:binary) do
      BSON::Binary.from_vector(vector)
    end

    describe '.mongoize' do
      it 'returns the matching vector binary' do
        expect(BSON::Vector.mongoize(vector)).to eq(binary)
        expect(BSON::Vector.mongoize(vector).type).to eq(:vector)
      end
    end

    describe '.demongoize' do
      let(:demongoized) do
        BSON::Vector.demongoize(binary)
      end

      it 'preserves the values, dtype and padding' do
        expect(demongoized).to be_a(BSON::Vector)
        expect(demongoized.to_a).to eq(values)
        expect(demongoized.dtype).to eq(dtype)
        expect(demongoized.padding).to eq(padding)
      end
    end

    context 'when used as a field type' do
      let!(:model) do
        VectorEmbedding.create!(embedding: vector)
      end

      let(:reloaded) do
        VectorEmbedding.find(model._id)
      end

      it 'stores the value as a vector binary' do
        stored = VectorEmbedding.collection.find(_id: model._id).first['embedding']
        expect(stored).to be_a(BSON::Binary)
        expect(stored.type).to eq(:vector)
      end

      it 'reads the value back as an equivalent BSON::Vector' do
        expect(reloaded.embedding).to be_a(BSON::Vector)
        expect(reloaded.embedding.to_a).to eq(values)
        expect(reloaded.embedding.dtype).to eq(dtype)
        expect(reloaded.embedding.padding).to eq(padding)
      end
    end
  end

  context 'with an int8 vector' do
    let(:values) { [ 1, 2, 3 ] }
    let(:dtype) { :int8 }
    let(:padding) { 0 }

    it_behaves_like 'a vector round-trip'
  end

  context 'with a float32 vector' do
    let(:values) { [ 1.5, -2.0, 0.25 ] }
    let(:dtype) { :float32 }
    let(:padding) { 0 }

    it_behaves_like 'a vector round-trip'
  end

  context 'with a packed_bit vector' do
    let(:values) { [ 255, 0, 128 ] }
    let(:dtype) { :packed_bit }
    let(:padding) { 3 }

    it_behaves_like 'a vector round-trip'
  end

  describe '#mongoize' do
    let(:vector) do
      BSON::Vector.new([ 1, 2, 3 ], :int8)
    end

    it 'delegates to the class method and returns a vector binary' do
      expect(vector.mongoize).to eq(BSON::Binary.from_vector(vector))
      expect(vector.mongoize.type).to eq(:vector)
    end

    # Regression guard: BSON::Vector < ::Array, and Array has its own Mongoid
    # extension. Without our override the value would be mongoized as a plain
    # array, losing the vector subtype.
    it 'does not mongoize via the Array extension' do
      expect(vector.mongoize).to be_a(BSON::Binary)
      expect(vector.mongoize).not_to be_a(Array)
    end
  end

  describe '.mongoize' do
    let(:vector) do
      BSON::Vector.new([ 1, 2, 3 ], :int8)
    end

    context 'when given a vector BSON::Binary' do
      it 'returns it unchanged' do
        binary = BSON::Binary.from_vector(vector)
        expect(BSON::Vector.mongoize(binary)).to eq(binary)
      end
    end

    context 'when given nil' do
      it 'returns nil' do
        expect(BSON::Vector.mongoize(nil)).to be_nil
      end
    end

    context 'when given a plain array' do
      it 'returns nil' do
        expect(BSON::Vector.mongoize([ 1, 2, 3 ])).to be_nil
      end
    end

    context 'when given an uncastable type' do
      it 'returns nil' do
        expect(BSON::Vector.mongoize(true)).to be_nil
      end
    end
  end

  describe '.demongoize' do
    let(:vector) do
      BSON::Vector.new([ 1, 2, 3 ], :int8)
    end

    context 'when given a BSON::Vector' do
      it 'returns it unchanged' do
        expect(BSON::Vector.demongoize(vector)).to eq(vector)
      end
    end

    context 'when given a non-vector BSON::Binary' do
      it 'returns nil' do
        expect(BSON::Vector.demongoize(BSON::Binary.new('x', :generic))).to be_nil
      end
    end

    context 'when given nil' do
      it 'returns nil' do
        expect(BSON::Vector.demongoize(nil)).to be_nil
      end
    end

    context 'when given an uncastable type' do
      it 'returns nil' do
        expect(BSON::Vector.demongoize(true)).to be_nil
      end
    end
  end
end
