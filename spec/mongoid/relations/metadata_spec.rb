require "spec_helper"

describe Mongoid::Relations::Metadata do

  describe "#counter_cached?" do

    context "when counter_cache is false" do

      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
          counter_cache: false
        )
      end

      it "returns false" do
        expect(metadata).to_not be_counter_cached
      end
    end

    context "when counter_cache is true" do

      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
          counter_cache: true
        )
      end

      it "returns true" do
        expect(metadata).to be_counter_cached
      end
    end

    context "when counter_cache is name for column" do

      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
          counter_cache: 'counter'
        )
      end

      it "returns true" do
        expect(metadata).to be_counter_cached
      end
    end

    context "when counter_cache is nil" do

      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
        )
      end

      it "returns false" do
        expect(metadata).to_not be_counter_cached
      end
    end
  end

  describe "#counter_cache_column_name" do

    let(:inverse_class_name) do
      "Wheel"
    end

    context "when the counter_cache is true" do

      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
          inverse_class_name: inverse_class_name,
          counter_cache: true
        )
      end

      before do
        expect(metadata).to receive(:inverse).and_return(:wheels)
      end

      it "returns inverse name + _count" do
        expect(metadata.counter_cache_column_name).to eq(
          "#{inverse_class_name.demodulize.underscore.pluralize}_count"
        )
      end
    end

    context "when given a custom name for counter cache" do
      let(:counter_cache_name) { 'counte_cache_for_wheels' }
      let(:metadata) do
        described_class.new(
          name: :car,
          relation: Mongoid::Relations::Referenced::In,
          inverse_class_name: inverse_class_name,
          counter_cache: counter_cache_name
        )
      end

      it "returns the name given" do
        expect(metadata.counter_cache_column_name).to eq(counter_cache_name)
      end
    end
  end

  describe "#autobuilding?" do

    context "when the option is true" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::One,
          autobuild: true
        )
      end

      it "returns true" do
        expect(metadata).to be_autobuilding
      end
    end

    context "when the option is false" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::One,
          autobuild: false
        )
      end

      it "returns false" do
        expect(metadata).to_not be_autobuilding
      end
    end

    context "when the option is nil" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::One
        )
      end

      it "returns false" do
        expect(metadata).to_not be_autobuilding
      end
    end
  end

  describe "#builder" do

    let(:metadata) do
      described_class.new(relation: Mongoid::Relations::Embedded::One)
    end

    let(:object) do
      double
    end

    let(:base) do
      double
    end

    it "returns the builder from the relation" do
      expect(
        metadata.builder(base, object)
      ).to be_a_kind_of(Mongoid::Relations::Builders::Embedded::One)
    end
  end

  describe "#cascading_callbacks?" do

    context "when the option is true" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::Many,
          cascade_callbacks: true
        )
      end

      it "returns true" do
        expect(metadata).to be_cascading_callbacks
      end
    end

    context "when the option is false" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::Many,
          cascade_callbacks: false
        )
      end

      it "returns false" do
        expect(metadata).to_not be_cascading_callbacks
      end
    end

    context "when the option is nil" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::Many
        )
      end

      it "returns false" do
        expect(metadata).to_not be_cascading_callbacks
      end
    end
  end

  describe "#cascade_strategy" do

    context "when no dependent option is set" do

      let(:metadata) do
        described_class.new(
          name: :posts,
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      it "returns nil" do
        expect(metadata.cascade_strategy).to be_nil
      end
    end

    context "when dependent is delete" do

      let(:metadata) do
        described_class.new(
          name: :posts,
          relation: Mongoid::Relations::Referenced::Many,
          dependent: :delete
        )
      end

      it "returns the delete strategy" do
        expect(metadata.cascade_strategy).to eq(
          Mongoid::Relations::Cascading::Delete
        )
      end
    end

    context "when dependent is destroy" do

      let(:metadata) do
        described_class.new(
          name: :posts,
          relation: Mongoid::Relations::Referenced::Many,
          dependent: :destroy
        )
      end

      it "returns the destroy strategy" do
        expect(metadata.cascade_strategy).to eq(
          Mongoid::Relations::Cascading::Destroy
        )
      end
    end

    context "when dependent is nullify" do

      let(:metadata) do
        described_class.new(
          name: :posts,
          relation: Mongoid::Relations::Referenced::Many,
          dependent: :nullify
        )
      end

      it "returns the nullify strategy" do
        expect(metadata.cascade_strategy).to eq(
          Mongoid::Relations::Cascading::Nullify
        )
      end
    end
  end

  describe "#constraint" do

    let(:metadata) do
      described_class.new(
        relation: Mongoid::Relations::Referenced::Many,
        class_name: "Person"
      )
    end

    it "returns the constraint object" do
      expect(metadata.constraint).to be_a(Mongoid::Relations::Constraint)
    end
  end

  describe "#classify" do

    let(:name) do
      "name"
    end

    let(:metadata) do
      described_class.new(name: name)
    end

    let(:classified) do
      metadata.send(:classify)
    end

    before do
      expect(Mongoid::Relations::Options).to receive(:validate!).at_least(:once)
    end

    it "concatenates the result from #find_module and name.classify" do
      expect(metadata).to receive(:find_module).once.and_return("Fruit")
      expect(classified).to eq("Fruit::Name")
    end
  end

  describe "#find_module" do

    let(:name) do
      "name"
    end

    let(:metadata) do
      described_class.new(name: name, inverse_class_name: inverse_class_name)
    end

    let(:mod) do
      metadata.send(:find_module)
    end

    before do
      expect(Mongoid::Relations::Options).to receive(:validate!).at_least(:once)
    end

    context "when inverse_class_name is nil" do

      let(:inverse_class_name) do
        nil
      end

      it "returns nil" do
        expect(mod).to be_nil
      end
    end

    context "when inverse_class_name is empty" do

      let(:inverse_class_name) do
        ""
      end

      it "returns nil" do
        expect(mod).to be_nil
      end
    end

    context "when inverse_class_name is defined" do

      context "when inverse_class_name is in root namespace" do

        let(:inverse_class_name) do
          "Person"
        end

        context "when name isn't defined" do

          let(:name) do
            "undefined"
          end

          it "returns nil" do
            expect(mod).to be_nil
          end
        end

        context "when name is defined in root namespace" do

          let(:name) do
            "account"
          end

          it "returns root namespace" do
            expect(mod).to be_nil
          end
        end

        context "when name is defined in module Fruits" do

          context "when inverse_class_name is defined in the same module" do

            let(:inverse_class_name) do
              "Fruits::Apple"
            end

            let(:name) do
              "banana"
            end

            it "returns Fruits" do
              expect(mod).to eq("Fruits")
            end
          end

          context "when inverse_class_name is defined in a nested module" do

            let(:inverse_class_name) do
              "Fruits::Big::Ananas"
            end

            let(:name) do
              "banana"
            end

            it "returns Fruits" do
              expect(mod).to eq("Fruits")
            end
          end

          context "when the inverse_class_name is defined in the root namespace" do

            let(:inverse_class_name) do
              "Person"
            end

            let(:name) do
              "banana"
            end

            it "returns nil" do
              expect(mod).to be_nil
            end
          end
        end
      end
    end
  end

  describe "#class_name" do

    context "when class_name provided" do

      context "when the class name contains leading ::" do

        let(:metadata) do
          described_class.new(
            relation: Mongoid::Relations::Referenced::Many,
            class_name: "::Person"
          )
        end

        it "returns the stripped class name" do
          expect(metadata.class_name).to eq("Person")
        end
      end

      context "when the class name has no prefix" do

        let(:metadata) do
          described_class.new(
            relation: Mongoid::Relations::Referenced::Many,
            class_name: "Person"
          )
        end

        it "constantizes the class name" do
          expect(metadata.class_name).to eq("Person")
        end
      end
    end

    context "when no class_name provided" do

      context "when inverse_class_name is provided" do

        context "when inverse_class_name is a simple class name" do

          context "when association name is singular" do

            let(:relation) do
              Mongoid::Relations::Embedded::One
            end

            let(:metadata) do
              described_class.new(name: :name, relation: relation, inverse_class_name: "Person")
            end

            it "classifies and constantizes the association name and adds the module" do
              expect(metadata.class_name).to eq("Name")
            end
          end

          context "when association name is plural" do

            let(:relation) do
              Mongoid::Relations::Embedded::Many
            end

            let(:metadata) do
              described_class.new(name: :addresses, relation: relation, inverse_class_name: "Person")
            end

            it "classifies and constantizes the association name and adds the module" do
              expect(metadata.class_name).to eq("Address")
            end
          end

        end

        context "when inverse_class_name is a class name in a module" do

          context "when association name is singular" do

            let(:relation) do
              Mongoid::Relations::Embedded::One
            end

            let(:metadata) do
              described_class.new(name: :apple, relation: relation, inverse_class_name: "Fruits::Banana")
            end

            it "classifies and constantizes the association name and adds the module" do
              expect(metadata.class_name).to eq("Fruits::Apple")
            end
          end

          context "when association name is plural" do

            let(:relation) do
              Mongoid::Relations::Embedded::Many
            end

            let(:metadata) do
              described_class.new(name: :apples, relation: relation, inverse_class_name: "Fruits::Banana")
            end

            it "classifies and constantizes the association name and adds the module" do
              expect(metadata.class_name).to eq("Fruits::Apple")
            end
          end

        end
      end

      context "when no inverse_class_name is provided" do

        context "when association name is singular" do

          let(:relation) do
            Mongoid::Relations::Embedded::One
          end

          let(:metadata) do
            described_class.new(name: :name, relation: relation)
          end

          it "classifies and constantizes the association name" do
            expect(metadata.class_name).to eq("Name")
          end
        end

        context "when association name is plural" do

          let(:relation) do
            Mongoid::Relations::Embedded::Many
          end

          let(:metadata) do
            described_class.new(name: :addresses, relation: relation)
          end

          it "classifies and constantizes the association name" do
            expect(metadata.class_name).to eq("Address")
          end
        end
      end
    end
  end

  context "when the association is polymorphic" do

    let(:metadata) do
      described_class.new(
        name: :ratable,
        relation: Mongoid::Relations::Referenced::In,
        polymorphic: true,
        inverse_class_name: "Rating"
      )
    end

    it "returns the polymorphic class name" do
      expect(metadata.class_name).to eq("Ratable")
    end
  end

  describe "#destructive?" do

    context "when the relation has a destructive dependent option" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::Many,
          dependent: :destroy
        )
      end

      it "returns true" do
        expect(metadata).to be_destructive
      end
    end

    context "when no dependent option" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        expect(metadata).to_not be_destructive
      end
    end
  end

  describe "#embedded?" do

    context "when the relation is embedded" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Embedded::Many
        )
      end

      it "returns true" do
        expect(metadata).to be_embedded
      end
    end

    context "when the relation is not embedded" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        expect(metadata).to_not be_embedded
      end
    end
  end

  describe "#extension" do

    let(:metadata) do
      described_class.new(
        relation: Mongoid::Relations::Referenced::Many,
        extend: :value
      )
    end

    it "returns the extend property" do
      expect(metadata.extension).to eq(:value)
    end
  end

  describe "#extension?" do

    context "when an extends property exists" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::Many,
          extend: :value
        )
      end

      it "returns true" do
        expect(metadata.extension?).to be true
      end
    end

    context "when the extend option is nil" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      it "returns false" do
        expect(metadata.extension?).to be false
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
                name: :person,
                relation: Mongoid::Relations::Referenced::In
              )
            end

            it "returns the foreign_key" do
              expect(metadata.foreign_key).to eq("person_id")
            end
          end

          context "when providing a class name" do

            let(:metadata) do
              described_class.new(
                name: :person,
                relation: Mongoid::Relations::Referenced::In,
                class_name: "TheseAreNotTheDriods"
              )
            end

            it "returns the foreign_key" do
              expect(metadata.foreign_key).to eq("person_id")
            end
          end

          context "when the class is namespaces" do

            let(:metadata) do
              described_class.new(
                name: :apple,
                relation: Mongoid::Relations::Referenced::In,
                class_name: "Fruits::Apple"
              )
            end

            it "returns the foreign_key without the module name" do
              expect(metadata.foreign_key).to eq("apple_id")
            end
          end
        end

        context "when references and referenced in many" do

          let(:metadata) do
            described_class.new(
              name: :people,
              relation: Mongoid::Relations::Referenced::ManyToMany
            )
          end

          it "returns the foreign_key" do
            expect(metadata.foreign_key).to eq("person_ids")
          end

          context "given a specific foreign key" do

            let(:metadata) do
              described_class.new(
                name: :follower,
                foreign_key: :follower_list,
                relation: Mongoid::Relations::Referenced::ManyToMany
              )
            end

            it "returns the foreign_key" do
              expect(metadata.foreign_key).to eq("follower_list")
            end
          end

          context "using name as foreign key" do

            let(:metadata) do
              described_class.new(
                name: :followers,
                class_name: "Person",
                relation: Mongoid::Relations::Referenced::ManyToMany
              )
            end

            it "returns the foreign_key" do
              expect(metadata.foreign_key).to eq("follower_ids")
            end
          end

          context "when the class is namespaced" do

            let(:metadata) do
              described_class.new(
                name: :bananas,
                relation: Mongoid::Relations::Referenced::ManyToMany,
                inverse_class_name: "Fruits::Apple",
                class_name: "Fruits::Banana"
              )
            end

            it "returns the foreign_key without the module name" do
              expect(metadata.foreign_key).to eq("banana_ids")
            end

            it "returns the inverse_foreign_key without the module name" do
              expect(metadata.inverse_foreign_key).to eq("apple_ids")
            end
          end
        end
      end

      context "when the relation does not store a foreign key" do

        context "when references one" do

          let(:metadata) do
            described_class.new(
              name: :post,
              relation: Mongoid::Relations::Referenced::One,
              inverse_class_name: "Person"
            )
          end

          it "returns the inverse foreign key" do
            expect(metadata.foreign_key).to eq("person_id")
          end
        end

        context "when references many" do

          context "when an inverse_of is defined" do

            let(:metadata) do
              described_class.new(
                name: :created_streets,
                relation: Mongoid::Relations::Referenced::Many,
                inverse_class_name: "House",
                inverse_of: :creator
              )
            end

            it "returns the inverse_of plus suffix" do
              expect(metadata.foreign_key).to eq("creator_id")
            end
          end

          context "when the class is not namespaced" do

            let(:metadata) do
              described_class.new(
                name: :posts,
                relation: Mongoid::Relations::Referenced::Many,
                inverse_class_name: "Person"
              )
            end

            it "returns the inverse foreign key" do
              expect(metadata.foreign_key).to eq("person_id")
            end
          end

          context "when the class is namespaced" do

            context "when name doesnt include namespace" do

              let(:metadata) do
                described_class.new(
                  name: :bananas,
                  relation: Mongoid::Relations::Referenced::Many,
                  inverse_class_name: "Fruits::Apple",
                  class_name: "Fruits::Banana"
                  )
              end

              it "returns the foreign_key without the module name" do
                expect(metadata.foreign_key).to eq("apple_id")
              end
            end

            context "when name include namespace" do

              let(:metadata) do
                described_class.new(
                  name: :fruits_melons,
                  relation: Mongoid::Relations::Referenced::Many,
                  inverse_class_name: "Fruits::Apple",
                  class_name: "Fruits::Melon"
                  )
              end

              it "returns the foreign_key with the module name" do
                expect(metadata.foreign_key).to eq("fruit_apple_id")
              end
            end
          end
        end

        context "when embeds one" do
          let(:metadata) do
            described_class.new(
              name: :post,
              relation: Mongoid::Relations::Embedded::One,
              inverse_class_name: "Person"
            )
          end

          it "returns a nil foreign key" do
            expect(metadata.foreign_key).to be_nil
          end
        end
      end
    end

    context "when a foreign_key was defined" do

      let(:metadata) do
        described_class.new(
          name: :person,
          relation: Mongoid::Relations::Referenced::ManyToMany,
          foreign_key: "blog_post_id"
        )
      end

      it "returns the foreign_key" do
        expect(metadata.foreign_key).to eq("blog_post_id")
      end
    end
  end

  describe "#foreign_key_default" do

    context "when the relation stores keys in an array" do

      let(:metadata) do
        described_class.new(
          name: :preferences,
          relation: Mongoid::Relations::Referenced::ManyToMany,
          foreign_key: "preference_ids"
        )
      end

      it "returns an empty array" do
        expect(metadata.foreign_key_default).to be_empty
      end
    end

    context "when the relation stores a single key" do

      let(:metadata) do
        described_class.new(
          name: :person,
          relation: Mongoid::Relations::Referenced::In,
          foreign_key: "person_id"
        )
      end

      it "returns an empty array" do
        expect(metadata.foreign_key_default).to be_nil
      end
    end
  end

  describe "#foreign_key_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :person,
          relation: Mongoid::Relations::Referenced::In,
          foreign_key: "person_id"
        )
      end

      it "returns the foreign_key plus =" do
        expect(metadata.foreign_key_setter).to eq("person_id=")
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :ratings,
          relation: Mongoid::Relations::Referenced::Many,
          as: :ratable,
          inverse_class_name: "Movie"
        )
      end

      it "returns the polymorphic foreign_key plus =" do
        expect(metadata.foreign_key_setter).to eq("ratable_id=")
      end
    end
  end

  describe "#inverse_type" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :person,
          relation: Mongoid::Relations::Referenced::In,
          foreign_key: "person_id"
        )
      end

      it "returns nil" do
        expect(metadata.inverse_type).to be_nil
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :ratable,
          relation: Mongoid::Relations::Referenced::In,
          polymorphic: true,
          inverse_class_name: "Rating"
        )
      end

      it "returns the polymorphic name plus type" do
        expect(metadata.inverse_type).to eq("ratable_type")
      end
    end
  end

  describe "#inverse_type_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :person,
          relation: Mongoid::Relations::Referenced::In,
          foreign_key: "person_id"
        )
      end

      it "returns nil" do
        expect(metadata.inverse_type_setter).to be_nil
      end
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :ratable,
          relation: Mongoid::Relations::Referenced::In,
          polymorphic: true,
          inverse_class_name: "Rating"
        )
      end

      it "returns the inverse type plus =" do
        expect(metadata.inverse_type_setter).to eq("ratable_type=")
      end
    end
  end

  describe "#inverses" do

    context "when the relation is polymorphic" do

      context "when an inverse_of is defined" do

        let(:metadata) do
          described_class.new(
            name: :ratable,
            relation: Mongoid::Relations::Referenced::In,
            polymorphic: true,
            inverse_of: "my_ratings"
          )
        end

        it "returns only the inverse_of" do
          expect(metadata.inverses(nil)).to eq([ "my_ratings" ])
        end
      end
    end
  end

  describe "#indexed?" do

    context "when an index property exists" do

      let(:metadata) do
        described_class.new(
          index: true,
          relation: Mongoid::Relations::Referenced::In
        )
      end

      it "returns true" do
        expect(metadata.indexed?).to be true
      end
    end

    context "when the index option is nil" do

      let(:metadata) do
        described_class.new(
          relation: Mongoid::Relations::Referenced::In
        )
      end

      it "returns false" do
        expect(metadata.indexed?).to be false
      end
    end

    context "when the index option is false" do

      let(:metadata) do
        described_class.new(
          index: false,
          relation: Mongoid::Relations::Referenced::In
        )
      end

      it "returns false" do
        expect(metadata.indexed?).to be false
      end
    end
  end

  describe "#inverse" do

    context "when an inverse relation exists" do

      context "when the inverse has a foreign key match" do

        let(:metadata) do
          User.reflect_on_association(:account)
        end

        it "returns the name of the inverse with the matching foreign_key" do
          expect(metadata.inverse).to eq(:creator)
        end
      end

      context "when multiple relations against the same class exist" do

        context "when not polymorphic" do

          let(:metadata) do
            described_class.new(
              inverse_class_name: "User",
              name: :shop,
              relation: Mongoid::Relations::Referenced::One
            )
          end

          it "returns the name of the inverse with the matching inverse of" do
            expect(metadata.inverse).to eq(:user)
          end
        end

        context "when polymorphic" do

          let(:metadata) do
            described_class.new(
              name: :left_eye,
              as: :eyeable,
              inverse_class_name: "Face",
              class_name: "Eye",
              relation: Mongoid::Relations::Referenced::One
            )
          end

          it "returns the name of the relation" do
            expect(metadata.inverse).to eq(:eyeable)
          end
        end

        context "when polymorphic on the child" do

          let(:metadata) do
            described_class.new(
              name: :eyeable,
              polymorphic: true,
              inverse_class_name: "Eye",
              relation: Mongoid::Relations::Referenced::In
            )
          end

          it "returns nil" do
            expect(metadata.inverse(Face.new)).to be_nil
          end
        end
      end

      context "when inverse_of is defined" do

        context "when inverse_of is nil" do

          let(:metadata) do
            described_class.new(
              inverse_of: nil,
              relation: Mongoid::Relations::Referenced::In
            )
          end

          it "returns nil" do
            expect(metadata.inverse).to be_nil
          end
        end

        context "when inverse_of is a symbol" do

          let(:metadata) do
            described_class.new(
              inverse_of: :crazy_name,
              relation: Mongoid::Relations::Referenced::In
            )
          end

          it "returns the name of the inverse_of property" do
            expect(metadata.inverse).to eq(:crazy_name)
          end
        end
      end

      context "when not polymorphic" do

        let(:metadata) do
          described_class.new(
            name: :pet,
            class_name: "Animal",
            inverse_class_name: "Person",
            relation: Mongoid::Relations::Referenced::In
          )
        end

        it "returns the name of the relation" do
          expect(metadata.inverse).to eq(:person)
        end
      end

      context "when polymorphic" do

        let(:metadata) do
          described_class.new(
            name: :addresses,
            as: :addressable,
            inverse_class_name: "Person",
            relation: Mongoid::Relations::Referenced::Many
          )
        end

        it "returns the name of the relation" do
          expect(metadata.inverse).to eq(:addressable)
        end
      end

      context "when polymorphic on the child" do

        let(:metadata) do
          described_class.new(
            name: :addressable,
            polymorphic: true,
            inverse_class_name: "Address",
            relation: Mongoid::Relations::Referenced::In
          )
        end

        it "returns the name of the relation" do
          expect(metadata.inverse(Person.new)).to eq(:addresses)
        end
      end

      context "when in a cyclic relation" do

        context "when the base name is included in the plural form" do

          let(:metadata) do
            described_class.new(
              name: :parent_role,
              class_name: "Role",
              inverse_class_name: "Role",
              relation: Mongoid::Relations::Embedded::In,
              cyclic: true
            )
          end

          it "returns the name of the relation" do
            expect(metadata.inverse(Role.new)).to eq(:child_roles)
          end
        end

        context "when the base name is not included in the plural form" do

          let(:metadata) do
            described_class.new(
              name: :parent_entry,
              class_name: "Entry",
              inverse_class_name: "Entry",
              relation: Mongoid::Relations::Embedded::In,
              cyclic: true
            )
          end

          it "returns the name of the relation" do
            expect(metadata.inverse(Entry.new)).to eq(:child_entries)
          end
        end
      end
    end
  end

  context "#inverse_foreign_key" do

    context "when the inverse foreign key is not defined" do

      let(:metadata) do
        described_class.new(
          name: :preferences,
          index: true,
          dependent: :nullify,
          relation: Mongoid::Relations::Referenced::ManyToMany,
          inverse_class_name: "Person"
        )
      end

      it "returns the inverse class name plus suffix" do
        expect(metadata.inverse_foreign_key).to eq("person_ids")
      end
    end

    context "when the inverse_of is nil" do

      let(:metadata) do
        described_class.new(
          name: :blogs,
          class_name: "Blog",
          relation: Mongoid::Relations::Referenced::ManyToMany,
          inverse_of: nil
        )
      end

      it "returns nil" do
        expect(metadata.inverse_foreign_key).to be_nil
      end
    end
  end

  context "#inverse_klass" do

    let(:metadata) do
      described_class.new(
        inverse_class_name: "Person",
        relation: Mongoid::Relations::Referenced::In
      )
    end

    it "constantizes the inverse_class_name" do
      expect(metadata.inverse_klass).to eq(Person)
    end
  end

  context "#inverse_setter" do

    context "when the relation is not polymorphic" do

      let(:metadata) do
        described_class.new(
          name: :pet,
          class_name: "Animal",
          inverse_class_name: "Person",
          relation: Mongoid::Relations::Referenced::In
        )
      end

      it "returns a string for the setter" do
        expect(metadata.inverse_setter).to eq("person=")
      end
    end

    context "when the relation is polymorphic" do

      context "when multiple relations against the same class exist" do

        context "when a referenced in" do

          let(:metadata) do
            described_class.new(
              name: :eyeable,
              polymorphic: true,
              relation: Mongoid::Relations::Referenced::In
            )
          end

          let(:other) do
            Face.new
          end

          it "returns nil" do
            expect(metadata.inverse_setter(other)).to be_nil
          end
        end

        context "when a references many" do

          let(:metadata) do
            described_class.new(
              name: :blue_eyes,
              inverse_class_name: "EyeBowl",
              as: :eyeable,
              relation: Mongoid::Relations::Referenced::Many
            )
          end

          it "returns a string for the setter" do
            expect(metadata.inverse_setter).to eq("eyeable=")
          end
        end
      end

      context "when a referenced in" do

        let(:metadata) do
          described_class.new(
            name: :ratable,
            inverse_class_name: "Rating",
            polymorphic: true,
            relation: Mongoid::Relations::Referenced::In
          )
        end

        let(:other) do
          Movie.new
        end

        it "returns a string for the setter" do
          expect(metadata.inverse_setter(other)).to eq("ratings=")
        end
      end

      context "when a references many" do

        let(:metadata) do
          described_class.new(
            name: :ratings,
            inverse_class_name: "Rating",
            as: :ratable,
            relation: Mongoid::Relations::Referenced::Many
          )
        end

        it "returns a string for the setter" do
          expect(metadata.inverse_setter).to eq("ratable=")
        end
      end
    end
  end

  context "#key" do

    context "when relation is embedded" do

      let(:metadata) do
        described_class.new(
          name: :addresses,
          relation: Mongoid::Relations::Embedded::Many
        )
      end

      it "returns the name as a string" do
        expect(metadata.key).to eq("addresses")
      end

      context "with a store_as option defined" do

        let(:metadata) do
          described_class.new(
            name: :comment,
            relation: Mongoid::Relations::Embedded::Many,
            store_as: "user_comments"
          )
        end

        it "return the name define by store_as option" do
          expect(metadata.key).to eq("user_comments")
        end
      end
    end

    context "when relation is referenced" do

      context "when relation stores foreign_key" do

        context "when the relation is not polymorphic" do

          let(:metadata) do
            described_class.new(
              name: :posts,
              relation: Mongoid::Relations::Referenced::ManyToMany
            )
          end

          it "returns the foreign_key" do
            expect(metadata.key).to eq("post_ids")
          end
        end

        context "when the relation is polymorphic" do

          let(:metadata) do
            described_class.new(
              name: :ratable,
              relation: Mongoid::Relations::Referenced::In,
              polymorphic: true
            )
          end

          it "returns the polymorphic foreign_key" do
            expect(metadata.key).to eq("ratable_id")
          end
        end
      end

      context "when relation does not store a foreign_key" do

        let(:metadata) do
          described_class.new(
            name: :addresses,
            relation: Mongoid::Relations::Referenced::Many,
            inverse_class_name: "Person"
          )
        end

        it "returns _id" do
          expect(metadata.key).to eq("_id")
        end
      end
    end
  end

  describe "#options" do

    let(:metadata) do
      described_class.new(
        order: :rating.asc,
        relation: Mongoid::Relations::Referenced::Many
      )
    end

    it "returns self" do
      expect(metadata.options).to eq(metadata)
    end
  end

  describe "#order" do

    let(:metadata) do
      described_class.new(
        order: :rating.asc,
        relation: Mongoid::Relations::Referenced::Many
      )
    end

    it "returns order criteria" do
      expect(metadata.order).to eq(:rating.asc)
    end
  end

  describe "#klass" do

    context "when the class name is not namespaced" do

      let(:metadata) do
        described_class.new(
          class_name: "Address",
          relation: Mongoid::Relations::Embedded::Many
        )
      end

      it "constantizes the class_name" do
        expect(metadata.klass).to eq(Address)
      end
    end

    context "when the class name is prepended with ::" do

      let(:metadata) do
        described_class.new(
          class_name: "::Address",
          relation: Mongoid::Relations::Embedded::Many
        )
      end

      it "returns the class" do
        expect(metadata.klass).to eq(Address)
      end
    end
  end

  describe "#many?" do

    context "when the relation is a many" do

      let(:metadata) do
        described_class.new(relation: Mongoid::Relations::Embedded::Many)
      end

      it "returns true" do
        expect(metadata).to be_many
      end
    end

    context "when the relation is not a many" do

      let(:metadata) do
        described_class.new(relation: Mongoid::Relations::Embedded::One)
      end

      it "returns false" do
        expect(metadata).to_not be_many
      end
    end
  end

  describe "#macro" do

    let(:metadata) do
      described_class.new(relation: Mongoid::Relations::Embedded::One)
    end

    it "returns the macro from the relation" do
      expect(metadata.macro).to eq(:embeds_one)
    end
  end

  describe "#nested_builder" do

    let(:metadata) do
      described_class.new(relation: Mongoid::Relations::Embedded::One)
    end

    let(:attributes) do
      {}
    end

    let(:options) do
      {}
    end

    it "returns the nested builder from the relation" do
      expect(
        metadata.nested_builder(attributes, options)
      ).to be_a_kind_of(Mongoid::Relations::Builders::NestedAttributes::One)
    end
  end

  describe "#primary_key" do

    context "when no primary key exists" do

      let(:metadata) do
        described_class.new(
          name: :person,
          inverse_class_name: "Person",
          relation: Mongoid::Relations::Referenced::In
        )
      end

      it "returns _id" do
        expect(metadata.primary_key).to eq("_id")
      end
    end

    context "when a primary key exists" do

      let(:metadata) do
        described_class.new(
          name: :person,
          inverse_class_name: "Person",
          relation: Mongoid::Relations::Referenced::In,
          primary_key: :something_id
        )
      end

      it "returns the primary key" do
        expect(metadata.primary_key).to eq("something_id")
      end
    end
  end

  describe "#validate?" do

    context "when validate is provided" do

      context "when validate is true" do

        let(:metadata) do
          described_class.new(
            name: :posts,
            inverse_class_name: "Post",
            relation: Mongoid::Relations::Referenced::Many,
            validate: true
          )
        end

        it "returns true" do
          expect(metadata.validate?).to be true
        end
      end

      context "when validate is false" do

        let(:metadata) do
          described_class.new(
            name: :posts,
            inverse_class_name: "Post",
            relation: Mongoid::Relations::Referenced::Many,
            validate: false
          )
        end

        it "returns false" do
          expect(metadata.validate?).to be false
        end
      end
    end

    context "when validate is not provided" do

      let(:metadata) do
        described_class.new(
          name: :posts,
          inverse_class_name: "Post",
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      it "returns the relation default" do
        expect(metadata.validate?).to be true
      end
    end
  end

  describe "#store_as" do

    context "when store_as is define" do

      let(:metadata) do
        described_class.new(
          name: :comment,
          relation: Mongoid::Relations::Embedded::Many,
          store_as: 'user_comments'
        )
      end

      it "returns the value" do
        expect(metadata.store_as).to eq("user_comments")
      end
    end

    context "when is not define" do

      let(:metadata) do
        described_class.new(
          name: :comments,
          relation: Mongoid::Relations::Embedded::Many,
        )
      end

      it "returns false" do
        expect(metadata.store_as).to eq("comments")
      end
    end
  end

  describe "#determine_inverse_relation" do

    let(:class_name) do
      "Person"
    end

    let(:metadata) do
      described_class.new(
        relation: Mongoid::Relations::Referenced::In,
        inverse_class_name: "Drug",
        class_name: class_name,
        name: :person
      )
    end

    let(:inverse_relation) do
      metadata.send(:determine_inverse_relation)
    end

    context "when no match" do

      let(:class_name) do
        "Slave"
      end

      it "returns nil" do
        expect(inverse_relation).to be_nil
      end
    end

    context "when one match" do

      it "returns correct relation" do
        expect(inverse_relation).to eq(:drugs)
      end
    end

    context "when multiple matches" do

      context "when the inverse_of is not nil" do

        before do
          class_name.constantize.has_many(:evil_drugs, class_name: "Drug")
        end

        after do
          class_name.constantize.relations.delete("evil_drugs")
          Person.reset_callbacks(:validate)
        end

        it "raises AmbiguousRelationship" do
          expect {
            inverse_relation
          }.to raise_error(Mongoid::Errors::AmbiguousRelationship)
        end
      end

      context "when the inverse_of is nil" do

        before do
          class_name.constantize.has_many(:evil_drugs, class_name: "Drug", inverse_of: nil)
        end

        after do
          class_name.constantize.relations.delete("evil_drugs")
          Person.reset_callbacks(:validate)
        end

        it "returns the non-nil inverses" do
          expect(inverse_relation).to eq(:drugs)
        end
      end
    end
  end

  describe "touchable?" do

    context "when touch is false" do

      let(:metadata) do
        described_class.new(
          name: :versions,
          relation: Mongoid::Relations::Referenced::In,
          touch: false
        )
      end

      it "returns false" do
        expect(metadata).to_not be_touchable
      end
    end

    context "when touch is true" do

      let(:metadata) do
        described_class.new(
          name: :versions,
          relation: Mongoid::Relations::Referenced::In,
          touch: true
        )
      end

      it "returns true" do
        expect(metadata).to be_touchable
      end
    end

    context "when touch is nil" do

      let(:metadata) do
        described_class.new(
          name: :versions,
          relation: Mongoid::Relations::Referenced::In,
        )
      end

      it "returns false" do
        expect(metadata).to_not be_touchable
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
            relation: Mongoid::Relations::Embedded::Many
          )
        end

        it "returns the #{property} property" do
          expect(metadata.send(property)).to eq(:value)
        end
      end

      describe "##{property}?" do

        context "when a #{property} property exists" do

          let(:metadata) do
            described_class.new(
              property.to_sym => :value,
              relation: Mongoid::Relations::Embedded::Many
            )
          end

          it "returns true" do
            expect(metadata.send("#{property}?")).to be true
          end
        end

        context "when the #{property} property is nil" do

          let(:metadata) do
            described_class.new(
              relation: Mongoid::Relations::Embedded::Many
            )
          end

          it "returns false" do
            expect(metadata.send("#{property}?")).to be false
          end
        end
      end
    end
  end

end
