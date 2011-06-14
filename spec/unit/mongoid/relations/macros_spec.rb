require "spec_helper"

describe Mongoid::Relations::Macros do

  class TestClass
    include Mongoid::Relations
    include Mongoid::Dirty
    include Mongoid::Fields
    include Mongoid::Validations
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
      klass.should respond_to(:embedded_in)
    end

    context "when defining the relation" do

      before do
        klass.embedded_in(:person)
      end

      it "adds the metadata to the klass" do
        klass.relations["person"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:person)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:person=)
      end

      it "creates the correct relation" do
        klass.relations["person"].relation.should ==
          Mongoid::Relations::Embedded::In
      end

      it "does not add associated validations" do
        klass._validators.should be_empty
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          metadata.name.should == :person
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  describe ".embeds_many" do

    it "defines the macro" do
      klass.should respond_to(:embeds_many)
    end

    context "when defining the relation" do

      before do
        klass.embeds_many(:addresses)
      end

      it "adds the metadata to the klass" do
        klass.relations["addresses"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:addresses)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:addresses=)
      end

      it "creates the correct relation" do
        klass.relations["addresses"].relation.should ==
          Mongoid::Relations::Embedded::Many
      end

      it "adds an associated validation" do
        klass._validators[:addresses].first.should be_a(
          Mongoid::Validations::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["addresses"]
        end

        it "automatically adds the name" do
          metadata.name.should == :addresses
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.embeds_many(:addresses, :order => :number.asc)
      end

      let(:metadata) do
        klass.relations["addresses"]
      end

      it "adds metadata to klass" do
        metadata.order.should_not be_nil
      end

      it "returns Mongoid::Criterion::Complex" do
        metadata.order.should be_kind_of(Mongoid::Criterion::Complex)
      end
    end

    context "when setting validate to false" do

      before do
        klass.embeds_many(:addresses, :validate => false)
      end

      it "does not add associated validations" do
        klass._validators.should be_empty
      end
    end
  end

  describe ".embeds_one" do

    it "defines the macro" do
      klass.should respond_to(:embeds_one)
    end

    context "when defining the relation" do

      before do
        klass.embeds_one(:name)
      end

      it "adds the metadata to the klass" do
        klass.relations["name"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:name)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:name=)
      end

      it "defines the builder" do
        klass.allocate.should respond_to(:build_name)
      end

      it "defines the creator" do
        klass.allocate.should respond_to(:create_name)
      end

      it "creates the correct relation" do
        klass.relations["name"].relation.should ==
          Mongoid::Relations::Embedded::One
      end

      it "adds an associated validation" do
        klass._validators[:name].first.should be_a(
          Mongoid::Validations::AssociatedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["name"]
        end

        it "automatically adds the name" do
          metadata.name.should == :name
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end

    context "when setting validate to false" do

      before do
        klass.embeds_one(:name, :validate => false)
      end

      it "does not add associated validations" do
        klass._validators.should be_empty
      end
    end
  end

  describe ".referenced_in" do

    it "defines the macro" do
      klass.should respond_to(:referenced_in)
    end

    context "when defining the relation" do

      before do
        klass.referenced_in(:person)
      end

      it "adds the metadata to the klass" do
        klass.relations["person"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:person)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:person=)
      end

      it "creates the correct relation" do
        klass.relations["person"].relation.should ==
          Mongoid::Relations::Referenced::In
      end

      it "creates the field for the foreign key" do
        klass.allocate.should respond_to(:person_id)
      end

      it "adds associated validations" do
        klass._validators[:person].first.should be_a(
          Mongoid::Validations::ReferencedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["person"]
        end

        it "automatically adds the name" do
          metadata.name.should == :person
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  describe ".references_many" do

    it "defines the macro" do
      klass.should respond_to(:references_many)
    end

    context "when defining the relation" do

      before do
        klass.references_many(:posts)
      end

      it "adds the metadata to the klass" do
        klass.relations["posts"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:posts)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:posts=)
      end

      it "creates the correct relation" do
        klass.relations["posts"].relation.should ==
          Mongoid::Relations::Referenced::Many
      end

      it "adds an associated validation" do
        klass._validators[:posts].first.should be_a(
          Mongoid::Validations::ReferencedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["posts"]
        end

        it "automatically adds the name" do
          metadata.name.should == :posts
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end

    context 'when defining order on relation' do

      before do
        klass.references_many(:posts, :order => :rating.asc)
      end

      let(:metadata) do
        klass.relations["posts"]
      end

      it "adds metadata to klass" do
        metadata.order.should_not be_nil
      end

      it "returns Mongoid::Criterion::Complex" do
        metadata.order.should be_kind_of(Mongoid::Criterion::Complex)
      end
    end

    context "when setting validate to false" do

      before do
        klass.references_many(:posts, :validate => false)
      end

      it "does not add associated validations" do
        klass._validators.should be_empty
      end
    end
  end

  describe ".references_and_referenced_in_many" do

    it "defines the macro" do
      klass.should respond_to(:references_and_referenced_in_many)
    end

    context "when defining the relation" do

      before do
        klass.references_and_referenced_in_many(:preferences)
      end

      it "adds the metadata to the klass" do
        klass.relations["preferences"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:preferences)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:preferences=)
      end

      it "creates the correct relation" do
        klass.relations["preferences"].relation.should ==
          Mongoid::Relations::Referenced::ManyToMany
      end

      it "creates the field for the foreign key" do
        klass.allocate.should respond_to(:preference_ids)
      end

      context 'when defining order on relation' do

        before do
          klass.references_and_referenced_in_many(:preferences, :order => :ranking.asc)
        end

        let(:metadata) do
          klass.relations["preferences"]
        end

        it "adds metadata to klass" do
          metadata.order.should_not be_nil
        end

        it "returns Mongoid::Criterion::Complex" do
          metadata.order.should be_kind_of(Mongoid::Criterion::Complex)
        end
      end


      context "metadata properties" do

        let(:metadata) do
          klass.relations["preferences"]
        end

        it "automatically adds the name" do
          metadata.name.should == :preferences
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end
  end

  describe ".references_one" do

    it "defines the macro" do
      klass.should respond_to(:references_one)
    end

    context "when defining the relation" do

      before do
        klass.references_one(:game)
      end

      it "adds the metadata to the klass" do
        klass.relations["game"].should_not be_nil
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:game)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:game=)
      end

      it "defines the builder" do
        klass.allocate.should respond_to(:build_game)
      end

      it "defines the creator" do
        klass.allocate.should respond_to(:create_game)
      end

      it "creates the correct relation" do
        klass.relations["game"].relation.should ==
          Mongoid::Relations::Referenced::One
      end

      it "adds an associated validation" do
        klass._validators[:game].first.should be_a(
          Mongoid::Validations::ReferencedValidator
        )
      end

      context "metadata properties" do

        let(:metadata) do
          klass.relations["game"]
        end

        it "automatically adds the name" do
          metadata.name.should == :game
        end

        it "automatically adds the inverse class name" do
          metadata.inverse_class_name.should == "TestClass"
        end
      end
    end

    context "when setting validate to false" do

      before do
        klass.references_one(:game, :validate => false)
      end

      it "does not add associated validations" do
        klass._validators.should be_empty
      end
    end
  end

  describe "#relations" do

    before do
      klass.embeds_one(:name)
    end

    it "returns a hash of relations" do
      klass.allocate.relations.should be_a_kind_of(Hash)
    end

    it "has keys that are the relation name" do
      klass.allocate.relations.keys.first.should == "name"
    end

    it "has values that are metadata" do
      klass.allocate.relations.values.first.should
        be_a_kind_of(Mongoid::Relations::Metadata)
    end
  end

  describe ".relations" do

    before do
      klass.embeds_one(:name)
    end

    it "returns a hash of relations" do
      klass.relations.should be_a_kind_of(Hash)
    end

    it "has keys that are the relation name" do
      klass.relations.keys.first.should == "name"
    end

    it "has values that are metadata" do
      klass.relations.values.first.should
        be_a_kind_of(Mongoid::Relations::Metadata)
    end
  end
end
