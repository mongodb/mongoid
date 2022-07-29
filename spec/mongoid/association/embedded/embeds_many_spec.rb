# frozen_string_literal: true

require "spec_helper"
require_relative 'embeds_many_models'

describe Mongoid::Association::Embedded::EmbedsMany do

  before do
    class Container; include Mongoid::Document; end
    class EmbeddedObject; include Mongoid::Document; end
  end

  after do
    Container.relations.clear
    EmbeddedObject.relations.clear
  end

  let(:embeds_many_class) do
    Container
  end

  let(:name) do
    :embedded_objects
  end

  let(:association) do
    embeds_many_class.embeds_many name, options
  end

  let(:options) do
    { }
  end

  describe '#relation_complements' do

    let(:expected_complements) do
      [
        Mongoid::Association::Embedded::EmbeddedIn,
      ]
    end

    it 'returns the relation complements' do
      expect(association.send(:relation_complements)).to eq(expected_complements)
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

    context 'when the :validate option is true' do

      let(:options) do
        {
          validate: true
        }
      end

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :embeds_many macro
        described_class.new(embeds_many_class, name, options)
      end

      it 'sets up validation' do
        expect(embeds_many_class).to receive(:validates_associated).with(name).and_call_original
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
        expect(embeds_many_class).not_to receive(:validates_associated)
        association.setup!
      end
    end

    context 'when the :validate option is not provided' do

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :embeds_many macro
        described_class.new(embeds_many_class, name, options)
      end

      it 'sets up the validation because it uses the validation default (true)' do
        expect(embeds_many_class).to receive(:validates_associated).with(name).and_call_original
        association.setup!
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

  describe '#embedded?' do

    it 'returns true' do
      expect(association.embedded?).to be(true)
    end
  end

  describe '#primary_key' do

    it 'returns nil' do
      expect(association.primary_key).to be_nil
    end
  end

  describe '#indexed?' do

    it 'returns false' do
      expect(association.indexed?).to be(false)
    end
  end

  describe '#relation' do

    it 'returns Mongoid::Association::Embedded::EmbedsMany::Proxy' do
      expect(association.relation).to be(Mongoid::Association::Embedded::EmbedsMany::Proxy)
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

  describe '#store_as' do

    context 'when :store_as is specified in the options' do

      let(:options) do
        {
          store_as: :baby_kangaroos
        }
      end

      it 'returns the :store_as option as a String' do
        expect(association.store_as).to eq(options[:store_as].to_s)
      end
    end

    context 'when :store_as is not specified in the options' do

      it 'returns name as a String' do
        expect(association.store_as).to eq(name.to_s)
      end
    end
  end

  describe '#touchable?' do

    it 'return false' do
      expect(association.send(:touchable?)).to be(false)
    end
  end

  describe '#order' do

    context 'when order is specified in the options' do

      let(:options) do
        {
          order: :rating.desc
        }
      end

      it 'returns a Criteria Queryable Key' do
        expect(association.order).to be_a(Mongoid::Criteria::Queryable::Key)
      end
    end

    context 'when order is not specified in the options' do

      it 'returns nil' do
        expect(association.order).to be_nil
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

    it 'returns nil' do
      expect(association.dependent).to be_nil
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
        EmbeddedObject.embedded_in :containable, polymorphic: true
      end

      let(:options) do
        {
          as: :containable
        }
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          EmbeddedObject.new
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
        EmbeddedObject.embedded_in :container
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
          expect(association.inverses).to eq([ :container ])
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

        end
      end
    end
  end

  describe '##inverse' do

    context 'when polymorphic' do

      before do
        EmbeddedObject.embedded_in :containable, polymorphic: true
      end

      let(:options) do
        {
          as: :containable
        }
      end

      context 'when another object is passed to the method' do

        let(:instance_of_other_class) do
          EmbeddedObject.new
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
        EmbeddedObject.embedded_in :container
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
          expect(association.inverse).to eq(:container)
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

    it 'returns false' do
      expect(association.autosave).to be(false)
    end
  end

  describe '#relation_class_name' do

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherEmbeddedObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('OtherEmbeddedObject')
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class_name).to eq('EmbeddedObject')
      end
    end
  end

  describe '#klass' do

    context 'when the :class_name option is specified' do

      let!(:_class) do
        class OtherEmbeddedObject; end
        OtherEmbeddedObject
      end

      let(:options) do
        { class_name: 'OtherEmbeddedObject' }
      end

      it 'returns the class name option' do
        expect(association.klass).to eq(_class)
      end

      context 'when the class name is prefixed with ::' do
        let(:options) do
          { class_name: '::OtherEmbeddedObject' }
        end

        it 'returns the class name option' do
          expect(association.klass).to eq(_class)
        end
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.klass).to eq(EmbeddedObject)
      end
    end
  end

  describe '#inverse_class_name' do

    it 'returns the name of the owner class' do
      expect(association.inverse_class_name).to eq(Container.name)
    end
  end

  describe '#inverse_class' do

    it 'returns the owner class' do
      expect(association.inverse_class).to be(Container)
    end
  end

  describe '#inverse_of' do

    context 'when :inverse_of is specified in the options' do

      let(:options) do
        { inverse_of: :objects_list }
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

  describe '#forced_nil_inverse?' do

    it 'returns false' do
      expect(association.forced_nil_inverse?).to be(false)
    end
  end

  describe '#inverse_setter' do

    context 'when an inverse can be determined' do

      before do
        EmbeddedObject.embedded_in :container
      end

      it 'returns the name of the inverse followed by =' do
        expect(association.inverse_setter).to eq('container=')
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
        embeds_many_class.embeds_one name, options do; end
      end

      it 'defines an extension module' do
        expect(association.extension).to be_a(Module)
      end

      it 'returns the extension' do
        expect(association.extension).to eq(
          "#{embeds_many_class.name}::#{embeds_many_class.name}#{name.to_s.camelize}RelationExtension".constantize)
      end
    end

    context 'when an :extension is not specified in the options' do

      it 'returns false' do
        expect(association.extension).to be_nil
      end
    end
  end

  describe '#destructive?' do

    it 'returns false' do
      expect(association.destructive?).to be(false)
    end
  end

  describe '#nested_builder' do

    it 'returns an instance of Association::Nested::One' do
      expect(association.nested_builder({}, {})).to be_a(Mongoid::Association::Nested::Many)
    end
  end

  describe '#cascading_callbacks?' do

    context 'when cascade_callbacks is specified in the options' do

      context 'when :cascade_callbacks is true' do

        let(:options) do
          { cascade_callbacks: true }
        end

        it 'returns true' do
          expect(association.cascading_callbacks?).to be(true)
        end
      end

      context 'when :cascade_callbacks is false' do

        let(:options) do
          { cascade_callbacks: false }
        end

        it 'returns false' do
          expect(association.cascading_callbacks?).to be(false)
        end
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
      expect(association.path(double( :_parent => true))).to be_a(Mongoid::Atomic::Paths::Embedded::Many)
    end
  end

  context "when the document and embedded document's klass is in a submodule" do

    let(:tank) { EmmSpec::Tank.create! }
    let(:gun) { tank.guns.create! }

    let(:inverse_assoc) { gun._association.inverse_association }

    it "has the correct inverses" do
      pending 'MONGOID-5080'

      inverse_assoc.should be_a(Mongoid::Association::Embedded::EmbeddedIn)
      inverse_assoc.name.should == :tank
    end

    context "when embedded association is not namespaced but has class_name" do

      let(:turret) { tank.emm_turrets.create! }

      let(:inverse_assoc) { turret._association.inverse_association }

      it "has the correct inverses" do
        inverse_assoc.should be_a(Mongoid::Association::Embedded::EmbeddedIn)
        inverse_assoc.name.should == :tank
      end
    end

    context "when embedded association is not namespaced and lacks class_name" do

      let(:hatch) { tank.emm_hatches.create! }

      let(:inverse_assoc) { hatch._association.inverse_association }

      it "does not find the inverse" do
        inverse_assoc.should be nil
      end
    end

    context "when the class names exist on top level and namespaced" do

      let(:car) { EmmSpec::Car.create! }
      let(:door) { car.doors.create! }

      let(:inverse_assoc) { door._association.inverse_association }

      it "has the correct inverses" do
        pending 'MONGOID-5080'

        inverse_assoc.should be_a(Mongoid::Association::Embedded::EmbeddedIn)
        inverse_assoc.name.should == :car
      end
    end

    context "when the association has an unqualified class_name in same module" do

      let(:launcher) { tank.launchers.create! }

      let(:inverse_assoc) { launcher._association.inverse_association }

      it "has the correct inverses" do
        pending 'unqualified class_name arguments do not work per MONGOID-5080'

        inverse_assoc.should be_a(Mongoid::Association::Embedded::EmbeddedIn)
        inverse_assoc.name.should == :tank
      end
    end
  end
end
