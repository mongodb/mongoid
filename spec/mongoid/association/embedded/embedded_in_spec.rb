# frozen_string_literal: true

require "spec_helper"
require_relative './embeds_one_models'

describe Mongoid::Association::Embedded::EmbeddedIn do

  before do
    class Container; include Mongoid::Document; end
    class EmbeddedObject; include Mongoid::Document; end
  end

  after do
    Object.send(:remove_const, :Container)
    Object.send(:remove_const, :EmbeddedObject)
  end

  let(:embedded_class) do
    EmbeddedObject
  end

  let(:name) do
    :container
  end

  let(:association) do
    embedded_class.embedded_in name, options
  end

  let(:options) do
    { }
  end

  describe '#VALID_OPTIONS' do

    it 'returns the SHARED options with the ASSOCIATION_OPTIONS' do
      expect(association.class::VALID_OPTIONS).to match_array(Mongoid::Association::Relatable::SHARED_OPTIONS +
                                                              association.class::ASSOCIATION_OPTIONS)
    end
  end

  describe '#relation_complements' do

    let(:expected_complements) do
      [
        Mongoid::Association::Embedded::EmbedsMany,
        Mongoid::Association::Embedded::EmbedsOne
      ]
    end

    it 'returns the relation complements' do
      expect(association.send(:relation_complements)).to eq(expected_complements)
    end
  end

  describe '#setup_instance_methods!' do

    it 'sets up a getter for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_getter!).with(association)
      association.send(:setup_instance_methods!)
    end

    it 'sets up a setter for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_setter!).with(association)
      association.send(:setup_instance_methods!)
    end

    it 'sets up an existence check for the relation' do
      expect(Mongoid::Association::Accessors).to receive(:define_existence_check!).with(association)
      association.send(:setup_instance_methods!)
    end
  end

  describe '#inverse_type_setter' do

    context 'when polymorphic' do

      let(:options) do
        { polymorphic: true }
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

  describe '#embedded?' do

    it 'returns true' do
      expect(association.embedded?).to be(true)
    end
  end

  describe '#relation' do

    it 'returns Mongoid::Association::Embedded::EmbeddedIn::Proxy' do
      expect(association.relation).to be(Mongoid::Association::Embedded::EmbeddedIn::Proxy)
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

    context 'when :cyclic is specified in the options' do

      let(:options) do
        { cyclic: true }
      end

      it 'returns true' do
        expect(association.cyclic?).to be(true)
      end
    end

    context 'when :cyclic is not specified in the options' do

      it 'returns false' do
        expect(association.cyclic?).to be(false)
      end
    end
  end

  describe '#merge!' do

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
          Container.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          before do
            Container.embeds_many :embedded_objects, as: :containable
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
              expect(association.inverses(instance_of_other_class)).to match_array([ :embedded_objects ])
            end

            context 'when the relation class has two associations with the same name' do

              before do
                Container.embeds_many :embedded_objects, as: :containable
                Container.embeds_many :other_embedded_objects, as: :containable
              end

              it 'returns only the relations whose :as attribute and class match' do
                expect(association.inverses(instance_of_other_class)).to match_array([ :embedded_objects ])
              end
            end
          end
        end

        context 'when the relation class has more than one relation whose class matches the owning class' do

          before do
            Container.embeds_many :embedded_objects, as: :containable
            Container.embeds_one :other_embedded_object, as: :containable, class_name: 'EmbeddedObject'
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
              expect(association.inverses(instance_of_other_class)).to match_array([ :embedded_objects,
                                                                                     :other_embedded_object ])
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

          context 'when class_name is given and is a plain string' do
            let(:association) do
              EomParent.relations['child']
            end

            it 'returns the inverse in an array' do
              inverses = association.inverses
              expect(inverses).to eq([:parent])
            end
          end

          context 'when class_name is given and is a :: prefixed string' do
            let(:association) do
              EomCcChild.relations['parent']
            end

            it 'returns the inverse in an array' do
              pending 'MONGOID-4751'

              inverses = association.inverses
              expect(inverses).to eq([:child])
            end

            context 'when other associations referencing unloaded classes exist' do
              let(:association) do
                EomDnlChild.relations['parent']
              end

              it 'does not load other classes' do
                inverses = association.inverses
                expect(inverses).to eq([:child])
                expect(Object.const_defined?(:EoDnlMarker)).to be false
              end
            end
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
          Container.embeds_many :embedded_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverses).to eq([ :embedded_objects ])
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end

      context 'when the inverse class has more than one relation with objects of the owner class' do

        before do
          Container.embeds_many :embedded_objects
          Container.embeds_many :other_embedded_objects, class_name: 'EmbeddedObject'
        end

        it 'raises a Mongoid::Errors::AmbiguousRelationship exception' do
          expect {
            association.inverses
          }.to raise_exception(Mongoid::Errors::AmbiguousRelationship)
        end
      end

      context 'when the inverse class only has one relation with objects of the owner class' do

        before do
          Container.embeds_many :embedded_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverses).to eq([ :embedded_objects ])
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
          Container.new
        end

        context 'when the relation class has only one relation whose class matches the owning class' do

          before do
            Container.embeds_many :embedded_objects, as: :containable
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
              expect(association.inverse(instance_of_other_class)).to eq(:embedded_objects)
            end
          end
        end

        context 'when the relation class has more than one relation whose class matches the owning class' do

          before do
            Container.embeds_many :embedded_objects, as: :containable
            Container.embeds_one :other_embedded_object, as: :containable
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
              expect(association.inverse(instance_of_other_class)).to eq(:embedded_objects)
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
          Container.embeds_many :embedded_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverse).to eq(:embedded_objects)
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end

      context 'when the inverse class has more than one relation with objects of the owner class' do

        before do
          Container.embeds_many :embedded_objects
          Container.embeds_many :other_embedded_objects, class_name: 'EmbeddedObject'
        end

        it 'raises a Mongoid::Errors::AmbiguousRelationship exception' do
          expect {
            association.inverse
          }.to raise_exception(Mongoid::Errors::AmbiguousRelationship)
        end
      end

      context 'when the inverse class only has one relation with objects of the owner class' do

        before do
          Container.embeds_many :embedded_objects
        end

        it 'uses the inverse class to find the inverse name' do
          expect(association.inverse).to eq(:embedded_objects)
        end
      end
    end
  end

  describe '#inverse_association' do

  end

  describe '#autosave' do

    it 'returns false' do
      expect(association.autosave).to be(false)
    end
  end

  describe '#relation_class_name' do

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherContainer' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('OtherContainer')
      end

      context ':class_name is a :: prefixed string' do
        let(:association) do
          EomCcChild.relations['parent']
        end

        it 'returns the :: prefixed string' do
          expect(association.relation_class_name).to eq('::EomCcParent')
        end
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class_name).to eq('Container')
      end
    end

    context 'when another association in the model is referencing a third model class' do
      let(:association) do
        EomDnlChild.relations['parent']
      end

      it 'does not attempt to load the third class' do
        expect(association.relation_class_name).to eq('EomDnlParent')
        expect(Object.const_defined?(:EoDnlMarker)).to be false
      end
    end
  end

  describe '#klass' do

    context 'when the :class_name option is specified' do

      let!(:_class) do
        class OtherContainer; end
        OtherContainer
      end

      let(:options) do
        { class_name: 'OtherContainer' }
      end

      it 'returns the class name option' do
        expect(association.klass).to eq(_class)
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.klass).to eq(Container)
      end
    end
  end

  describe '#inverse_class_name' do

    it 'returns the name of the owner class' do
      expect(association.inverse_class_name).to eq(embedded_class.name)
    end
  end

  describe '#inverse_class' do

    it 'returns the owner class' do
      expect(association.inverse_class).to be(embedded_class)
    end
  end

  describe '#inverse_of' do

    context 'when :inverse_of is specified in the options' do

      let(:options) do
        { inverse_of: :a_container }
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

    it 'returns the name of the relation as a string' do
      expect(association.key).to eq(name.to_s)
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
        Container.embeds_many :embedded_objects
      end

      it 'returns the name of the inverse followed by =' do
        expect(association.inverse_setter).to eq('embedded_objects=')
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
        embedded_class.embedded_in name, options do; end
      end

      it 'defines an extension module' do
        expect(association.extension).to be_a(Module)
      end

      it 'returns the extension' do
        expect(association.extension).to eq(
          "#{embedded_class.name}::#{embedded_class.name}#{name.capitalize}RelationExtension".constantize)
      end
    end

    context 'when an :extension is not specified in the options' do

      it 'returns false' do
        expect(association.extension).to be_nil
      end
    end
  end

  describe '#criteria' do

    it 'does not respond to the method' do
      expect {
        association.criteria
      }.to raise_exception(NoMethodError)
    end
  end

  describe '#destructive?' do

    it 'returns false' do
      expect(association.destructive?).to be(false)
    end
  end

  describe '#nested_builder' do

    it 'returns an instance of Association::Nested::One' do
      expect(association.nested_builder({}, {})).to be_a(Mongoid::Association::Nested::One)
    end
  end

  describe '#cascading_callbacks?' do

    context 'when cascade_callbacks is specified in the options' do

      let(:options) do
        {cascade_callbacks: true}
      end

      it 'raises a Mongoid::Errors::InvalidRelationOption exception' do
        expect {
          association.cascading_callbacks?
        }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
      end
    end

    context 'when cascade_callbacks is not specified in the options' do

      it 'returns false' do
        expect(association.cascading_callbacks?).to be(false)
      end
    end
  end

  describe '#path' do

    it 'returns an instance of Mongoid::Atomic::Paths::Root' do
      expect(association.path({})).to be_a(Mongoid::Atomic::Paths::Root)
    end
  end

  describe '#foreign_key_check' do

    it 'returns nil' do
      expect(association.foreign_key_check).to be_nil
    end
  end

  describe '#create_relation' do

    let(:owner) do
      Container.new
    end

    let(:target) do
      EmbeddedObject.new
    end

    it 'returns an instance of Mongoid::Association::Embedded::EmbeddedIn::Proxy' do
      expect(Mongoid::Association::Embedded::EmbeddedIn::Proxy).to receive(:new).and_call_original
      expect(association.create_relation(owner, target)).to be_a(EmbeddedObject)
    end
  end
end
