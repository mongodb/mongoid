# frozen_string_literal: true

require "spec_helper"
require_relative "./has_and_belongs_to_many_models"

describe Mongoid::Association::Referenced::HasAndBelongsToMany do

  before do
    class HasManyLeftObject; include Mongoid::Document; end
    class HasManyRightObject; include Mongoid::Document; end
  end

  after do
    Object.send(:remove_const, :HasManyLeftObject)
    Object.send(:remove_const, :HasManyRightObject)
  end

  let(:has_many_left_class) do
    HasManyLeftObject
  end

  let(:name) do
    :has_many_right_objects
  end

  let(:association) do
    has_many_left_class.has_and_belongs_to_many name, options
  end

  let(:options) do
    { }
  end

  describe '#relation_complements' do

    let(:expected_complements) do
      [
          Mongoid::Association::Referenced::HasAndBelongsToMany,
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

    context 'autosave' do

      context 'when the :autosave option is true' do

        let(:options) do
          {
              autosave: true
          }
        end

        let(:association) do
          # Note that it is necessary to create the association directly, otherwise the
          # setup! method will be called by the :has_many macro
          described_class.new(has_many_left_class, name, options)
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
          # setup! method will be called by the :has_many macro
          described_class.new(has_many_left_class, name, options)
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
        # setup! method will be called by the :has_and_belongs_to_many macro
        described_class.new(has_many_left_class, name, options)
      end

      it 'sets up validation' do
        expect(has_many_left_class).to receive(:validates_associated).with(name).and_call_original
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
        expect(has_many_left_class).not_to receive(:validates_associated)
        association.setup!
      end
    end

    context 'when the :validate option is not provided' do

      let(:association) do
        # Note that it is necessary to create the association directly, otherwise the
        # setup! method will be called by the :has_many macro
        described_class.new(has_many_left_class, name, options)
      end

      it 'sets up the validation because it uses the validation default (true)' do
        expect(has_many_left_class).to receive(:validates_associated).with(name).and_call_original
        association.setup!
      end
    end

    context 'foreign key field' do

      before do
        association
      end

      it 'sets up the foreign key field' do
        expect(has_many_left_class.fields.keys).to include(association.foreign_key)
      end
    end

    context 'index' do

      before do
        association
      end

      context 'when index is true' do

        let(:options) do
          {
            index: true
          }
        end

        it 'sets up the index with the key' do
          expect(has_many_left_class.index_specifications.first.fields).to match_array([association.key.to_sym])
        end
      end

      context 'when index is false' do


        it 'does not set up an index' do
          expect(has_many_left_class.index_specifications).to eq([])
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
            described_class.new(has_many_left_class, name, options)
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
            described_class.new(has_many_left_class, name, options)
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
            described_class.new(has_many_left_class, name, options)
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
            described_class.new(has_many_left_class, name, options)
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
            described_class.new(has_many_left_class, name, options)
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

    it 'returns nil' do
      expect(association.type).to be_nil
    end
  end

  describe '#inverse_type' do

    it 'returns nil' do
      expect(association.inverse_type).to be_nil
    end
  end

  describe '#inverse_type_setter' do

    it 'returns nil' do
      expect(association.inverse_type_setter).to be_nil
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

      it 'returns the default foreign key, the name of the inverse followed by "_ids"' do
        expect(association.foreign_key).to eq("#{name.to_s.singularize}_ids")
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

    it 'returns Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy' do
      expect(association.relation).to be(Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy)
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

    it 'returns false' do
      expect(association.polymorphic?).to be(false)
    end
  end

  describe '#type_setter' do

    it 'returns nil' do
      expect(association.type).to be_nil
    end
  end

  describe '#dependent' do

    it 'returns nil' do
      expect(association.dependent).to be_nil
    end
  end

  describe '#bindable?' do

    it 'returns false' do
      expect(association.bindable?(Person.new)).to be(false)
    end
  end

  describe '#inverses' do

    before do
      HasManyRightObject.has_and_belongs_to_many :has_many_left_objects
    end

    context 'when inverse_of is specified' do

      before do
        options.merge!(inverse_of: :inverse_name)
      end

      it 'returns the :inverse_of value' do
        expect(association.inverses).to eq([:inverse_name])
      end
    end

    context 'when inverse_of is not specified' do

      it 'uses the inverse class to find the inverse name' do
        expect(association.inverses).to eq([:has_many_left_objects])
      end
    end

    context 'when :cyclic is specified' do

      it 'returns the cyclic inverse name' do

      end
    end
  end

  describe '##inverse' do

      before do
        HasManyRightObject.has_and_belongs_to_many :has_many_left_objects
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
          expect(association.inverse).to eq(:has_many_left_objects)
        end
      end

      context 'when :cyclic is specified' do

        it 'returns the cyclic inverse name' do

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

    context 'when the :class_name option is specified' do

      let(:options) do
        { class_name: 'OtherHasManyRightObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class_name).to eq('OtherHasManyRightObject')
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class_name).to eq('HasManyRightObject')
      end
    end
  end

  describe '#relation_class' do

    context 'when the :class_name option is specified' do

      let!(:_class) do
        class OtherHasManyRightObject; end
        OtherHasManyRightObject
      end

      let(:options) do
        { class_name: 'OtherHasManyRightObject' }
      end

      it 'returns the class name option' do
        expect(association.relation_class).to eq(_class)
      end
    end

    context 'when the class_name option is not specified' do

      it 'uses the name of the relation to deduce the class name' do
        expect(association.relation_class).to eq(HasManyRightObject)
      end
    end
  end

  describe '#inverse_class_name' do

    it 'returns the name of the owner class' do
      expect(association.inverse_class_name).to eq(HasManyLeftObject.name)
    end
  end

  describe '#inverse_class' do

    it 'returns the owner class' do
      expect(association.inverse_class).to be(HasManyLeftObject)
    end
  end

  describe '#inverse_of' do

    context 'when :inverse_of is specified in the options' do

      let(:options) do
        { inverse_of: :a_has_many_left_object }
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

  # describe '#key' do
  #
  #   it 'returns the primary key' do
  #     expect(association.key).to eq(association.primary_key)
  #   end
  # end

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

    context 'when inverse_of is specified in the options' do

      context 'when :inverse_of is nil' do

        let(:options) do
          {
              inverse_of: nil
          }
        end

        it 'returns true' do
          expect(association.forced_nil_inverse?).to be(true)
        end
      end

      context 'when :inverse_of is a symbol' do

        let(:options) do
          {
              inverse_of: :inverse_name
          }
        end

        it 'returns false' do
          expect(association.forced_nil_inverse?).to be(false)
        end
      end

      context 'when :inverse_of is false' do

        let(:options) do
          {
              inverse_of: false
          }
        end

        it 'returns true' do
          expect(association.forced_nil_inverse?).to be(true)
        end
      end
    end

    context 'when :inverse_of is not specified in the options' do

      it 'returns false' do
        expect(association.forced_nil_inverse?).to be(false)
      end
    end
  end

  describe '#stores_foreign_key?' do

    it 'returns false' do
      expect(association.stores_foreign_key?).to be(true)
    end
  end

  describe '#inverse_setter' do

    context 'when an inverse can be determined' do

      before do
        HasManyRightObject.has_and_belongs_to_many :has_many_left_objects
      end

      it 'returns the name of the inverse followed by =' do
        expect(association.inverse_setter).to eq('has_many_left_objects=')
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
        has_many_left_class.has_and_belongs_to_many name, options do; end
      end

      it 'defines an extension module' do
        expect(association.extension).to be_a(Module)
      end

      it 'returns the extension' do
        expect(association.extension).to eq(
          "#{has_many_left_class.name}::#{has_many_left_class.name}#{name.to_s.camelize}RelationExtension".constantize)
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

  describe '#criteria' do

    it 'returns a criteria object' do
      expect(association.criteria(BSON::ObjectId.new, HasManyLeftObject)).to be_a(Mongoid::Criteria)
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

    it 'returns an instance of Association::Nested::Many' do
      expect(association.nested_builder({}, {})).to be_a(Mongoid::Association::Nested::Many)
    end
  end

  describe '#cascading_callbacks?' do

    it 'returns false' do
      expect(association.cascading_callbacks?).to be(false)
    end
  end

  describe '#path' do

    it 'returns an instance of Mongoid::Atomic::Paths::Root' do
      expect(association.path(double)).to be_a(Mongoid::Atomic::Paths::Root)
    end
  end

  describe '#foreign_key_check' do

    it 'returns the foreign_key followed by "_previously_changed?"' do
      expect(association.foreign_key_check).to eq('has_many_right_object_ids_previously_changed?')
    end
  end

  describe '#create_relation' do

    let(:left_object) do
      HasManyLeftObject.new
    end

    let(:target) do
      [ HasManyRightObject.new ]
    end

    before do
      association
      HasManyRightObject.has_and_belongs_to_many :has_many_left_objects
    end

    it 'returns an the target' do
      expect(Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy).to receive(:new).and_call_original
      expect(association.create_relation(left_object, target)).to be_a(Array)
    end
  end

  describe '#inverse_foreign_key' do

    it 'returns generated key' do
      expect(association.inverse_foreign_key).to eq('has_many_left_object_ids')
    end

    context 'with inverse given' do
      let(:options) do
        { inverse_of: 'foo' }
      end

      it 'returns configured key' do
        expect(association.inverse_foreign_key).to eq('foo_ids')
      end
    end

    context 'with primary_key and foreign_key given' do
      let(:options) do
        { primary_key: 'foo', foreign_key: 'foo_ref',
          inverse_primary_key: 'bar', inverse_foreign_key: 'bar_ref' }
      end

      it 'returns configured key' do
        expect(association.inverse_foreign_key).to eq('bar_ref')
      end
    end

    context "when using a model that uses the class_name option" do
      let(:inverse_foreign_key) { HabtmmSchool.relations[:students].inverse_foreign_key }
      it "gets the correct inverse foreign key" do
        expect(inverse_foreign_key).to eq("school_ids")
      end
    end
  end

  describe '#inverse_foreign_key_setter' do

    it 'returns generated method name' do
      expect(association.inverse_foreign_key_setter).to eq('has_many_left_object_ids=')
    end
  end

  context "when adding an object to the association" do
    let!(:start_time) { Timecop.freeze(Time.at(Time.now.to_i)) }

    let(:update_time) do
      Timecop.freeze(Time.at(Time.now.to_i) + 2)
    end

    after do
      Timecop.return
    end

    let!(:school) { HabtmmSchool.create! }
    let!(:student) { HabtmmStudent.create! }

    before do
      update_time
      school.update(students: [student])
    end

    it "updates the updated at" do
      pending "MONGOID-4953"
      expect(school.updated_at).to eq(update_time)
    end
  end
end
