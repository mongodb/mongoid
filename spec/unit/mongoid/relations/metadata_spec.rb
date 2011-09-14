require "spec_helper"

describe Mongoid::Relations::Metadata do

  describe "#builder" do

    let(:metadata) do
      described_class.new(:relation => Mongoid::Relations::Embedded::One)
    end

    let(:object) do
      stub
    end

    it "returns the builder from the relation" do
      metadata.builder(object).should
        be_a_kind_of(Mongoid::Relations::Builders::Embedded::One)
    end
  end

  describe "#cascade_strategy" do

    context "when no dependent option is set" do

      let(:metadata) do
        described_class.new(
          :name => :posts,
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      it "returns nil" do
        metadata.cascade_strategy.should be_nil
      end
    end

    context "when dependent is delete" do

      let(:metadata) do
        described_class.new(
          :name => :posts,
          :relation => Mongoid::Relations::Referenced::Many,
          :dependent => :delete
        )
      end

      it "returns the delete strategy" do
        metadata.cascade_strategy.should ==
          Mongoid::Relations::Cascading::Delete
      end
    end

    context "when dependent is destroy" do

      let(:metadata) do
        described_class.new(
          :name => :posts,
          :relation => Mongoid::Relations::Referenced::Many,
          :dependent => :destroy
        )
      end

      it "returns the destroy strategy" do
        metadata.cascade_strategy.should ==
          Mongoid::Relations::Cascading::Destroy
      end
    end

    context "when dependent is nullify" do

      let(:metadata) do
        described_class.new(
          :name => :posts,
          :relation => Mongoid::Relations::Referenced::Many,
          :dependent => :nullify
        )
      end

      it "returns the nullify strategy" do
        metadata.cascade_strategy.should ==
          Mongoid::Relations::Cascading::Nullify
      end
    end
  end

  describe "#constraint" do

    let(:metadata) do
      described_class.new(
        :relation => Mongoid::Relations::Referenced::Many,
        :class_name => "Person"
      )
    end

    it "returns the constraint object" do
      metadata.constraint.should be_a(Mongoid::Relations::Constraint)
    end
  end

  describe "#class_name" do

    context "when class_name provided" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many,
          :class_name => "Person"
        )
      end

      it "constantizes the class name" do
        metadata.class_name.should == "Person"
      end
    end

    context "when no class_name provided" do

      context "when association name is singular" do

        let(:relation) do
          Mongoid::Relations::Embedded::One
        end

        let(:metadata) do
          described_class.new(:name => :name, :relation => relation)
        end

        it "classifies and constantizes the association name" do
          metadata.class_name.should == "Name"
        end
      end

      context "when association name is plural" do

        let(:relation) do
          Mongoid::Relations::Embedded::Many
        end

        let(:metadata) do
          described_class.new(:name => :addresses, :relation => relation)
        end

        it "classifies and constantizes the association name" do
          metadata.class_name.should == "Address"
        end
      end
    end
  end

  describe "#destructive?" do

    context "when the relation has a destructive dependent option" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many,
          :dependent => :destroy
        )
      end

      it "returns true" do
        metadata.should be_destructive
      end
    end

    context "when no dependent option" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        metadata.should_not be_destructive
      end
    end
  end

  describe "#embedded?" do

    context "when the relation is embedded" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Embedded::Many
        )
      end

      it "returns true" do
        metadata.should be_embedded
      end
    end

    context "when the relation is not embedded" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        metadata.should_not be_embedded
      end
    end
  end

  describe "#extension" do

    let(:metadata) do
      described_class.new(
        :relation => Mongoid::Relations::Referenced::Many,
        :extend => :value
      )
    end

    it "returns the extend property" do
      metadata.extension.should == :value
    end
  end

  describe "#extension?" do

    context "when an extends property exists" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many,
          :extend => :value
        )
      end

      it "returns true" do
        metadata.extension?.should == true
      end
    end

    context "when the extend option is nil" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        metadata.extension?.should == false
      end
    end
  end

  describe "#foreign_key" do

    context "when no foreign key was explicitly defined" do

      context "when the relation stores a foreign key" do

        context "when referenced in" do

          context "when not providing a class name" do

            let(:metadata) do
              described_class.new(
                :name => :person,
                :relation => Mongoid::Relations::Referenced::In
              )
            end

            it "returns the foreign_key" do
              metadata.foreign_key.should == "person_id"
            end
          end

          context "when providing a class name" do

            let(:metadata) do
              described_class.new(
                :name => :person,
                :relation => Mongoid::Relations::Referenced::In,
                :class_name => "TheseAreNotTheDriods"
              )
            end

            it "returns the foreign_key" do
              metadata.foreign_key.should == "person_id"
            end
          end

          context "when the class is namespaces" do

            let(:metadata) do
              described_class.new(
                :name => :apple,
                :relation => Mongoid::Relations::Referenced::In,
                :class_name => "Fruits::Apple"
              )
            end

            it "returns the foreign_key without the module name" do
              metadata.foreign_key.should == "apple_id"
            end
          end
        end

        context "when references and referenced in many" do

          let(:metadata) do
            described_class.new(
              :name => :people,
              :relation => Mongoid::Relations::Referenced::ManyToMany
            )
          end

          it "returns the foreign_key" do
            metadata.foreign_key.should == "person_ids"
          end

          context "given a specific foreign key" do
            let(:metadata) do
            described_class.new(
                :name => :follower,
                :foreign_key => :follower_list,
                :relation => Mongoid::Relations::Referenced::ManyToMany
              )
            end

            it "returns the foreign_key" do
              metadata.foreign_key.should == "follower_list"
            end
          end

          context "using name as foreign key" do
            let(:metadata) do
            described_class.new(
                :name => :followers,
                :class_name => "Person",
                :relation => Mongoid::Relations::Referenced::ManyToMany
              )
            end

            it "returns the foreign_key" do
              metadata.foreign_key.should == "follower_ids"
            end
          end

          context "when the class is namespaced" do
            let(:metadata) do
              described_class.new(
                :name => :bananas,
                :relation => Mongoid::Relations::Referenced::ManyToMany,
                :inverse_class_name => "Fruits::Apple",
                :class_name => "Fruits::Banana"
              )
            end

            it "returns the foreign_key without the module name" do
              metadata.foreign_key.should == "banana_ids"
            end

            it "returns the inverse_foreign_key without the module name" do
              metadata.inverse_foreign_key.should == "apple_ids"
            end

          end
        end
      end

      context "when the relation does not store a foreign key" do

        context "when references one" do

          let(:metadata) do
            described_class.new(
              :name => :post,
              :relation => Mongoid::Relations::Referenced::One,
              :inverse_class_name => "Person"
            )
          end

          it "returns the inverse foreign key" do
            metadata.foreign_key.should == "person_id"
          end
        end

        context "when references many" do

          context "when an inverse_of is defined" do

            let(:metadata) do
              described_class.new(
                :name => :created_streets,
                :relation => Mongoid::Relations::Referenced::Many,
                :inverse_class_name => "House",
                :inverse_of => :creator
              )
            end

            it "returns the inverse_of plus suffix" do
              metadata.foreign_key.should == "creator_id"
            end
          end

          context "when the class is not namespaced" do

            let(:metadata) do
              described_class.new(
                :name => :posts,
                :relation => Mongoid::Relations::Referenced::Many,
                :inverse_class_name => "Person"
              )
            end

            it "returns the inverse foreign key" do
              metadata.foreign_key.should == "person_id"
            end
          end

          context "when the class is namespaced" do

            let(:metadata) do
              described_class.new(
                :name => :bananas,
                :relation => Mongoid::Relations::Referenced::Many,
                :inverse_class_name => "Fruits::Apple",
                :class_name => "Fruits::Banana"
              )
            end

            it "returns the foreign_key without the module name" do
              metadata.foreign_key.should == "apple_id"
            end
          end
        end
      end
    end

    context "when a foreign_key was defined" do

      let(:metadata) do
        described_class.new(
          :name => :person,
          :relation => Mongoid::Relations::Referenced::ManyToMany,
          :foreign_key => "blog_post_id"
        )
      end

      it "returns the foreign_key" do
        metadata.foreign_key.should == "blog_post_id"
      end
    end
  end

  describe "#foreign_key_default" do

    context "when the relation stores keys in an array" do

      let(:metadata) do
        described_class.new(
          :name => :preferences,
          :relation => Mongoid::Relations::Referenced::ManyToMany,
          :foreign_key => "preference_ids"
        )
      end

      it "returns an empty array" do
        metadata.foreign_key_default.should == []
      end
    end

    context "when the relation stores a single key" do

      let(:metadata) do
        described_class.new(
          :name => :person,
          :relation => Mongoid::Relations::Referenced::In,
          :foreign_key => "person_id"
        )
      end

      it "returns an empty array" do
        metadata.foreign_key_default.should be_nil
      end
    end
  end

  describe "#foreign_key_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :person,
          :relation => Mongoid::Relations::Referenced::In,
          :foreign_key => "person_id"
        )
      end

      it "returns the foreign_key plus =" do
        metadata.foreign_key_setter.should == "person_id="
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :ratings,
          :relation => Mongoid::Relations::Referenced::Many,
          :as => :ratable,
          :inverse_class_name => "Movie"
        )
      end

      it "returns the polymorphic foreign_key plus =" do
        metadata.foreign_key_setter.should == "ratable_id="
      end
    end
  end

  describe "#inspect" do

    let(:metadata) do
      described_class.new(
        :name => :preferences,
        :relation => Mongoid::Relations::Referenced::ManyToMany,
        :inverse_class_name => "Person"
      )
    end

    it "contains all relevant information" do
      metadata.inspect.should ==
        "#<Mongoid::Relations::Metadata\n" <<
        "  class_name:           #{metadata.class_name},\n" <<
        "  cyclic:               #{metadata.cyclic || "No"},\n" <<
        "  dependent:            #{metadata.dependent || "None"},\n" <<
        "  inverse_of:           #{metadata.inverse_of || "N/A"},\n" <<
        "  key:                  #{metadata.key},\n" <<
        "  macro:                #{metadata.macro},\n" <<
        "  name:                 #{metadata.name},\n" <<
        "  order:                #{metadata.order.inspect || "No"},\n" <<
        "  polymorphic:          #{metadata.polymorphic? ? "Yes" : "No"},\n" <<
        "  relation:             #{metadata.relation},\n" <<
        "  setter:               #{metadata.setter},\n" <<
        "  versioned:            #{metadata.versioned? || "No"}>\n"
    end
  end

  describe "#inverse_type" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :person,
          :relation => Mongoid::Relations::Referenced::In,
          :foreign_key => "person_id"
        )
      end

      it "returns nil" do
        metadata.inverse_type.should be_nil
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :ratable,
          :relation => Mongoid::Relations::Referenced::In,
          :polymorphic => true,
          :inverse_class_name => "Rating"
        )
      end

      it "returns the polymorphic name plus type" do
        metadata.inverse_type.should == "ratable_type"
      end
    end
  end

  describe "#inverse_type_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :person,
          :relation => Mongoid::Relations::Referenced::In,
          :foreign_key => "person_id"
        )
      end

      it "returns nil" do
        metadata.inverse_type_setter.should be_nil
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :ratable,
          :relation => Mongoid::Relations::Referenced::In,
          :polymorphic => true,
          :inverse_class_name => "Rating"
        )
      end

      it "returns the inverse type plus =" do
        metadata.inverse_type_setter.should == "ratable_type="
      end
    end
  end

  describe "#indexed?" do

    context "when an index property exists" do

      let(:metadata) do
        described_class.new(
          :index => true,
          :relation => Mongoid::Relations::Referenced::In
        )
      end

      it "returns true" do
        metadata.indexed?.should == true
      end
    end

    context "when the index option is nil" do

      let(:metadata) do
        described_class.new(
          :relation => Mongoid::Relations::Referenced::In
        )
      end

      it "returns false" do
        metadata.indexed?.should == false
      end
    end

    context "when the index option is false" do

      let(:metadata) do
        described_class.new(
          :index => false,
          :relation => Mongoid::Relations::Referenced::In
        )
      end

      it "returns false" do
        metadata.indexed?.should == false
      end
    end
  end

  context "#inverse" do

    context "when an inverse relation exists" do

      context "when multiple relations against the same class exist" do

        let(:metadata) do
          described_class.new(
            :inverse_class_name => "User",
            :name => :shop,
            :relation => Mongoid::Relations::Referenced::One
          )
        end

        it "returns the name of the inverse with the matching inverse of" do
          metadata.inverse.should eq(:user)
        end
      end

      context "when inverse_of is defined" do

        context "when inverse_of is a symbol" do

          let(:metadata) do
            described_class.new(
              :inverse_of => nil,
              :relation => Mongoid::Relations::Referenced::In
            )
          end

          it "returns nil" do
            metadata.inverse.should be_nil
          end
        end

        context "when inverse_of is nil" do

          let(:metadata) do
            described_class.new(
              :inverse_of => :crazy_name,
              :relation => Mongoid::Relations::Referenced::In
            )
          end

          it "returns the name of the inverse_of property" do
            metadata.inverse.should == :crazy_name
          end
        end
      end

      context "when not polymorphic" do

        let(:metadata) do
          described_class.new(
            :name => :pet,
            :class_name => "Animal",
            :inverse_class_name => "Person",
            :relation => Mongoid::Relations::Referenced::In
          )
        end

        it "returns the name of the relation" do
          metadata.inverse.should == :person
        end
      end

      context "when polymorphic" do

        let(:metadata) do
          described_class.new(
            :name => :addresses,
            :as => :addressable,
            :inverse_class_name => "Person",
            :relation => Mongoid::Relations::Referenced::Many
          )
        end

        it "returns the name of the relation" do
          metadata.inverse.should == :addressable
        end
      end

      context "when polymorphic on the child" do

        let(:metadata) do
          described_class.new(
            :name => :addressable,
            :polymorphic => true,
            :inverse_class_name => "Address",
            :relation => Mongoid::Relations::Referenced::In
          )
        end

        it "returns the name of the relation" do
          metadata.inverse(Person.new).should == :addresses
        end
      end

      context "when in a cyclic relation" do

        context "when the base name is included in the plural form" do

          let(:metadata) do
            described_class.new(
              :name => :parent_role,
              :class_name => "Role",
              :inverse_class_name => "Role",
              :relation => Mongoid::Relations::Embedded::In,
              :cyclic => true
            )
          end

          it "returns the name of the relation" do
            metadata.inverse(Role.new).should == :child_roles
          end
        end

        context "when the base name is not included in the plural form" do

          let(:metadata) do
            described_class.new(
              :name => :parent_entry,
              :class_name => "Entry",
              :inverse_class_name => "Entry",
              :relation => Mongoid::Relations::Embedded::In,
              :cyclic => true
            )
          end

          it "returns the name of the relation" do
            metadata.inverse(Entry.new).should == :child_entries
          end
        end
      end
    end
  end

  context "#inverse_foreign_key" do

    context "when the inverse foreign key is not defined" do

      let(:metadata) do
        described_class.new(
          :name => :preferences,
          :index => true,
          :dependent => :nullify,
          :relation => Mongoid::Relations::Referenced::ManyToMany,
          :inverse_class_name => "Person"
        )
      end

      it "returns the inverse class name plus suffix" do
        metadata.inverse_foreign_key.should == "person_ids"
      end
    end
  end

  context "#inverse_klass" do

    let(:metadata) do
      described_class.new(
        :inverse_class_name => "Person",
        :relation => Mongoid::Relations::Referenced::In
      )
    end

    it "constantizes the inverse_class_name" do
      metadata.inverse_klass.should == Person
    end
  end

  context "#inverse_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          :name => :pet,
          :class_name => "Animal",
          :inverse_class_name => "Person",
          :relation => Mongoid::Relations::Referenced::In
        )
      end

      it "returns a string for the setter" do
        metadata.inverse_setter.should == "person="
      end
    end

    context "when the relation is polymorphic" do

      context "when a referenced in" do

        let(:metadata) do
          described_class.new(
            :name => :ratable,
            :inverse_class_name => "Movie",
            :polymorphic => true,
            :relation => Mongoid::Relations::Referenced::In
          )
        end

        let(:other) do
          Movie.new
        end

        it "returns a string for the setter" do
          metadata.inverse_setter(other).should == "ratings="
        end
      end

      context "when a references many" do

        let(:metadata) do
          described_class.new(
            :name => :ratings,
            :inverse_class_name => "Rating",
            :as => :ratable,
            :relation => Mongoid::Relations::Referenced::Many
          )
        end

        it "returns a string for the setter" do
          metadata.inverse_setter.should == "ratable="
        end
      end
    end
  end

  context "#key" do

    context "when relation is embedded" do

      let(:metadata) do
        described_class.new(
          :name => :addresses,
          :relation => Mongoid::Relations::Embedded::Many
        )
      end

      it "returns the name as a string" do
        metadata.key.should == "addresses"
      end
    end

    context "when relation is referenced" do

      context "when relation stores foreign_key" do

        context "when the relation is not polymorphic" do

          let(:metadata) do
            described_class.new(
              :name => :posts,
              :relation => Mongoid::Relations::Referenced::ManyToMany
            )
          end

          it "returns the foreign_key" do
            metadata.key.should == "post_ids"
          end
        end

        context "when the relation is polymorphic" do

          let(:metadata) do
            described_class.new(
              :name => :ratable,
              :relation => Mongoid::Relations::Referenced::In,
              :polymorphic => true
            )
          end

          it "returns the polymorphic foreign_key" do
            metadata.key.should == "ratable_id"
          end
        end
      end

      context "when relation does not store a foreign_key" do

        let(:metadata) do
          described_class.new(
            :name => :addresses,
            :relation => Mongoid::Relations::Referenced::Many,
            :inverse_class_name => "Person"
          )
        end

        it "returns _id" do
          metadata.key.should == "_id"
        end
      end
    end
  end

  context "#order" do
    let(:metadata) do
      described_class.new(
        :order => :rating.asc,
        :relation => Mongoid::Relations::Referenced::Many
      )
    end

    it "returns order criteria" do
      metadata.order.should == :rating.asc
    end

  end

  describe "#klass" do

    let(:metadata) do
      described_class.new(
        :class_name => "Address",
        :relation => Mongoid::Relations::Embedded::Many
      )
    end

    it "constantizes the class_name" do
      metadata.klass.should == Address
    end
  end

  describe "#many?" do

    context "when the relation is a many" do

      let(:metadata) do
        described_class.new(:relation => Mongoid::Relations::Embedded::Many)
      end

      it "returns true" do
        metadata.should be_many
      end
    end

    context "when the relation is not a many" do

      let(:metadata) do
        described_class.new(:relation => Mongoid::Relations::Embedded::One)
      end

      it "returns false" do
        metadata.should_not be_many
      end
    end
  end

  describe "#macro" do

    let(:metadata) do
      described_class.new(:relation => Mongoid::Relations::Embedded::One)
    end

    it "returns the macro from the relation" do
      metadata.macro.should == :embeds_one
    end
  end

  describe "#nested_builder" do

    let(:metadata) do
      described_class.new(:relation => Mongoid::Relations::Embedded::One)
    end

    let(:attributes) do
      {}
    end

    let(:options) do
      {}
    end

    it "returns the nested builder from the relation" do
      metadata.nested_builder(attributes, options).should
        be_a_kind_of(Mongoid::Relations::Builders::NestedAttributes::One)
    end
  end

  describe "#validate?" do

    context "when validate is provided" do

      context "when validate is true" do

        let(:metadata) do
          described_class.new(
            :name => :posts,
            :inverse_class_name => "Post",
            :relation => Mongoid::Relations::Referenced::Many,
            :validate => true
          )
        end

        it "returns true" do
          metadata.validate?.should eq(true)
        end
      end

      context "when validate is false" do

        let(:metadata) do
          described_class.new(
            :name => :posts,
            :inverse_class_name => "Post",
            :relation => Mongoid::Relations::Referenced::Many,
            :validate => false
          )
        end

        it "returns false" do
          metadata.validate?.should eq(false)
        end
      end
    end

    context "when validate is not provided" do

      let(:metadata) do
        described_class.new(
          :name => :posts,
          :inverse_class_name => "Post",
          :relation => Mongoid::Relations::Referenced::Many
        )
      end

      it "returns the relation default" do
        metadata.validate?.should eq(true)
      end
    end
  end

  describe "#versioned?" do

    context "when versioned is true" do

      let(:metadata) do
        described_class.new(
          :name => :versions,
          :relation => Mongoid::Relations::Embedded::Many,
          :versioned => true
        )
      end

      it "returns true" do
        metadata.should be_versioned
      end
    end

    context "when versioned is false" do

      let(:metadata) do
        described_class.new(
          :name => :versions,
          :relation => Mongoid::Relations::Embedded::Many,
          :versioned => false
        )
      end

      it "returns false" do
        metadata.should_not be_versioned
      end
    end

    context "when versioned is nil" do

      let(:metadata) do
        described_class.new(
          :name => :versions,
          :relation => Mongoid::Relations::Embedded::Many
        )
      end

      it "returns false" do
        metadata.should_not be_versioned
      end
    end
  end

  context "properties" do

    PROPERTIES = [
      "as",
      "cyclic",
      "name",
      "order"
    ]

    PROPERTIES.each do |property|

      describe "##{property}" do

        let(:metadata) do
          described_class.new(
            property.to_sym => :value,
            :relation => Mongoid::Relations::Embedded::Many
          )
        end

        it "returns the #{property} property" do
          metadata.send(property).should == :value
        end
      end

      describe "##{property}?" do

        context "when a #{property} property exists" do

          let(:metadata) do
            described_class.new(
              property.to_sym => :value,
              :relation => Mongoid::Relations::Embedded::Many
            )
          end

          it "returns true" do
            metadata.send("#{property}?").should == true
          end
        end

        context "when the #{property} property is nil" do

          let(:metadata) do
            described_class.new(
              :relation => Mongoid::Relations::Embedded::Many
            )
          end

          it "returns false" do
            metadata.send("#{property}?").should == false
          end
        end
      end
    end
  end
end
