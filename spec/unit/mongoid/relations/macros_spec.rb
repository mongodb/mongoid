require "spec_helper"

describe Mongoid::Relations::Macros do

  let(:klass) do
    Class.new do
      include Mongoid::Relations
      include Mongoid::Dirty
      include Mongoid::Fields
      def self.name
        "TestClass"
      end
    end
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

      it "marks the class as embedded" do
        klass.embedded.should == true
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

      it "does not mark the class as embedded" do
        klass.embedded.should == false
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

  describe ".referenced_in_from_array" do

    it "defines the macro" do
      klass.should respond_to(:referenced_in_from_array)
    end

    context "when defining the relation" do

      before do
        klass.referenced_in_from_array(:person)
      end

      it "adds the metadata to the klass" do
        klass.relations["person"].should_not be_nil
      end

      it "does not mark the class as embedded" do
        klass.embedded.should == false
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:person)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:person=)
      end

      it "creates the correct relation" do
        klass.relations["person"].relation.should ==
          Mongoid::Relations::Referenced::InFromArray
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

      it "does not mark the class as embedded" do
        klass.embedded.should == false
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
  end

  describe ".references_many_as_array" do

    it "defines the macro" do
      klass.should respond_to(:references_many_as_array)
    end

    context "when defining the relation" do

      before do
        klass.references_many_as_array(:posts)
      end

      it "adds the metadata to the klass" do
        klass.relations["posts"].should_not be_nil
      end

      it "does not mark the class as embedded" do
        klass.embedded.should == false
      end

      it "defines the getter" do
        klass.allocate.should respond_to(:posts)
      end

      it "defines the setter" do
        klass.allocate.should respond_to(:posts=)
      end

      it "creates the correct relation" do
        klass.relations["posts"].relation.should ==
          Mongoid::Relations::Referenced::ManyAsArray
      end

      it "creates the field for the foreign key" do
        klass.allocate.should respond_to(:post_ids)
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

      it "does not mark the class as embedded" do
        klass.embedded.should == false
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

      it "does not mark the class as embedded" do
        klass.embedded.should == false
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
