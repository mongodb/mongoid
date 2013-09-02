require "spec_helper"

describe Mongoid::Relations::Macros do

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

  describe ".embedded_in" do

    it "defines the macro" do
      expect(klass).to respond_to(:embedded_in)
    end

    context "when defining the relation" do

      before do
        klass.embedded_in(:person)
      end

      it "adds the metadata to the klass" do
        expect(klass.relations["person"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:person)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:person=)
      end

      it "creates the correct relation" do
        expect(klass.relations["person"].relation).to eq(
          Mongoid::Relations::Embedded::In
        )
      end

      it "does not add associated validations" do
        expect(klass._validators).to be_empty
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:person)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".embeds_many" do

    it "defines the macro" do
      expect(klass).to respond_to(:embeds_many)
    end

    context "when defining the relation" do

      before do
        klass.embeds_many(:addresses)
      end

      it "adds the metadata to the klass" do
        expect(klass.relations["addresses"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:addresses)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:addresses=)
      end

      it "creates the correct relation" do
        expect(klass.relations["addresses"].relation).to eq(
          Mongoid::Relations::Embedded::Many
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:addresses].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["addresses"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:addresses)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.embeds_many(:addresses, order: :number.asc)
      end

      let(:metadata) do
        klass.relations["addresses"]
      end

      it "adds metadata to klass" do
        expect(metadata.order).to_not be_nil
      end

      it "returns Origin::Key" do
        expect(metadata.order).to be_kind_of(Origin::Key)
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

      before do
        klass.embeds_one(:name)
      end

      it "adds the metadata to the klass" do
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
        expect(klass.relations["name"].relation).to eq(
          Mongoid::Relations::Embedded::One
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:name].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["name"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:name)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
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

    it "defines the macro" do
      expect(klass).to respond_to(:belongs_to)
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

      before do
        klass.belongs_to(:person)
      end

      it "adds the metadata to the klass" do
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
        expect(klass.relations["person"].relation).to eq(
          Mongoid::Relations::Referenced::In
        )
      end

      it "creates the field for the foreign key" do
        expect(klass.allocate).to respond_to(:person_id)
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:person)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".has_many" do

    it "defines the macro" do
      expect(klass).to respond_to(:has_many)
    end

    context "when defining the relation" do

      before do
        klass.has_many(:posts)
      end

      it "adds the metadata to the klass" do
        expect(klass.relations["posts"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:posts)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:posts=)
      end

      it "creates the correct relation" do
        expect(klass.relations["posts"].relation).to eq(
          Mongoid::Relations::Referenced::Many
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:posts].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["posts"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:posts)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.has_many(:posts, order: :rating.asc)
      end

      let(:metadata) do
        klass.relations["posts"]
      end

      it "adds metadata to klass" do
        expect(metadata.order).to_not be_nil
      end

      it "returns Origin::Key" do
        expect(metadata.order).to be_kind_of(Origin::Key)
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

      before do
        klass.has_and_belongs_to_many(:preferences)
      end

      it "adds the metadata to the klass" do
        expect(klass.relations["preferences"]).to_not be_nil
      end

      it "defines the getter" do
        expect(klass.allocate).to respond_to(:preferences)
      end

      it "defines the setter" do
        expect(klass.allocate).to respond_to(:preferences=)
      end

      it "creates the correct relation" do
        expect(klass.relations["preferences"].relation).to eq(
          Mongoid::Relations::Referenced::ManyToMany
        )
      end

      it "creates the field for the foreign key" do
        expect(klass.allocate).to respond_to(:preference_ids)
      end

      context 'when defining order on relation' do

        before do
          klass.has_and_belongs_to_many(:preferences, order: :ranking.asc)
        end

        let(:metadata) do
          klass.relations["preferences"]
        end

        it "adds metadata to klass" do
          expect(metadata.order).to_not be_nil
        end

        it "returns Origin::Key" do
          expect(metadata.order).to be_kind_of(Origin::Key)
        end
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["preferences"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:preferences)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
        end
      end
    end
  end

  describe ".has_one" do

    it "defines the macro" do
      expect(klass).to respond_to(:has_one)
    end

    context "when defining the relation" do

      before do
        klass.has_one(:game)
      end

      it "adds the metadata to the klass" do
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
        expect(klass.relations["game"].relation).to eq(
          Mongoid::Relations::Referenced::One
        )
      end

      it "adds an associated validation" do
        expect(klass._validators[:game].first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["game"]
        end

        it "automatically adds the name" do
          expect(metadata.name).to eq(:game)
        end

        it "automatically adds the inverse class name" do
          expect(metadata.inverse_class_name).to eq("TestClass")
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

    it "returns a hash of relations" do
      expect(klass.allocate.relations).to be_a_kind_of(Hash)
    end

    it "has keys that are the relation name" do
      expect(klass.allocate.relations.keys.first).to eq("name")
    end

    it "has values that are metadata" do
      expect(
        klass.allocate.relations.values.first
      ).to be_a_kind_of(Mongoid::Relations::Metadata)
    end
  end

  describe ".relations" do

    before do
      klass.embeds_one(:name)
    end

    it "returns a hash of relations" do
      expect(klass.relations).to be_a_kind_of(Hash)
    end

    it "has keys that are the relation name" do
      expect(klass.relations.keys.first).to eq("name")
    end

    it "has values that are metadata" do
      expect(
        klass.relations.values.first
      ).to be_a_kind_of(Mongoid::Relations::Metadata)
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
