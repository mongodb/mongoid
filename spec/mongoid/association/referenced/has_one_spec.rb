# frozen_string_literal: true

require "spec_helper"
require_relative './has_one_models'

describe Mongoid::Association::Referenced::HasOne do

  before do
    class OwnerObject; include Mongoid::Document; end
    class BelongingObject; include Mongoid::Document; end
  end

  after do
    Object.send(:remove_const, :BelongingObject)
    Object.send(:remove_const, :OwnerObject)
  end

  let(:has_one_class) do
    OwnerObject
  end

  let(:name) do
    :belonging_object
  end

  let(:association) do
    has_one_class.has_one name, options
  end

  let(:options) do
    { }
  end

  describe '#relation_complements' do

    let(:expected_complements) do
      [
          Mongoid::Association::Referenced::BelongsTo,
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
          # setup! method will be called by the :has_one macro
          described_class.new(has_one_class, name, options)
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
          # setup! method will be called by the :has_one macro
          described_class.new(has_one_class, name, options)
        end

        it 'does not set up autosave' do
          expect(Mongoid::Association::Referenced::AutoSave).not_to receive(:define_autosave!)
          association.setup!
        end
      end
    end

    context 'when the :validate option is true' do

      let(:options) do
        {
            validate: true
        }
      end

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :has_one macro
        described_class.new(has_one_class, name, options)
      end

      it 'sets up validation' do
        expect(has_one_class).to receive(:validates_associated).with(name).and_call_original
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
        expect(has_one_class).not_to receive(:validates_associated)
        association.setup!
      end
    end

    context 'when the :validate option is not provided' do

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :embeds_one macro
        described_class.new(has_one_class, name, options)
      end

      it 'sets up the validation because it uses the validation default (true)' do
        expect(has_one_class).to receive(:validates_associated).with(name).and_call_original
        association.setup!
      end
    end

    context 'polymorphic' do

      context 'when the as option is provided' do


        let(:options) do
          {
              as: :containable
          }
        end

        before do
          association
        end

        it 'set the polymorphic attribute on the owner class' do
          expect(has_one_class.polymorphic).to be(true)
        end
      end

      context 'when the as option is not provided' do

        it 'does not set the polymorphic attribute on the owner class' do
          expect(has_one_class.polymorphic).to be(false)
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
            described_class.new(has_one_class, name, options)
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
            described_class.new(has_one_class, name, options)
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
            described_class.new(has_one_class, name, options)
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
            described_class.new(has_one_class, name, options)
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
            described_class.new(has_one_class, name, options)
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
  end

  describe '#type' do

    context 'when polymorphic' do

      let(:options) do
        { as: :containable }
      end

      it 'returns the as attribute followed by "_type"' do
        expect(association.type).to eq("#{options[:as]}_type")
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
        { as: :containable }
      end

      it 'returns nil' do
        expect(association.inverse_type).to be_nil
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
        { as: :containable }
      end

      it 'returns nil' do
        expect(association.inverse_type).to be_nil
      end
    end

    context 'when not polymorphic' do

      it 'returns nil' do
        expect(association.inverse_type).to be_nil
      end
    end
  end

  describe '#foreign_key' do

    context 'when options has foreign_key specified' do

      let(:options) do
        { foreign_key: :other_object_id }
      end

      it 'raises returns the foreign key as a String' do
        expect(association.foreign_key).to eq(options[:foreign_key].to_s)
      end
    end

    context 'when options does not have foreign_key specified' do

      it 'returns the default foreign key, the name of the inverse followed by "_id"' do
        expect(association.foreign_key).to eq("#{association.inverse}_id")
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

      let(:options) do
        {
            primary_key: 'guid'
        }
      end

      it 'returns the primary_key' do
        expect(association.primary_key).to eq(options[:primary_key])
      end
    end

    context 'when the :primary_key option is not specified' do

      it 'returns the primary_key default' do
        expect(association.primary_key).to eq(Mongoid::Association::Relatable::PRIMARY_KEY_DEFAULT)
      end
    end
  end

  describe '#indexed?' do

    it 'returns false' do
      expect(association.indexed?).to be(false)
    end
  end

  describe '#relation' do

    it 'returns Mongoid::Association::Referenced::HasOne::Proxy' do
      expect(association.relation).to be(Mongoid::Association::Referenced::HasOne::Proxy)
    end
  end

  describe '#validation_default' do

    it 'returns true' do
      expect(association.validation_default).to be(true)
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

  describe '#merge!' do

  end

  describe '#store_as' do
    it 'returns nil' do
      expect(association.store_as).to be_nil
    end
  end

  describe '#touchable?' do

    it 'return false' do
      expect(association.send(:touchable?)).to be(false)
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

    context 'when :as is specified in the options' do

      let(:options) do
        {
            as: :containable
        }
      end

      it 'returns the :as option' do
        expect(association.as).to eq(options[:as])
      end
    end

    context 'when :as is not specified in the options' do

      it 'returns nil' do
        expect(association.as).to be_nil
      end
    end
  end

  describe '#polymorphic?' do

    context 'when :as is specified in the options' do

      let(:options) do
        {
            as: :containable
        }
      end

      it 'returns true' do
        expect(association.polymorphic?).to be(true)
      end

    end

    context 'when :as is not specified in the options' do

      it 'returns false' do
        expect(association.polymorphic?).to be(false)
      end
    end
  end

  describe '#type_setter' do

    context 'when polymorphic' do

      let(:options) do
        { as: :containable }
      end

      it 'returns the type followed by = as a String' do
        expect(association.type_setter).to eq("containable_type=")
      end
    end

    context 'when not polymorphic' do

      it 'returns nil' do
        expect(association.type).to be_nil
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

  describe '#inverse_type' do

    it 'returns nil' do
      expect(association.inverse_type).to be_nil
    end
  end

  describe '#bindable?' do

    it 'returns false' do
      expect(association.bindable?(Person.new)).to be(false)
    end
  end

  describe '#inverses' do

    context 'when polymorphic' do

      before do
        BelongingObject.belongs_to :containable, polymorphic: true
      end

      let(:options) do
        {
            as: :containable
        }
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          BelongingObject.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          it 'returns the :as attribute of this association' do
            expect(association.inverses(instance_of_other_class)).to match_array([ :containable ])
          end
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

          it 'returns the :as attribute of this association' do
            expect(association.inverses(instance_of_other_class)).to match_array([ :containable ])
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

          it 'returns the :as attribute' do
            expect(association.inverses).to eq([ :containable ])
          end
        end
      end
    end

    context 'when not polymorphic' do

      before do
        BelongingObject.belongs_to :owner_object
      end

      context 'when inverse_of is specified' do

        before do
          options.merge!(inverse_of: :inverse_name)
        end

        it 'returns the :inverse_of value' do
          expect(association.inverses).to eq([ :inverse_name ])
        end
      end

      context 'when inverse_of is not specified' do

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverses).to eq([ :owner_object ])
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end
    end
  end

  describe '#inverse' do

    context 'when polymorphic' do

      before do
        BelongingObject.belongs_to :containable, polymorphic: true
      end

      let(:options) do
        {
            as: :containable
        }
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          BelongingObject.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          it 'returns the :as attribute of this association' do
            expect(association.inverse(instance_of_other_class)).to eq(:containable)
          end
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

          it 'returns the :as attribute of this association' do
            expect(association.inverse(instance_of_other_class)).to eq(:containable)
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

          it 'returns the :as attribute' do
            expect(association.inverse).to eq(:containable)
          end
        end
      end
    end

    context 'when not polymorphic' do

      before do
        BelongingObject.belongs_to :owner_object
      end

      context 'when inverse_of is specified' do

        before do
          options.merge!(inverse_of: :inverse_name)
        end

        it 'returns the :inverse_of value' do
          expect(association.inverse).to eq(:inverse_name)
        end
      end

      context 'when inverse_of is not specified' do

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverse).to eq(:owner_object)
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end
    end
  end

  describe '#inverse_association' do

  end

  describe '#autosave' do

    context 'when the autosave option is specified' do

      context 'when the autosave option is true' do

        let(:options) do
          {
            autosave: true
          }
        end

        it 'returns true' do
          expect(association.autosave).to be(true)
        end
      end

      context 'when the autosave option is false' do

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

    context 'when the autosave option is not specified' do

      it 'returns false' do
        expect(association.autosave).to be(false)
      end
    end
  end

  describe '#relation_class_name' do

    context 'when the classes are defined in a module' do

      let(:define_classes) do
        module HasOneAssociationClassName
          class OwnedClass
            include Mongoid::Document

            belongs_to :owner_class
          end

          class OwnerClass
            include Mongoid::Document

            has_one :owned_class
          end
        end
      end

      it 'returns the inferred unqualified class name' do
        define_classes

        expect(
            HasOneAssociationClassName::OwnedClass.relations['owner_class'].relation_class_name
        ).to eq('OwnerClass')
      end
    end

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherBelongingObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('OtherBelongingObject')
      end

      context 'when the class is namespaced' do
        let(:association) do
          HomNs::PrefixedParent.relations['child']
        end

        it 'returns unqualified class name as given in the :class_name option' do
          expect(association.relation_class_name).to eq('PrefixedChild')
        end
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class_name).to eq('BelongingObject')
      end
    end

    context "when the class is not defined" do
      let(:name) do
        :undefined_class
      end

      it 'does not trigger autoloading' do
        expect(association.relation_class_name).to eq('UndefinedClass')
      end
    end
  end

  describe '#relation_class' do

    context 'when the :class_name option is specified' do

      let!(:_class) do
        class OtherBelongingObject; end
        OtherBelongingObject
      end

      let(:options) do
        { class_name: 'OtherBelongingObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class).to eq(_class)
      end

      context 'when the class is namespaced' do
        let(:association) do
          HomNs::PrefixedParent.relations['child']
        end

        it 'returns resolved class instance' do
          expect(association.relation_class).to eq(HomNs::PrefixedChild)
        end
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class).to eq(BelongingObject)
      end
    end
  end

  describe '#klass' do
    it 'is the target class' do
      expect(association.klass).to eq(BelongingObject)
    end
  end

  describe '#inverse_class_name' do

    it 'returns the name of the owner class' do
      expect(association.inverse_class_name).to eq('OwnerObject')
    end

    context 'polymorphic association' do
      let(:association) do
        has_one_class.has_one :belonging_object, as: :bar
      end

      it 'returns the name of the owner class' do
        expect(association.inverse_class_name).to eq(OwnerObject.name)
      end
    end
  end

  describe '#inverse_class' do

    it 'returns the owner class' do
      expect(association.inverse_class).to be(OwnerObject)
    end

    context 'polymorphic association' do
      let(:association) do
        has_one_class.has_one :belonging_object, as: :bar
      end

      it 'returns the owner class' do
        expect(association.inverse_class).to be(OwnerObject)
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

    it 'returns the primary key' do
      expect(association.key).to eq(association.primary_key)
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

    it 'returns false' do
      expect(association.stores_foreign_key?).to be(false)
    end
  end

  describe '#inverse_setter' do

    context 'when an inverse can be determined' do

      before do
        BelongingObject.belongs_to :owner_object
      end

      it 'returns the name of the inverse followed by =' do
        expect(association.inverse_setter).to eq('owner_object=')
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
        has_one_class.embeds_one name, options do; end
      end

      it 'defines an extension module' do
        expect(association.extension).to be_a(Module)
      end

      it 'returns the extension' do
        expect(association.extension).to eq(
          "#{has_one_class.name}::#{has_one_class.name}#{name.to_s.camelize}RelationExtension".constantize)
      end
    end

    context 'when an :extension is not specified in the options' do

      it 'returns false' do
        expect(association.extension).to be_nil
      end
    end
  end

  describe '#foreign_key_setter' do

    it 'returns the foreign key followed by "="' do
      expect(association.foreign_key_setter).to eq("#{association.foreign_key}=")
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

  context 'when the classes are defined in a module' do

    let(:define_classes) do
      module HasOneAssociationModuleDefinitions
        class OwnedClass
          include Mongoid::Document

          belongs_to :owner_class
        end

        class OwnerClass
          include Mongoid::Document

          has_one :owned_class
        end
      end
    end

    let(:owner) do
      HasOneAssociationModuleDefinitions::OwnerClass.create!
    end

    let(:owned) do
      define_classes
      HasOneAssociationModuleDefinitions::OwnedClass.create!(owner_class: owner)
    end

    it 'successfully creates the owned document' do
      expect { owned }.not_to raise_error
    end
  end

  describe '#nested_builder' do

    it 'returns an instance of Association::Nested::One' do
      expect(association.nested_builder({}, {})).to be_a(Mongoid::Association::Nested::One)
    end
  end

  describe '#path' do

    it 'returns an instance of Mongoid::Atomic::Paths::Root' do
      expect(association.path(double( :_parent => true))).to be_a(Mongoid::Atomic::Paths::Root)
    end
  end

  describe '#foreign_key_check' do

    it 'returns the nil' do
      expect(association.foreign_key_check).to be_nil
    end
  end

  describe '#create_relation' do

    let(:owner) do
      OwnerObject.new
    end

    let(:target) do
      BelongingObject.new
    end

    before do
      association
      BelongingObject.belongs_to :owner_object
    end

    it 'returns an the target (EmbeddedObject)' do
      expect(Mongoid::Association::Referenced::HasOne::Proxy).to receive(:new).and_call_original
      expect(association.create_relation(owner, target)).to be_a(BelongingObject)
    end
  end
end
