# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Macros do

  class TestClass
    include Mongoid::Document
  end

  let(:klass) do
    TestClass
  end

  before do
    klass.relations.clear
    klass._validators.clear
  end

  after do
    klass.relations.clear
    klass.validators.clear
  end

  describe 'Model loading' do

    let(:model_associations) do
      class TestModel
        include Mongoid::Document
        field :associations
      end
    end

    after do
      Object.send(:remove_const, :TestModel)
    end

    it 'prohibits the use of :associations as an attribute' do
      expect {
        model_associations
      }.to raise_exception(Mongoid::Errors::InvalidField)
    end
  end

  describe ".embedded_in" do

    it "defines the macro" do
      expect(klass).to respond_to(:embedded_in)
    end

    context 'when the relation name is invalid' do

      let(:relation) do
        klass.embedded_in(:fields)
      end

      it 'raises an InvalidRelation exception' do
        expect {
          relation
        }.to raise_exception(Mongoid::Errors::InvalidRelation)
      end
    end

    context "when defining the relation" do

      before do
        klass.embedded_in(:person)
      end

      it "adds the association to the klass" do
        expect(klass.relations["person"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:person)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:person=)
      end

      it "creates the correct relation" do
        expect(klass.relations["person"]).to be_a(
          Mongoid::Association::Embedded::EmbeddedIn
        )
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.embedded_in(:person, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      context "association properties" do

        let(:association) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:person)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".embeds_many" do

    it "defines the macro" do
      expect(klass).to respond_to(:embeds_many)
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.embeds_many(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      before do
        klass.embeds_many(:addresses)
      end

      it "adds the association to the klass" do
        expect(klass.relations["addresses"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:addresses)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:addresses=)
      end

      it "creates the correct relation" do
        expect(klass.relations["addresses"]).to be_a(
          Mongoid::Association::Embedded::EmbedsMany
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:addresses].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.embeds_many(:addresses, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      context "association properties" do

        let(:association) do
          klass.relations["addresses"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:addresses)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.embeds_many(:addresses, order: :number.asc)
      end

      let(:association) do
        klass.relations["addresses"]
      end

      it "adds association to klass" do
        expect(association.order).to_not be_nil
      end

      it "returns Mongoid::Criteria::Queryable::Key" do
        expect(association.order).to be_kind_of(Mongoid::Criteria::Queryable::Key)
      end
    end

    context "when setting validate to false" do

      before do
        klass.embeds_many(:addresses, validate: false)
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end
    end
  end

  describe ".embeds_one" do

    it "defines the macro" do
      expect(klass).to respond_to(:embeds_one)
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.embeds_one(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      before do
        klass.embeds_one(:name)
      end

      it "adds the association to the klass" do
        expect(klass.relations["name"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:name)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:name=)
      end

      it "defines the builder" do
        expect(klass.allocate).to respond_to(:build_name)
      end

      it "defines the creator" do
        expect(klass.allocate).to respond_to(:create_name)
      end

      it "creates the correct relation" do
        expect(klass.relations["name"]).to be_a(
          Mongoid::Association::Embedded::EmbedsOne
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:name].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.embeds_one(:name, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      context "association properties" do

        let(:association) do
          klass.relations["name"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:name)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end

    context "when setting validate to false" do

      before do
        klass.embeds_one(:name, validate: false)
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end
    end
  end

  describe ".belongs_to" do

    let(:_class) do
      class RelationsTestClass
        include Mongoid::Document
      end
    end

    let(:conf) do
      CONFIG.merge(options: { belongs_to_required_by_default: default_require })
    end

    let(:relation) do
      _class.new
    end

    let(:relation_options) { {} }

    let(:default_require) { Mongoid.belongs_to_required_by_default }

    before do
      Mongoid.configure do |config|
        config.load_configuration(conf)
      end
      _class.belongs_to(:person, relation_options)
    end

    after do
      Object.send(:remove_const, _class.name)
    end

    after(:all) do
      Mongoid.configure do |config|
        config.load_configuration(CONFIG)
      end
    end

    it "defines the macro" do
      expect(_class).to respond_to(:belongs_to)
    end

    context 'when the relation has options' do

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.belongs_to(:person, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      context 'when the relation has the option :required' do

        context 'when the relation does not have the :optional option' do

          context 'when :required is true' do

            let(:relation_options) do
              { required: true }
            end

            context 'when the default config is to require the association' do

              let(:default_require) { true }

              it 'requires the association' do
                expect(relation.save).to be(false)
              end
            end

            context 'when the default config is to not require the association' do

              let(:default_require) { false }

              it 'requires the association' do
                expect(relation.save).to be(false)
              end
            end
          end

          context 'when :required is false' do

            let(:relation_options) do
              { required: false }
            end

            context 'when the default config is to require the association' do

              let(:default_require) { true }

              it 'does not require the association' do
                expect(relation.save!).to be(true)
              end
            end

            context 'when the default config is to not require the association' do

              let(:default_require) { false }

              it 'does not require the association' do
                expect(relation.save!).to be(true)
              end
            end
          end
        end

        context 'when the relation has the option :optional' do

          context 'when :required is true' do

            context 'when :optional is true' do

              let(:relation_options) do
                {
                  required: true,
                  optional: true
                }
              end

              context 'when the default config is to require the association' do

                let(:default_require) { true }

                it 'requires the association' do
                  expect(relation.save).to be(false)
                end
              end

              context 'when the default config is to not require the association' do

                let(:default_require) { false }

                it 'requires the association' do
                  expect(relation.save).to be(false)
                end
              end
            end

            context 'when :optional is false' do

              let(:relation_options) do
                {
                  required: true,
                  optional: false
                }
              end

              context 'when the default config is to require the association' do

                let(:default_require) { true }

                it 'requires the association' do
                  expect(relation.save).to be(false)
                end
              end

              context 'when the default config is to not require the association' do

                let(:default_require) { false }

                it 'requires the association' do
                  expect(relation.save).to be(false)
                end
              end
            end
          end

          context 'when :required is false' do

            context 'when :optional is true' do

              let(:relation_options) do
                {
                  required: false,
                  optional: true
                }
              end

              context 'when the default config is to require the association' do

                let(:default_require) { true }

                it 'does not require the association' do
                  expect(relation.save!).to be(true)
                end
              end

              context 'when the default config is to not require the association' do

                let(:default_require) { true }

                it 'does not require the association' do
                  expect(relation.save!).to be(true)
                end
              end
            end

            context 'when :optional is false' do

              let(:relation_options) do
                {
                  required: false,
                  optional: false
                }
              end

              context 'when the default config is to require the association' do

                let(:default_require) { true }

                it 'does not require the association' do
                  expect(relation.save!).to be(true)
                end
              end

              context 'when the default config is to not require the association' do

                let(:default_require) { false }

                it 'does not require the association' do
                  expect(relation.save!).to be(true)
                end
              end
            end
          end
        end
      end

      context 'when the relation does not have the option :required' do

        context 'when the relation has the option :optional' do

          context 'when :optional is true' do

            let(:relation_options) do
              { optional: true }
            end

            context 'when the default config is to require the association' do

              let(:default_require) { true }

              it 'does not require the association' do
                expect(relation.save!).to be(true)
              end
            end

            context 'when the default config is to not require the association' do

              let(:default_require) { false }

              it 'does not require the association' do
                expect(relation.save!).to be(true)
              end
            end
          end

          context 'when :optional is false' do

            let(:relation_options) do
              { optional: false }
            end

            context 'when the default config is to require the association' do

              let(:default_require) { true }

              it 'requires the association' do
                expect(relation.save).to be(false)
              end
            end

            context 'when the default config is to not require the association' do

              let(:default_require) { false }

              it 'requires the association' do
                expect(relation.save).to be(false)
              end
            end
          end
        end
      end
    end

    context 'when the relation does not have options' do

      context 'when the default config is to require the association' do

        let(:default_require) { true }

        it 'requires the association' do
          expect(relation.save).to be(false)
        end
      end

      context 'when the default config is to not require the association' do

        let(:default_require) { false }

        it 'does not require the association' do
          expect(relation.save!).to be(true)
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when indexed is true" do

        before do
          klass.belongs_to(:relatable, polymorphic: true, index: true)
        end

        let(:index) do
          klass.index_specifications.first
        end

        it "adds the background index to the definitions" do
          expect(index.key).to eq(relatable_id: 1, relatable_type: 1)
        end
      end
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.belongs_to(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      before do
        klass.belongs_to(:person)
      end

      it "adds the association to the klass" do
        expect(klass.relations["person"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:person)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:person=)
      end

      it "defines the builder" do
        expect(klass.allocate).to respond_to(:build_person)
      end

      it "defines the creator" do
        expect(klass.allocate).to respond_to(:create_person)
      end

      it "creates the correct relation" do
        expect(klass.relations["person"]).to be_a(
          Mongoid::Association::Referenced::BelongsTo
        )
      end

      it "creates the field for the foreign key" do
        expect(klass.allocate).to respond_to(:person_id)
      end

      context "association properties" do

        let(:association) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:person)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".has_many" do

    it "defines the macro" do
      expect(klass).to respond_to(:has_many)
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.has_many(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      before do
        klass.has_many(:posts)
      end

      it "adds the association to the klass" do
        expect(klass.relations["posts"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:posts)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:posts=)
      end

      it "creates the correct relation" do
        expect(klass.relations["posts"]).to be_a(
          Mongoid::Association::Referenced::HasMany
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:posts].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "association properties" do

        let(:association) do
          klass.relations["posts"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:posts)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.has_many(:names, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.has_many(:posts, order: :rating.asc)
      end

      let(:association) do
        klass.relations["posts"]
      end

      it "adds association to klass" do
        expect(association.order).to_not be_nil
      end

      it "returns Mongoid::Criteria::Queryable::Key" do
        expect(association.order).to be_kind_of(Mongoid::Criteria::Queryable::Key)
      end
    end

    context "when setting validate to false" do

      before do
        klass.has_many(:posts, validate: false)
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end
    end
  end

  describe ".has_and_belongs_to_many" do

    it "defines the macro" do
      expect(klass).to respond_to(:has_and_belongs_to_many)
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.has_and_belongs_to_many(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.has_and_belongs_to_many(:fields, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      before do
        klass.has_and_belongs_to_many(:preferences)
      end

      it "adds the association to the klass" do
        expect(klass.relations["preferences"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:preferences)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:preferences=)
      end

      it "creates the correct relation" do
        expect(klass.relations["preferences"]).to be_a(
          Mongoid::Association::Referenced::HasAndBelongsToMany
        )
      end

      it "creates the field for the foreign key" do
        expect(klass.allocate).to respond_to(:preference_ids)
      end

      context 'when defining order on relation' do

        before do
          klass.has_and_belongs_to_many(:preferences, order: :ranking.asc)
        end

        let(:association) do
          klass.relations["preferences"]
        end

        it "adds association to klass" do
          expect(association.order).to_not be_nil
        end

        it "returns Mongoid::Criteria::Queryable::Key" do
          expect(association.order).to be_kind_of(Mongoid::Criteria::Queryable::Key)
        end
      end

      context "association properties" do

        let(:association) do
          klass.relations["preferences"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:preferences)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".has_one" do

    it "defines the macro" do
      expect(klass).to respond_to(:has_one)
    end

    context "when defining the relation" do

      context 'when the relation name is invalid' do

        let(:relation) do
          klass.has_one(:fields)
        end

        it 'raises an InvalidRelation exception' do
          expect {
            relation
          }.to raise_exception(Mongoid::Errors::InvalidRelation)
        end
      end

      context 'when an invalid option is provided' do

        it 'raises an InvalidRelationOption exception' do
          expect {
            klass.has_one(:game, sandwich: true)
          }.to raise_exception(Mongoid::Errors::InvalidRelationOption)
        end
      end

      before do
        klass.has_one(:game)
      end

      it "adds the association to the klass" do
        expect(klass.relations["game"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:game)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:game=)
      end

      it "defines the builder" do
        expect(klass.allocate).to respond_to(:build_game)
      end

      it "defines the creator" do
        expect(klass.allocate).to respond_to(:create_game)
      end

      it "creates the correct relation" do
        expect(klass.relations["game"]).to be_a(
          Mongoid::Association::Referenced::HasOne
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:game].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "association properties" do

        let(:association) do
          klass.relations["game"]
        end

        it "automatically adds the name" do
          expect(association.name).to eq(:game)
        end

        it "automatically adds the inverse class name" do
          expect(association.inverse_class_name).to eq("TestClass")
        end
      end
    end

    context "when setting validate to false" do

      before do
        klass.has_one(:game, validate: false)
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end
    end
  end

  describe "#relations" do

    before do
      klass.embeds_one(:name)
    end

    it "returns a bson document of relations" do
      expect(klass.allocate.relations).to be_a_kind_of(BSON::Document)
    end

    it "has keys that are the relation name" do
      expect(klass.allocate.relations['name']).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has keys that can be accessed by a String" do
      expect(klass.allocate.relations['name']).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has keys that can be accessed by a Symbol" do
      expect(klass.allocate.relations[:name]).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has values that are association" do
      expect(
        klass.allocate.relations.values.first
      ).to be_a_kind_of(Mongoid::Association::Embedded::EmbedsOne)
    end
  end

  describe ".relations" do

    before do
      klass.embeds_one(:name)
    end

    it "has keys that are the relation name" do
      expect(klass.allocate.relations['name']).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has keys that can be accessed by a String" do
      expect(klass.allocate.relations['name']).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has keys that can be accessed by a Symbol" do
      expect(klass.allocate.relations[:name]).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end

    it "has values that are association" do
      expect(
        klass.relations.values.first
      ).to be_a(Mongoid::Association::Embedded::EmbedsOne)
    end
  end

  context "when creating an association with an extension" do

    class Peep
      include Mongoid::Document
    end

    class Handle
      include Mongoid::Document

      module Extension
        def short_name
          "spec"
        end
      end

      module AnotherExtension
        def very_short_name
          "spec"
        end
      end
    end

    let(:peep) do
      Peep.new(handle: Handle.new)
    end

    context "when the extension is a block" do

      before do
        Peep.embeds_one(:handle) do
          def full_name
            "spec"
          end
        end
      end

      it "extends the relation" do
        expect(peep.handle.full_name).to eq("spec")
      end
    end

    context "when the extension is a module" do

      before do
        Peep.embeds_one(:handle, extend: Handle::Extension)
      end

      it "extends the relation" do
        expect(peep.handle.short_name).to eq("spec")
      end
    end

    context "when the extension is two modules" do

      before do
        Peep.embeds_one(:handle, extend: [ Handle::Extension, Handle::AnotherExtension ])
      end

      it "extends the relation" do
        expect(peep.handle.very_short_name).to eq("spec")
      end
    end
  end
end
