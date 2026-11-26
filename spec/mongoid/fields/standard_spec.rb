# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Fields::Standard do
  describe '#demongoize' do
    context 'when the field has a type' do
      let(:field) do
        described_class.new(:test, type: Integer)
      end

      it 'demongoizes the object with the type' do
        expect(field.demongoize('42')).to eq(42)
      end

      it 'returns nil for nil' do
        expect(field.demongoize(nil)).to be_nil
      end
    end

    context 'when the field has a custom type' do
      let(:field) do
        described_class.new(:test, type: Image)
      end

      it 'demongoizes the object with the type' do
        expect(field.demongoize('test').name).to eq('test')
      end
    end

    context 'when the field has no type' do
      let(:field) do
        described_class.new(:test)
      end

      it 'returns the object' do
        expect(field.demongoize('42')).to eq('42')
      end
    end
  end

  describe '#evolve' do
    context 'when the field has a type' do
      let(:field) do
        described_class.new(:test, type: Integer)
      end

      it 'evolves the object with the type' do
        expect(field.evolve('42')).to eq(42)
      end

      it 'returns nil for nil' do
        expect(field.evolve(nil)).to be_nil
      end
    end

    context 'when the field has no type' do
      let(:field) do
        described_class.new(:test)
      end

      it 'returns the object' do
        expect(field.evolve('42')).to eq('42')
      end
    end
  end

  describe '#mongoize' do
    context 'when the field has a type' do
      let(:field) do
        described_class.new(:test, type: Integer)
      end

      it 'mongoizes the object with the type' do
        expect(field.mongoize('42')).to eq(42)
      end

      it 'returns nil for nil' do
        expect(field.mongoize(nil)).to be_nil
      end
    end

    context 'when the field has no type' do
      let(:field) do
        described_class.new(:test)
      end

      it 'mongoizes the object itself' do
        expect(field.mongoize(Image.new('test'))).to eq('test')
      end
    end
  end

  describe '#eval_default' do
    let(:field) do
      described_class.new(:test, type: String, default: 'testing')
    end

    let(:person) do
      Person.new
    end

    context 'when the document has no projection' do
      it 'returns the default' do
        expect(field.eval_default(person)).to eq('testing')
      end
    end

    context 'when the projection includes the field' do
      before do
        person.__selected_fields = { 'title' => 1, 'test' => 1 }
      end

      it 'returns the default' do
        expect(field.eval_default(person)).to eq('testing')
      end
    end

    context 'when the projection includes other fields only' do
      before do
        person.__selected_fields = { 'title' => 1 }
      end

      it 'returns nil' do
        expect(field.eval_default(person)).to be_nil
      end
    end

    context 'when the projection excludes the field' do
      before do
        person.__selected_fields = { 'title' => 0, 'test' => 0 }
      end

      it 'returns nil' do
        expect(field.eval_default(person)).to be_nil
      end
    end

    context 'when the projection excludes other fields only' do
      before do
        person.__selected_fields = { 'title' => 0 }
      end

      it 'returns the default' do
        expect(field.eval_default(person)).to eq('testing')
      end
    end
  end

  describe '#lazy?' do
    let(:field) do
      described_class.new(:test, type: String)
    end

    it 'returns false' do
      expect(field).not_to be_lazy
    end
  end

  describe '#pre_processed?' do
    before(:all) do
      class FieldTest
        include Mongoid::Document
      end
    end

    after(:all) do
      Object.send(:remove_const, :FieldTest)
    end

    context 'when the field has a default' do
      context 'when the default is a proc' do
        context 'when the pre-processed option is true' do
          let(:field) do
            described_class.new(
              :test,
              default: -> { 'testing' },
              pre_processed: true,
              klass: FieldTest,
              type: String
            )
          end

          it 'returns true' do
            expect(field).to be_pre_processed
          end
        end

        context 'when the pre-processed option is not true' do
          let(:field) do
            described_class.new(
              :test,
              default: -> { 'testing' },
              klass: FieldTest,
              type: String
            )
          end

          it 'returns false' do
            expect(field).not_to be_pre_processed
          end
        end
      end

      context 'when the default is not a proc' do
        let(:field) do
          described_class.new(
            :test,
            default: 'testing',
            klass: FieldTest,
            type: String
          )
        end

        it 'returns true' do
          expect(field).to be_pre_processed
        end
      end
    end

    context 'when the field has no default' do
      let(:field) do
        described_class.new(
          :test,
          type: String
        )
      end

      it 'returns false' do
        expect(field).not_to be_pre_processed
      end
    end
  end

  context 'when checking hash values in a custom serializer' do
    let(:image) do
      Image.new('test')
    end

    it 'does not conflict with the ruby core hash' do
      expect(image.hash_is_hash).to be true
    end
  end

  context 'when included in a hash' do
    let(:hash) do
      MyHash.new
    end

    context 'when setting a value' do
      before do
        hash[:key] = 'value'
      end

      it 'allows normal hash access' do
        expect(hash[:key]).to eq('value')
      end
    end

    context 'when getting a non existent value' do
      it 'returns nil' do
        expect(hash[:key]).to be_nil
      end
    end
  end

  context 'when subclassing a serializable field' do
    let(:thumbnail) do
      Thumbnail.new('test')
    end

    it 'inherits the parents deserialize method' do
      expect(Thumbnail.demongoize('testy').name).to eq('testy')
    end

    it 'inherits the parents serialize method' do
      expect(thumbnail.mongoize).to eq('test')
    end

    context 'when instantiating the class' do
      let(:movie) do
        Movie.new(
          poster: Image.new('poster'),
          poster_thumb: Thumbnail.new('thumb')
        )
      end

      it 'deserializes the parent type' do
        expect(movie.poster.name).to eq('poster')
      end

      it 'deserializes the child type' do
        expect(movie.poster_thumb.name).to eq('thumb')
      end
    end
  end
end
