# frozen_string_literal: true

require "spec_helper"
require_relative './has_one_models'

describe Mongoid::Association::Referenced::BelongsTo do

  before do
    class OwnerObject; include Mongoid::Document; end
    class BelongingObject; include Mongoid::Document; end
  end

  after do
    Object.send(:remove_const, :BelongingObject)
    Object.send(:remove_const, :OwnerObject)
  end

  let(:belonging_class) do
    BelongingObject
  end

  let(:name) do
    :owner_object
  end

  let(:association) do
    belonging_class.belongs_to name, options
  end

  let(:options) do
    { }
  end

  describe '#relation_complements' do

    let(:expected_complements) do
      [
          Mongoid::Association::Referenced::HasMany,
          Mongoid::Association::Referenced::HasOne
      ]
    end

    it 'returns the relation complements' do
      expect(association.relation_complements).to eq(expected_complements)
    end
  end

  describe '#setup!' do

    it 'sets up a getter for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_getter!).with(association)
      association.setup!
    end

    it 'sets up a setter for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_setter!).with(association)
      association.setup!
    end

    it 'sets up an existence check for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_existence_check!).with(association)
      association.setup!
    end

    it 'sets up the builder for the relation' do
      expect(Mongoid::Association::Builders).to receive(:define_builder!).with(association)
      association.setup!
    end

    it 'sets up the creator for the relation' do
      expect(Mongoid::Association::Builders).to receive(:define_creator!).with(association)
      association.setup!
    end

    context 'autosave' do

      context 'when the :autosave option is true' do

        let(:options) do
          {
              autosave: true
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup!! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'sets up autosave' do
          expect(Mongoid::Association::Referenced::AutoSave).to receive(:define_autosave!).with(association)
          association.setup!
        end
      end

      context 'when the :autosave option is false' do

        let(:options) do
          {
              autosave: false
          }
        end

        it 'does not set up autosave' do
          expect(Mongoid::Association::Referenced::AutoSave).not_to receive(:define_autosave!)
          association.setup!
        end
      end

      context 'when the :autosave option is not provided' do

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup!! method will be called by the :embeds_many macro
          described_class.new(belonging_class, name, options)
        end

        it 'does not set up autosave' do
          expect(Mongoid::Association::Referenced::AutoSave).not_to receive(:define_autosave!)
          association.setup!
        end
      end
    end

    context 'counter cache callbacks' do

      context 'when the :counter_cache option is true' do

        let(:options) do
          {
              counter_cache: true
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'sets up counter cache callbacks' do
          expect(Mongoid::Association::Referenced::CounterCache).to receive(:define_callbacks!).with(association)
          association.setup!
        end
      end

      context 'when the :counter_cache option is a String' do

        let(:options) do
          {
              counter_cache: 'counts_field'
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'sets up counter cache callbacks' do
          expect(Mongoid::Association::Referenced::CounterCache).to receive(:define_callbacks!).with(association)
          association.setup!
        end
      end

      context 'when the :counter_cache option is false' do

        let(:options) do
          {
              counter_cache: false
          }
        end

        it 'does not set up counter cache callbacks' do
          expect(Mongoid::Association::Referenced::CounterCache).not_to receive(:define_callbacks!)
          association.setup!
        end
      end

      context 'when the :counter_cache option is not provided' do

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :embeds_many macro
          described_class.new(belonging_class, name, options)
        end

        it 'does not set up counter cache callbacks' do
          expect(Mongoid::Association::Referenced::CounterCache).not_to receive(:define_callbacks!)
          association.setup!
        end
      end
    end

    context 'polymorphic' do

      context 'when the polymorphic option is provided' do

        context 'when the polymorphic option is true' do

          let(:options) do
            {
              polymorphic: true
            }
          end

          before do
            association
          end

          it 'set the polymorphic attribute on the owner class' do
            expect(belonging_class.polymorphic).to be(true)
          end

          it 'sets up a field for the inverse type' do
            expect(belonging_class.fields.keys).to include(association.inverse_type)
          end
        end

        context 'when the polymorphic option is false' do

          let(:options) do
            {
              polymorphic: false
            }
          end

          it 'does not set the polymorphic attribute on the owner class' do
            expect(belonging_class.polymorphic).to be(false)
          end

          it 'does not set up a field for the inverse type' do
            expect(belonging_class.fields.keys).not_to include(association.inverse_type)
          end
        end
      end

      context 'when the polymorphic option is not provided' do

        it 'does not set the polymorphic attribute on the owner class' do
          expect(belonging_class.polymorphic).to be(false)
        end

        it 'does not set up a field for the inverse type' do
          expect(belonging_class.fields.keys).not_to include(association.inverse_type)
        end
      end
    end

    context 'dependent' do

      context 'when the dependent option is provided' do

        context 'when the dependent option is :delete_all' do

          let(:options) do
            {
              dependent: :delete_all
            }
          end

          let(:association) do
            # Note that it is necessary to create the association directly, otherwise the
            # setup! method will be called by the :belongs_to macro
            described_class.new(belonging_class, name, options)
          end

          it 'sets up the dependency' do
            expect(Mongoid::Association::Depending).to receive(:define_dependency!)
            association.setup!
          end
        end

        context 'when the dependent option is :destroy' do

          let(:options) do
            {
                dependent: :destroy
            }
          end

          let(:association) do
            # Note that it is necessary to create the association directly, otherwise the
            # setup! method will be called by the :belongs_to macro
            described_class.new(belonging_class, name, options)
          end

          it 'sets up the dependency' do
            expect(Mongoid::Association::Depending).to receive(:define_dependency!)
            association.setup!
          end
        end

        context 'when the dependent option is :nullify' do

          let(:options) do
            {
                dependent: :nullify
            }
          end

          let(:association) do
            # Note that it is necessary to create the association directly, otherwise the
            # setup! method will be called by the :belongs_to macro
            described_class.new(belonging_class, name, options)
          end

          it 'sets up the dependency' do
            expect(Mongoid::Association::Depending).to receive(:define_dependency!)
            association.setup!
          end
        end

        context 'when the dependent option is :restrict_with_exception' do

          let(:options) do
            {
                dependent: :restrict_with_exception
            }
          end

          let(:association) do
            # Note that it is necessary to create the association directly, otherwise the
            # setup! method will be called by the :belongs_to macro
            described_class.new(belonging_class, name, options)
          end

          it 'sets up the dependency' do
            expect(Mongoid::Association::Depending).to receive(:define_dependency!)
            association.setup!
          end
        end

        context 'when the dependent option is :restrict_with_error' do

          let(:options) do
            {
                dependent: :restrict_with_error
            }
          end

          let(:association) do
            # Note that it is necessary to create the association directly, otherwise the
            # setup! method will be called by the :belongs_to macro
            described_class.new(belonging_class, name, options)
          end

          it 'sets up the dependency' do
            expect(Mongoid::Association::Depending).to receive(:define_dependency!)
            association.setup!
          end
        end
      end

      context 'when the dependent option is not provided' do

        it 'does not set up the dependency' do
          expect(Mongoid::Association::Depending).not_to receive(:define_dependency!)
          association.setup!
        end
      end
    end

    context 'foreign key field' do

      before do
        association
      end

      it 'sets up the foreign key field' do
        expect(belonging_class.fields.keys).to include(association.foreign_key)
      end
    end

    context 'index' do

      before do
        association
      end

      context 'when index is true' do

        context 'when polymorphic' do

          let(:options) do
            {
                polymorphic: true,
                index: true
            }
          end

          it 'sets up the index with the key and inverse type' do
            expect(belonging_class.index_specifications.first.fields).to match_array([ association.key.to_sym,
                                                                                       association.inverse_type.to_sym])
          end
        end

        context 'when not polymorphic' do

          let(:options) do
            {
                index: true
            }
          end

          it 'sets up the index with the key' do
            expect(belonging_class.index_specifications.first.fields).to match_array([ association.key.to_sym ])
          end
        end
      end

      context 'when index is false' do

        context 'when polymorphic' do

          let(:options) do
            {
                polymorphic: true
            }
          end

          it 'does not set up an index' do
            expect(belonging_class.index_specifications).to eq([ ])
          end
        end

        context 'when not polymorphic' do

          it 'does not set up an index' do
            expect(belonging_class.index_specifications).to eq([ ])
          end
        end
      end
    end

    context 'touchable' do

      context 'when the :touch option is true' do

        let(:options) do
          {
              touch: true
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'sets up touch' do
          expect(Mongoid::Touchable).to receive(:define_touchable!).with(association)
          association.setup!
        end
      end

      context 'when the :touch option is false' do

        let(:options) do
          {
              touch: false
          }
        end

        it 'does not set up touch' do
          expect(Mongoid::Touchable).not_to receive(:define_touchable!).with(association)
          association.setup!
        end
      end

      context 'when the :touch option is not provided' do

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :embeds_many macro
          described_class.new(belonging_class, name, options)
        end

        it 'does not set up touch' do
          expect(Mongoid::Touchable).not_to receive(:define_touchable!).with(association)
          association.setup!
        end
      end
    end

    context 'validate' do

      context 'when the :validate option is true' do

        let(:options) do
          {
              validate: true
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'sets up validation' do
          expect(belonging_class).to receive(:validates_associated).with(name).and_call_original
          association.setup!
        end
      end

      context 'when the :validate option is false' do

        let(:options) do
          {
              validate: false
          }
        end

        it 'does not set up validation' do
          expect(belonging_class).not_to receive(:validates_associated)
          association.setup!
        end
      end

      context 'when the :validate option is not provided' do

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :belongs_to macro
          described_class.new(belonging_class, name, options)
        end

        it 'does not set up the validation because it uses the validation default (false)' do
          expect(belonging_class).not_to receive(:validates_associated)
          association.setup!
        end
      end
    end

    context 'presence of validation' do

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :belongs_to macro
        described_class.new(belonging_class, name, options)
      end

      context 'when the global config option is true' do
        config_override :belongs_to_required_by_default, true

        context 'when the required option is true' do

          let(:options) do
            {
                required: true
            }
          end

          it 'sets up the presence of validation' do
            expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  required: true,
                  optional: true
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  required: true,
                  optional: false
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end
        end

        context 'when the required option is false' do

          let(:options) do
            {
                required: false
            }
          end

          it 'does not set up the presence of validation' do
            expect(belonging_class).not_to receive(:validates)
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  required: false,
                  optional: true
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  required: false,
                  optional: false
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end
        end

        context 'when the required option is not provided' do

          it 'uses the default and sets up the presence of validation' do
            expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  optional: true
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  optional: false
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end
        end
      end

      context 'when the global config option is false' do
        config_override :belongs_to_required_by_default, false

        context 'when the required option is true' do

          let(:options) do
            {
                required: true
            }
          end

          it 'sets up the presence of validation' do
            expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  required: true,
                  optional: true
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  required: true,
                  optional: false
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end
        end

        context 'when the required option is false' do

          let(:options) do
            {
                required: false
            }
          end

          it 'does not set up the presence of validation' do
            expect(belonging_class).not_to receive(:validates)
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  required: false,
                  optional: true
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  required: false,
                  optional: false
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end
        end

        context 'when the required option is not provided' do

          it 'uses the default and does not set up the presence of validation' do
            expect(belonging_class).not_to receive(:validates)
            association.setup!
          end

          context 'when the optional option is true' do

            let(:options) do
              {
                  optional: true
              }
            end

            it 'does not set up the presence of validation' do
              expect(belonging_class).not_to receive(:validates)
              association.setup!
            end
          end

          context 'when the optional option is false' do

            let(:options) do
              {
                  optional: false
              }
            end

            it 'sets up the presence of validation' do
              expect(belonging_class).to receive(:validates).with(name, { presence: true }).and_call_original
              association.setup!
            end
          end
        end
      end
    end
  end

  describe '#type' do

    context 'when polymorphic' do

      let(:options) do
        { polymorphic: true }
      end

      it 'returns nil' do
        expect(association.type).to be_nil
      end
    end

    context 'when not polymorphic' do

      it 'returns nil' do
        expect(association.type).to be_nil
      end
    end
  end

  describe '#inverse_type' do

    context 'when polymorphic' do

      let(:options) do
        { polymorphic: true }
      end

      it 'returns the name followed by "_type"' do
        expect(association.inverse_type).to eq("#{name}_type")
      end
    end

    context 'when not polymorphic' do

      it 'returns nil' do
        expect(association.inverse_type).to be_nil
      end
    end
  end

  describe '#inverse_type_setter' do

    context 'when polymorphic' do

      let(:options) do
        { polymorphic: true }
      end

      it 'returns the inverse type setter' do
        expect(association.inverse_type_setter).to eq("#{name}_type=")
      end
    end

    context 'when not polymorphic' do

      it 'returns nil' do
        expect(association.inverse_type_setter).to be_nil
      end
    end
  end

  describe '#foreign_key' do

    context 'when options has foreign_key specified' do

      let(:options) do
        { foreign_key: :other_object_id }
      end

      it 'returns the foreign key' do
        expect(association.foreign_key).to eq(options[:foreign_key].to_s)
      end
    end

    context 'when options does not have foreign_key specified' do

      it 'returns the ame followed by "_id"' do
        expect(association.foreign_key).to eq("#{name}_id")
      end
    end
  end

  describe '#embedded?' do

    it 'returns false' do
      expect(association.embedded?).to be(false)
    end
  end

  describe '#primary_key' do

    context 'when the :primary_key option is specified' do

      context 'when the :primary_key option is true' do

        let(:options) do
          {
              primary_key: :other_primary_key
          }
        end

        it 'returns the primary key option as a String' do
          expect(association.primary_key).to eq('other_primary_key')
        end
      end
    end

    context 'when the :primary_key option is not specified' do

      it 'returns the default primary key' do
        expect(association.primary_key).to eq(Mongoid::Association::Relatable::PRIMARY_KEY_DEFAULT)
      end
    end
  end

  describe '#indexed?' do

    context 'when :index is specified in the options' do

      context 'when :index is true' do

        let(:options) do
          {
              index: true
          }
        end

        it 'returns true' do
          expect(association.indexed?).to be(true)
        end
      end

      context 'when :index is false' do

        let(:options) do
          {
              index: false
          }
        end

        it 'returns false' do
          expect(association.indexed?).to be(false)
        end
      end
    end

    context 'when :index is not specified in the options' do

      it 'returns nil' do
        expect(association.indexed?).to be(false)
      end
    end
  end

  describe '#relation' do

    it 'returns Mongoid::Association::Referenced::BelongsTo::Proxy' do
      expect(association.relation).to be(Mongoid::Association::Referenced::BelongsTo::Proxy)
    end
  end

  describe '#validation_default' do

    it 'returns false' do
      expect(association.validation_default).to be(false)
    end
  end

  describe '#name' do

    it 'returns the name of the relation' do
      expect(association.name).to be(name)
    end
  end

  describe '#options' do

    it 'returns the options' do
      expect(association.options).to be(options)
    end
  end

  describe '#cyclic?' do

    it 'returns false' do
      expect(association.cyclic?).to be(false)
    end
  end

  describe '#merge!' do

  end

  describe '#store_as' do

    it 'returns nil' do
      expect(association.store_as).to be_nil
    end
  end

  describe '#touchable?' do

    context 'when :touch is in the options' do

      let(:options) do
        { touch: true}
      end

      it 'returns true' do
        expect(association.send(:touchable?)).to be(true)
      end
    end

    context 'when :touch is not in the options' do

      it 'return false' do
        expect(association.send(:touchable?)).to be(false)
      end
    end
  end

  describe '#order' do

    it 'returns nil' do
      expect(association.order).to be_nil
    end
  end

  describe '#scope' do

    context 'when scope is specified in the options' do

      let(:options) do
        { scope: -> { unscoped.where(foo: :bar) } }
      end

      it 'returns a Criteria Queryable Key' do
        expect(association.scope).to be_a(Proc)
      end
    end

    context 'when scope is not specified in the options' do

      it 'returns nil' do
        expect(association.scope).to be_nil
      end
    end
  end

  describe '#as' do

    it 'returns nil' do
      expect(association.as).to be_nil
    end
  end

  describe '#polymorphic?' do

    context 'when :polymorphic is specified in the options as true' do

      let(:options) do
        { polymorphic: true }
      end

      it 'returns true' do
        expect(association.polymorphic?).to be(true)
      end
    end

    context 'when :polymorphic is specified in the options as false' do

      let(:options) do
        { polymorphic: false }
      end

      it 'returns false' do
        expect(association.polymorphic?).to be(false)
      end
    end

    context 'when :polymorphic is not specified in the options' do

      it 'returns false' do
        expect(association.polymorphic?).to be(false)
      end
    end
  end

  describe '#dependent' do

    context 'when the dependent option is provided' do

      context 'when the dependent option is :delete_all' do

        let(:options) do
          {
              dependent: :delete_all
          }
        end

        it 'returns :delete_all' do
          expect(association.dependent).to eq(:delete_all)
        end
      end

      context 'when the dependent option is :destroy' do

        let(:options) do
          {
              dependent: :destroy
          }
        end

        it 'returns :destroy' do
          expect(association.dependent).to eq(:destroy)
        end
      end

      context 'when the dependent option is :nullify' do

        let(:options) do
          {
              dependent: :nullify
          }
        end

        it 'returns :nullify' do
          expect(association.dependent).to eq(:nullify)
        end
      end

      context 'when the dependent option is :restrict_with_exception' do

        let(:options) do
          {
              dependent: :restrict_with_exception
          }
        end

        it 'returns :restrict_with_exception' do
          expect(association.dependent).to eq(:restrict_with_exception)
        end
      end

      context 'when the dependent option is :restrict_with_error' do

        let(:options) do
          {
              dependent: :restrict_with_error
          }
        end

        it 'returns :restrict_with_error' do
          expect(association.dependent).to eq(:restrict_with_error)
        end
      end
    end

    context 'when the dependent option is not provided' do

      it 'returns nil' do
        expect(association.dependent).to be_nil
      end
    end
  end

  describe '#bindable?' do

    it 'returns false' do
      expect(association.bindable?(Person.new)).to be(false)
    end
  end

  describe '#inverses' do

    context 'when polymorphic' do

      let(:options) do
        {
            polymorphic: true
        }
      end

      let(:name) do
        :containable
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          OwnerObject.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          before do
            OwnerObject.has_one :belonging_object, as: :containable
          end

          context 'when :inverse_of is specified' do

            before do
              options.merge!(inverse_of: :inverse_name)
            end

            it 'returns the :inverse_of value' do
              expect(association.inverses(instance_of_other_class)).to eq([ :inverse_name ])
            end
          end

          context 'when inverse_of is not specified' do

            it 'returns the list of relations whose :as attribute matches the name of this association' do
              expect(association.inverses(instance_of_other_class)).to match_array([ :belonging_object ])
            end
          end
        end

        context 'when the relation class has more than one relation whose class matches the owning class' do

          before do
            OwnerObject.has_one :other_belonging_object, as: :containable, class_name: 'BelongingObject'
            OwnerObject.has_one :belonging_object, as: :containable
          end

          context 'when :inverse_of is specified' do

            before do
              options.merge!(inverse_of: :inverse_name)
            end

            it 'returns the :inverse_of value' do
              expect(association.inverses(instance_of_other_class)).to eq([ :inverse_name ])
            end
          end

          context 'when inverse_of is not specified' do

            it 'returns the list of relations whose :as attribute matches the name of this association' do
              expect(association.inverses(instance_of_other_class)).to match_array([ :other_belonging_object,
                                                                                     :belonging_object ])
            end

            context 'when the relation class has two associations with the same name' do

              before do
                OwnerObject.has_one :belonging_object, as: :containable
                OwnerObject.has_one :other_belonging_object, as: :containable
              end

              it 'returns only the relations whose :as attribute and class match' do
                expect(association.inverses(instance_of_other_class)).to match_array([ :belonging_object ])
              end
            end
          end
        end
      end

      context 'when another object is not passed to the method' do

        context 'when inverse_of is specified' do

          before do
            options.merge!(inverse_of: :inverse_name)
          end

          it 'returns the :inverse_of value' do
            expect(association.inverses).to eq([ :inverse_name ])
          end
        end

        context 'when inverse_of is not specified' do

          it 'returns nil' do
            expect(association.inverses).to eq(nil)
          end
        end
      end
    end

    context 'when not polymorphic' do

      context 'when inverse_of is specified' do

        before do
          options.merge!(inverse_of: :inverse_name)
        end

        it 'returns the :inverse_of value' do
          expect(association.inverses).to eq([ :inverse_name ])
        end
      end

      context 'when inverse_of is not specified' do

        before do
          OwnerObject.has_many :belonging_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverses).to eq([ :belonging_objects ])
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end

      context 'when the inverse class has more than one relation with objects of the owner class' do

        before do
          OwnerObject.has_many :belonging_objects
          OwnerObject.has_one :other_belonging_object, class_name: 'BelongingObject'
        end

        it 'raises a Mongoid::Errors::AmbiguousRelationship exception' do
          expect {
            association.inverses
          }.to raise_exception(Mongoid::Errors::AmbiguousRelationship)
        end
      end

      context 'when the inverse class only has one relation with objects of the owner class' do

        before do
          OwnerObject.has_many :belonging_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverses).to eq([ :belonging_objects ])
        end
      end
    end
  end

  describe '#inverse' do

    context 'when polymorphic' do

      let(:options) do
        {
            polymorphic: true
        }
      end

      let(:name) do
        :containable
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          OwnerObject.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          before do
            OwnerObject.has_many :belonging_objects, as: :containable
          end

          context 'when :inverse_of is specified' do

            before do
              options.merge!(inverse_of: :inverse_name)
            end

            it 'returns the :inverse_of value' do
              expect(association.inverse(instance_of_other_class)).to eq(:inverse_name)
            end
          end

          context 'when inverse_of is not specified' do

            it 'returns the list of relations whose :as attribute matches the name of this association' do
              expect(association.inverse(instance_of_other_class)).to eq(:belonging_objects)
            end
          end
        end

        context 'when the relation class has more than one relation whose class matches the owning class' do

          before do
            OwnerObject.has_one :other_belonging_object, as: :containable, class_name: 'BelongingObject'
            OwnerObject.has_one :belonging_object, as: :containable
          end

          context 'when :inverse_of is specified' do

            before do
              options.merge!(inverse_of: :inverse_name)
            end

            it 'returns the :inverse_of value' do
              expect(association.inverse(instance_of_other_class)).to eq(:inverse_name)
            end
          end

          context 'when inverse_of is not specified' do

            it 'returns the first candidate whose :as attribute matches the name of this association' do
              expect(association.inverse(instance_of_other_class)).to eq(:other_belonging_object)
            end
          end
        end
      end

      context 'when another object is not passed to the method' do

        context 'when inverse_of is specified' do

          before do
            options.merge!(inverse_of: :inverse_name)
          end

          it 'returns the :inverse_of value' do
            expect(association.inverse).to eq(:inverse_name)
          end
        end

        context 'when inverse_of is not specified' do

          it 'returns nil' do
            expect(association.inverse).to eq(nil)
          end
        end
      end
    end

    context 'when not polymorphic' do

      context 'when inverse_of is specified' do

        before do
          options.merge!(inverse_of: :inverse_name)
        end

        it 'returns the :inverse_of value' do
          expect(association.inverse).to eq(:inverse_name)
        end
      end

      context 'when inverse_of is not specified' do

        before do
          OwnerObject.has_many :belonging_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverse).to eq(:belonging_objects)
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end

      context 'when the inverse class has more than one relation with objects of the owner class' do

        before do
          OwnerObject.has_many :belonging_objects
          OwnerObject.has_many :other_belonging_objects, class_name: 'BelongingObject'
        end

        it 'raises a Mongoid::Errors::AmbiguousRelationship exception' do
          expect {
            association.inverse
          }.to raise_exception(Mongoid::Errors::AmbiguousRelationship)
        end
      end

      context 'when the inverse class only has one relation with objects of the owner class' do

        before do
          OwnerObject.has_many :belonging_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverse).to eq(:belonging_objects)
        end
      end
    end
  end

  describe '#inverse_association' do

  end

  describe '#autosave' do

    context 'when the :autosave option is specified' do

      context 'when the :autosave option is true' do

        let(:options) do
          {
              autosave: true
          }
        end

        it 'returns true' do
          expect(association.autosave).to be(true)
        end
      end

      context 'when the :autosave option is false' do

        let(:options) do
          {
              autosave: false
          }
        end

        it 'returns false' do
          expect(association.autosave).to be(false)
        end
      end
    end

    context 'when the :autosave option is not specified' do

      it 'returns nil' do
        expect(association.autosave).to be(false)
      end
    end
  end

  describe '#counter_cached?' do

    context 'when the :counter_cache option is true' do

      let(:options) do
        {
            counter_cache: true
        }
      end

      it 'returns true' do
        expect(association.counter_cached?).to be(true)
      end
    end

    context 'when the :counter_cache option is a String' do

      let(:options) do
        {
            counter_cache: 'counts_field'
        }
      end

      it 'returns true' do
        expect(association.counter_cached?).to be(true)
      end
    end

    context 'when the :counter_cache option is false' do

      let(:options) do
        {
            counter_cache: false
        }
      end

      it 'returns false' do
        expect(association.counter_cached?).to be(false)
      end
    end

    context 'when the :counter_cache option is not provided' do

      it 'returns false' do
        expect(association.counter_cached?).to be(false)
      end
    end
  end

  describe '#counter_cache_column_name' do

    context 'when the :counter_cache option is true' do

      let(:options) do
        {
            counter_cache: true
        }
      end

      it 'returns the inverse name followed by "_count"' do
        expect(association.counter_cache_column_name).to eq('belonging_objects_count')
      end
    end

    context 'when the :counter_cache option is a String' do

      let(:options) do
        {
            counter_cache: 'counts_field'
        }
      end

      it 'returns the String' do
        expect(association.counter_cache_column_name).to eq('counts_field')
      end
    end
  end

  describe '#relation_class_name' do

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherOwnerObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('OtherOwnerObject')
      end
    end

    context 'when the :class_name option is scoped with ::' do

      let(:options) do
        { class_name: '::OtherOwnerObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('::OtherOwnerObject')
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class_name).to eq('OwnerObject')
      end
    end

    context 'when the association is polymorphic' do
      let(:association) do
        HomPolymorphicChild.relations['p_parent']
      end

      it 'is the computed class name that does not match any existing class' do
        expect(association.relation_class_name).to eq('PParent')
      end
    end
  end

  describe '#relation_class' do

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherOwnerObject' }
      end

      it 'returns the named class' do
        expect(association.relation_class).to eq(OtherOwnerObject)
      end
    end

    context 'when the :class_name option is scoped with ::' do

      let(:options) do
        { class_name: '::OtherOwnerObject' }
      end

      it 'returns the named class' do
        expect(association.relation_class).to eq(OtherOwnerObject)
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class).to eq(OwnerObject)
      end
    end

    context 'when the association is polymorphic' do
      let(:association) do
        HomPolymorphicChild.relations['p_parent']
      end

      it 'raises NameError' do
        expect do
          association.relation_class
        end.to raise_error(NameError, /uninitialized constant .*PParent/)
      end
    end
  end

  describe '#inverse_class_name' do

    it 'returns the name of the owner class' do
      expect(association.inverse_class_name).to eq(belonging_class.name)
    end

    context 'polymorphic association' do
      let(:association) do
        belonging_class.belongs_to :poly_owner, polymorphic: true
      end

      it 'returns the name of the owner class' do
        expect(association.inverse_class_name).to eq(belonging_class.name)
      end
    end
  end

  describe '#inverse_class' do

    it 'returns the owner class' do
      expect(association.inverse_class).to be(belonging_class)
    end

    context 'polymorphic association' do
      let(:association) do
        belonging_class.belongs_to :poly_owner, polymorphic: true
      end

      it 'returns the owner class' do
        expect(association.inverse_class).to be(belonging_class)
      end
    end
  end

  describe '#inverse_of' do

    context 'when :inverse_of is specified in the options' do

      let(:options) do
        { inverse_of: :a_belonging_object }
      end

      it 'returns the inverse_of value' do
        expect(association.inverse_of).to eq(options[:inverse_of])
      end
    end

    context 'when :inverse_of is not specified in the options' do

      it 'returns nil' do
        expect(association.inverse_of).to be_nil
      end
    end
  end

  describe '#key' do

    it 'returns the name of the foreign_key as a string' do
      expect(association.key).to eq(association.foreign_key.to_s)
    end
  end

  describe '#setter' do

    it 'returns a string of the name followed by =' do
      expect(association.setter).to eq("#{name}=")
    end
  end

  describe '#validate?' do

    context 'when :validate is specified in the options' do

      context 'when validate is true' do

        let(:options) do
          { validate: true }
        end

        it 'returns true' do
          expect(association.send(:validate?)).to be(true)
        end
      end

      context 'when validate is false' do

        let(:options) do
          { validate: false }
        end

        it 'returns false' do
          expect(association.send(:validate?)).to be(false)
        end
      end
    end

    context 'when :validate is not specified in the options' do

      it 'returns the validation_default' do
        expect(association.send(:validate?)).to eq(association.validation_default)
      end
    end
  end

  describe '#autobuilding?' do

    context 'when :autobuild is specified in the options' do

      context 'when autobuild is true' do

        let(:options) do
          { autobuild: true }
        end

        it 'returns true' do
          expect(association.autobuilding?).to be(true)
        end
      end

      context 'when autobuild is false' do

        let(:options) do
          { autobuild: false }
        end

        it 'returns true' do
          expect(association.autobuilding?).to be(false)
        end
      end
    end

    context 'when :validate is not specified in the options' do

      it 'returns false' do
        expect(association.autobuilding?).to be(false)
      end
    end
  end

  describe '#forced_nil_inverse?' do

    it 'returns false' do
      expect(association.forced_nil_inverse?).to be(false)
    end
  end

  describe '#stores_foreign_key?' do

    it 'returns true' do
      expect(association.stores_foreign_key?).to be(true)
    end
  end

  describe '#inverse_setter' do

    context 'when an inverse can be determined' do

      before do
        OwnerObject.has_many :belonging_objects
      end

      it 'returns the name of the inverse followed by =' do
        expect(association.inverse_setter).to eq('belonging_objects=')
      end
    end

    context 'when an inverse cannot be determined' do

      it 'returns nil' do
        expect(association.inverse_setter).to be_nil
      end
    end
  end

  describe '#extension' do

    context 'when a block is passed' do

      let(:association) do
        belonging_class.belongs_to name, options do; end
      end

      it 'defines an extension module' do
        expect(association.extension).to be_a(Module)
      end

      it 'returns the extension' do
        expect(association.extension).to eq(
          "#{belonging_class.name}::#{belonging_class.name}#{name.to_s.camelize}RelationExtension".constantize)
      end
    end

    context 'when an :extension is not specified in the options' do

      it 'returns false' do
        expect(association.extension).to be_nil
      end
    end
  end

  describe '#foreign_key_setter' do

    it 'returns the foreign key field followed by "="' do
      expect(association.foreign_key_setter).to eq("owner_object_id=")
    end
  end

  describe '#destructive?' do

    context 'when the dependent option is provided' do

      context 'when the dependent option is :delete_all' do

        let(:options) do
          {
              dependent: :delete_all
          }
        end

        it 'returns true' do
          expect(association.destructive?).to be(true)
        end
      end

      context 'when the dependent option is :destroy' do

        let(:options) do
          {
              dependent: :destroy
          }
        end

        it 'returns true' do
          expect(association.destructive?).to be(true)
        end
      end

      context 'when the dependent option is :nullify' do

        let(:options) do
          {
              dependent: :nullify
          }
        end

        it 'returns false' do
          expect(association.destructive?).to be(false)
        end
      end

      context 'when the dependent option is :restrict_with_exception' do

        let(:options) do
          {
              dependent: :restrict_with_exception
          }
        end

        it 'returns false' do
          expect(association.destructive?).to be(false)
        end
      end

      context 'when the dependent option is :restrict_with_error' do

        let(:options) do
          {
              dependent: :restrict_with_error
          }
        end

        it 'returns false' do
          expect(association.destructive?).to be(false)
        end
      end
    end

    context 'when the dependent option is not provided' do

      it 'returns false' do
        expect(association.destructive?).to be(false)
      end
    end
  end

  describe '#nested_builder' do

    it 'returns an instance of Association::Nested::One' do
      expect(association.nested_builder({}, {})).to be_a(Mongoid::Association::Nested::One)
    end
  end

  describe '#path' do

    it 'returns an instance of Mongoid::Atomic::Paths::Root' do
      expect(association.path({})).to be_a(Mongoid::Atomic::Paths::Root)
    end
  end

  describe '#foreign_key_check' do

    it 'returns the foreign_key followed by "_previously_changed?"' do
      expect(association.foreign_key_check).to eq('owner_object_id_previously_changed?')
    end
  end

  describe '#create_relation' do

    let(:owner) do
      BelongingObject.new
    end

    let(:target) do
      OwnerObject.new
    end

    before do
      OwnerObject.has_one :belonging_object
    end

    it 'returns an instance of Mongoid::Association::Referenced::BelongsTo::Proxy' do
      expect(Mongoid::Association::Referenced::BelongsTo::Proxy).to receive(:new).and_call_original
      expect(association.create_relation(owner, target)).to be_a(OwnerObject)
    end
  end
end
