require "spec_helper"

describe Mongoid::PersistenceContext do

  describe '#initialize' do

    let(:persistence_context) do
      described_class.new(object, options)
    end

    let(:object) do
      Band
    end

    let(:options) do
      { collection: 'other' }
    end

    context 'when an object is passed' do

      context 'when the object is a klass' do

        it 'sets the object on the persistence context' do
          expect(persistence_context.instance_variable_get(:@object)).to eq(object)
        end
      end

      context 'when the object is a model instance' do

        let(:object) do
          Band.new
        end

        it 'sets the object on the persistence context' do
          expect(persistence_context.instance_variable_get(:@object)).to eq(object)
        end
      end
    end

    context 'when options are passed' do

      let(:options) do
        { connect_timeout: 10 }
      end

      context 'when the options are valid client options' do

        it 'sets the options on the persistence context object' do
          expect(persistence_context.options).to eq(options)
        end
      end

      context 'when the options are not valid client options' do

        context 'when the options are valid extra options' do

          let(:options) do
            { collection: 'other' }
          end

          it 'sets the options on the persistence context object' do
            expect(persistence_context.collection_name).to eq(options[:collection].to_sym)
          end
        end

        context 'when the options are not valid extra options' do

          let(:options) do
            { invalid: 'option' }
          end

          it 'raises an InvalidPersistenceOption error' do
            expect {
              persistence_context
            }.to raise_error(Mongoid::Errors::InvalidPersistenceOption)
          end
        end
      end
    end
  end

  describe '#collection' do

    let(:persistence_context) do
      described_class.new(Band, options)
    end

    let(:options) do
      { read: { 'mode' => :secondary } }
    end

    context 'when a parent object is passed' do

      it 'uses the collection of the parent object' do
        expect(persistence_context.collection(Person.new).name).to eq('people')
      end

      it 'does not memoize the collection' do
        persistence_context.collection
        expect(persistence_context.collection(Person.new).name).to eq('people')
      end

      it 'keeps the other options of the persistence context' do
        expect(persistence_context.collection(Person.new).client.options[:read]).to eq(options[:read])
      end
    end

    context 'when a parent object is not passed' do

      it 'uses the collection of the object' do
        expect(persistence_context.collection.name).to eq('bands')
      end

      it 'does not memoize the collection' do
        persistence_context.collection(Person.new)
        expect(persistence_context.collection.name).to eq('bands')
      end

      it 'keeps the other options of the persistence context' do
        expect(persistence_context.collection.client.options[:read]).to eq(options[:read])
      end
    end
  end

  describe '#collection_name' do

    let(:persistence_context) do
      described_class.new(Band, options)
    end

    let(:options) do
      { collection: 'other' }
    end

    context 'when storage options are set on the object' do

      context 'when there are no options passed to the Persistence Context' do

        let(:options) do
          { }
        end

        context 'when the storage options is static' do

          before do
            Band.store_in collection: :schmands
          end

          it 'uses the storage options' do
            expect(persistence_context.collection_name).to eq(:schmands)
          end
        end

        context 'when the storage options is a block' do

          before do
            Band.store_in collection: ->{ :schmands }
          end

          it 'uses the storage options' do
            expect(persistence_context.collection_name).to eq(:schmands)
          end
        end
      end

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { collection: 'other' }
        end

        context 'when the storage options is static' do

          before do
            Band.store_in collection: :schmands
          end

          it 'uses the persistence context options' do
            expect(persistence_context.collection_name).to eq(:other)
          end
        end

        context 'when the storage options is a block' do

          before do
            Band.store_in collection: ->{ :schmands }
          end

          it 'uses the persistence context options' do
            expect(persistence_context.collection_name).to eq(:other)
          end
        end
      end
    end

    context 'when storage options are not set on the object' do

      context 'when there are options passed to the Persistence Context' do

        let(:options) do
          { collection: 'other' }
        end

        it 'uses the persistence context options' do
          expect(persistence_context.collection_name).to eq(:other)
        end
      end
    end
  end
end
