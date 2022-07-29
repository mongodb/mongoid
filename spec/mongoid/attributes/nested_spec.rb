# frozen_string_literal: true

require "spec_helper"
require_relative '../association/referenced/has_many_models'
require_relative '../association/referenced/has_and_belongs_to_many_models'
require_relative './nested_spec_models'

describe Mongoid::Attributes::Nested do

  describe ".accepts_nested_attributes_for" do

    context "when the autosave option is not defined" do

      let(:person) do
        Person.new
      end

      before do
        Person.accepts_nested_attributes_for :favorites
        Person.accepts_nested_attributes_for :children
      end

      after do
        Person.send(:undef_method, :favorites_attributes=)
        Person.send(:undef_method, :children_attributes=)
        Person.nested_attributes.clear
      end

      it "adds a method for handling the attributes" do
        expect(person).to respond_to(:favorites_attributes=)
      end

      it "does not autosave if the association is embedded" do
        expect(person).not_to respond_to(:autosave_documents_for_favorites)
      end

      it "autosaves if the association is not embedded" do
        expect(person).to respond_to(:autosave_documents_for_children)
      end

      it "adds the method name to the nested attributes list" do
        expect(Person.nested_attributes).to eq({
          "favorites_attributes" => "favorites_attributes=",
          "children_attributes" => "children_attributes="
        })
      end
    end

    context "when autosave is explicitly false" do

      before do
        Account.accepts_nested_attributes_for :alerts
      end

      after do
        Account.send(:undef_method, :alerts_attributes=)
        Account.nested_attributes.clear
      end

      let(:association) do
        Account.reflect_on_association(:alerts)
      end

      it "keeps autosave set to false" do
        expect(association).to_not be_autosave
      end
    end
  end

  describe "#initialize" do

    context "when the relation is an embeds one" do

      before do
        Person.send(:undef_method, :name_attributes=)
        Person.accepts_nested_attributes_for :name
      end

      let(:person) do
        Person.new(name_attributes: { first_name: "Johnny" })
      end

      it "sets the nested attributes" do
        expect(person.name.first_name).to eq("Johnny")
      end
    end

    context "when the relation is an embeds many" do

      before do
        Person.send(:undef_method, :addresses_attributes=)
        Person.accepts_nested_attributes_for :addresses
      end

      let(:person) do
        Person.new(addresses_attributes: { "1" => { street: "Alexanderstr" }})
      end

      it "sets the nested attributes" do
        expect(person.addresses.first.street).to eq("Alexanderstr")
      end

      context "when there are 10 or more child records" do

        let(:person) do
          Person.new(addresses: addresses)
        end

        let(:addresses) do
          ('0'..'10').inject({}) do |addresses,i|
            addresses.merge(i => {number: i})
          end
        end

        it "preserves the order of the children" do
          expect(person.addresses.map(&:number)).to eq((0..10).to_a)
        end
      end
    end

    context "when the association is referenced in and polymorphic" do

      it "infers the class name of the polymorphic with the inverse type" do
        expect {
          Post.create!(
            title: "Some title",
            posteable_type: "Sandwich",
            posteable_attributes: { name: 'Grilled Cheese' }
          )
        }.not_to raise_error
      end
    end

    context "when the relation is an embedded in" do

      before do
        Video.accepts_nested_attributes_for :person
      end

      let(:video) do
        Video.new(person_attributes: { title: "Sir" })
      end

      it "sets the nested attributes" do
        expect(video.person.title).to eq("Sir")
      end
    end

    context "when the relation is a references one" do

      before do
        Person.send(:undef_method, :game_attributes=)
        Person.accepts_nested_attributes_for :game
      end

      let(:person) do
        Person.new(game_attributes: { name: "Tron" })
      end

      it "sets the nested attributes" do
        expect(person.game.name).to eq("Tron")
      end
    end

    context "when the relation is a references many" do

      before do
        Person.send(:undef_method, :posts_attributes=)
        Person.accepts_nested_attributes_for :posts
      end

      let(:person) do
        Person.new(posts_attributes: { "1" => { title: "First" }})
      end

      it "sets the nested attributes" do
        expect(person.posts.first.title).to eq("First")
      end
    end

    context "when the relation is a references and referenced in many" do

      before do
        Person.send(:undef_method, :preferences_attributes=)
        Person.accepts_nested_attributes_for :preferences
      end

      let(:person) do
        Person.new(preferences_attributes: { "1" => { name: "First" }})
      end

      it "sets the nested attributes" do
        expect(person.preferences.first.name).to eq("First")
      end

      context "when adding existing document to a relation" do
        let(:preference) { Preference.create!(name: 'sample preference') }
        let(:person) do
          Person.new(
            preferences_attributes: { 0 => { id: preference.id, name: preference.name } }
          )
        end

        it "sets the nested attributes" do
          expect(person.preferences.map(&:name)).to eq([preference.name])
        end

        it "updates attributes of existing document which is added to relation" do
          preference_name = 'updated preference'
          person = Person.new(
            preferences_attributes: { 0 => { id: preference.id, name: preference_name } }
          )
          expect(person.preferences.map(&:name)).to eq([preference_name])
        end
      end
    end

    context "when the relation is a referenced in" do

      before do
        Post.accepts_nested_attributes_for :person, autosave: false
      end

      after do
        Post.send(:undef_method, :person_attributes=)
        Post.nested_attributes.clear
      end

      let(:post) do
        Post.new(person_attributes: { title: "Sir" })
      end

      it "sets the nested attributes" do
        expect(post.person.title).to eq("Sir")
      end
    end
  end

  describe "*_attributes=" do

    context "when the parent document is new" do

      context "when the relation is an embeds one" do

        context "when the parent document is persisted" do

          let(:person) do
            Person.create!
          end

          before do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name, allow_destroy: true
          end

          after do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name
          end

          context "when setting the child attributes" do

            before do
              person.name_attributes = { last_name: "Fischer" }
            end

            it "sets the child document" do
              expect(person.name.last_name).to eq("Fischer")
            end

            it "does not persist the child document" do
              expect(person.name).to_not be_persisted
            end

            context "when saving the parent" do

              before do
                person.save!
                person.reload
              end

              it "persists the child document" do
                expect(person.name).to be_persisted
              end
            end
          end
        end

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for \
              :name, reject_if: ->(attrs){ attrs[:first_name].blank? }
          end

          after do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name
          end

          context "when the attributes match" do

            before do
              person.name_attributes = { last_name: "Lang" }
            end

            it "does not add the document" do
              expect(person.name).to be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.name_attributes = { first_name: "Lang" }
            end

            it "adds the document" do
              expect(person.name.first_name).to eq("Lang")
            end
          end
        end

        context "when :reject_if => :all_blank is specified" do

          context "when the relation is not autobuilding" do

            before do
              Person.send(:undef_method, :name_attributes=)
              Person.accepts_nested_attributes_for \
                :name, reject_if: :all_blank
            end

            after do
              Person.send(:undef_method, :name_attributes=)
              Person.accepts_nested_attributes_for :name
            end

            context "when all attributes are empty" do

              before do
                person.name_attributes = { last_name: "" }
              end

              it "does not add the document" do
                expect(person.name).to be_nil
              end
            end

            context "when an attribute is non-empty" do

              before do
                person.name_attributes = { first_name: "Lang" }
              end

              it "adds the document" do
                expect(person.name.first_name).to eq("Lang")
              end
            end
          end

          context "when the relation is autobuilding" do

            before do
              Product.accepts_nested_attributes_for :seo, reject_if: :all_blank
            end

            after do
              Product.send(:undef_method, :seo_attributes=)
            end

            context "when all attributes are empty" do

              let(:product) do
                Product.create!(name: "testing")
              end

              it "does not add the document" do
                expect(product.seo).to_not be_persisted
              end
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.name_attributes = { first_name: "Leo" }
            end

            it "builds a new document" do
              expect(person.name.first_name).to eq("Leo")
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, allow_destroy: true
              end

              after do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              context "when destroy is a symbol" do

                before do
                  person.name_attributes = { first_name: "Leo", _destroy: "1" }
                end

                it "does not build the document" do
                  expect(person.name).to be_nil
                end
              end

              context "when destroy is a string" do

                before do
                  person.name_attributes = { first_name: "Leo", "_destroy" => "1" }
                end

                it "does not build the document" do
                  expect(person.name).to be_nil
                end
              end
            end

            context "when allow_destroy is false" do

              before do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, allow_destroy: false
              end

              after do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              before do
                person.name_attributes = { first_name: "Leo", _destroy: "1" }
              end

              it "builds the document" do
                expect(person.name.first_name).to eq("Leo")
              end
            end
          end

          context "with empty attributes" do

            before do
              person.name_attributes = {}
            end

            it "does not build the document" do
              expect(person.name).to be_nil
            end
          end

          context "when there is an existing document" do

            context "with no destroy attribute" do

              before do
                person.name = Name.new(first_name: "Michael")
                person.name_attributes = { first_name: "Jack" }
              end

              it "replaces the document" do
                expect(person.name.first_name).to eq("Jack")
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(first_name: "Michael")
                  person.name_attributes = { first_name: "Jack", _destroy: "1" }
                end

                it "does not replace the document" do
                  expect(person.name.first_name).to eq("Michael")
                end
              end

              context "when allow_destroy is false" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(first_name: "Michael")
                  person.name_attributes = { first_name: "Jack", _destroy: "1" }
                end

                it "replaces the document" do
                  expect(person.name.first_name).to eq("Jack")
                end
              end
            end
          end
        end

        context "when an id is passed" do

          context "when there is an existing record" do

            let(:name) do
              Name.new(first_name: "Joe")
            end

            before do
              person.name = name
            end

            context "when the id matches" do

              context "when passed keys as symbols" do

                before do
                  person.name_attributes =
                    { id: name.id.to_s, first_name: "Bob" }
                end

                it "updates the existing document" do
                  expect(person.name.first_name).to eq("Bob")
                end
              end

              context "when passed keys as strings" do

                before do
                  person.name_attributes =
                    { "id" => name.id.to_s, "first_name" => "Bob" }
                end

                it "updates the existing document" do
                  expect(person.name.first_name).to eq("Bob")
                end
              end

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    context "when the document has no callbacks" do

                      before do
                        person.name_attributes =
                          { id: name.id, _destroy: truth }
                      end

                      it "destroys the existing document" do
                        expect(person.name).to be_nil
                      end
                    end

                    context "when the document has destroy callbacks" do

                      before do
                        PetOwner.accepts_nested_attributes_for :pet, allow_destroy: true
                      end

                      after do
                        PetOwner.send(:undef_method, :pet_attributes=)
                      end

                      let(:owner) do
                        PetOwner.create!
                      end

                      let!(:pet) do
                        owner.create_pet
                      end

                      before do
                        owner.pet_attributes = { id: pet.id, _destroy: truth }
                        owner.save!
                      end

                      it "destroys the existing document" do
                        expect(owner.pet).to be_nil
                      end

                      it "runs the destroy callbacks" do
                        expect(pet.destroy_flag).to be true
                      end
                    end
                  end
                end

                [ nil, 0, "0", false, "false" ].each do |falsehood|

                  context "when passed #{falsehood} with destroy" do

                    before do
                      person.name_attributes =
                        { id: name.id, _destroy: falsehood }
                    end

                    it "does not destroy the existing document" do
                      expect(person.name).to eq(name)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.name_attributes =
                      { id: name.id, _destroy: true }
                  end

                  it "does not destroy the document" do
                    expect(person.name).to eq(name)
                  end
                end
              end

              context "when update only is true" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for \
                    :name,
                    update_only: true,
                    allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when the id matches" do

                  before do
                    person.name_attributes =
                      { id: name.id, first_name: "Ro" }
                  end

                  it "updates the existing document" do
                    expect(person.name.first_name).to eq("Ro")
                  end
                end

                context "when the id does not match" do

                  before do
                    person.name_attributes =
                      { id: BSON::ObjectId.new.to_s, first_name: "Durran" }
                  end

                  it "updates the existing document" do
                    expect(person.name.first_name).to eq("Durran")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.name_attributes =
                      { id: name.id, _destroy: true }
                  end

                  it "destroys the existing document" do
                    expect(person.name).to be_nil
                  end
                end
              end

              context "when ids are ObjectId strings" do

                let(:quiz) do
                  person.quiz = Quiz.new(topic: "Math")
                end

                before do
                  person.quiz_attributes = {
                    "id" => quiz.id.to_s, topic: "English"
                  }
                end

                it "updates the existing document" do
                  expect(person.quiz.topic).to eq("English")
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before do
            Person.validates_associated(:pet)
          end

          after do
            Person.reset_callbacks(:validate)
          end

          before do
            person.pet_attributes = { name: "$$$" }
          end

          it "propagates invalidity to parent" do
            expect(person.pet).to_not be_valid
            expect(person).to_not be_valid
          end
        end

        context "when a type is passed" do

          let(:canvas) do
            Canvas.new
          end

          before do
            Canvas.send(:undef_method, :writer_attributes=)
            Canvas.accepts_nested_attributes_for :writer
            canvas.writer_attributes = { _type: "HtmlWriter" }
          end

          it "instantiates an object of the given type" do
            expect(canvas.writer.class).to eq(HtmlWriter)
          end
        end
      end

      context "when the relation is embedded in" do

        context "when the child is new" do

          let(:animal) do
            Animal.new
          end

          context "when no id has been passed" do

            context "when no destroy attribute passed" do

              before do
                animal.person_attributes = { title: "Sir" }
              end

              it "builds a new document" do
                expect(animal.person.title).to eq("Sir")
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "does not build a new document" do
                  expect(animal.person).to be_nil
                end
              end

              context "when allow_destroy is false" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "builds a new document" do
                  expect(animal.person.title).to eq("Sir")
                end
              end
            end
          end

          context "when an id has been passed" do

            let(:person) do
              Person.new
            end

            context "when no destroy attribute passed" do

              context "when the id matches" do

                before do
                  animal.person_attributes = { id: person.id, title: "Sir" }
                end

                it "updates the existing document" do
                  expect(animal.person.title).to eq("Sir")
                end
              end
            end

            context "when there is an existing document" do

              before do
                animal.person = person
              end

              context "when allow destroy is true" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      animal.person_attributes =
                        { id: person.id, _destroy: truth }
                    end

                    it "destroys the existing document" do
                      expect(animal.person).to be_nil
                    end
                  end
                end

                [ nil, 0, "0", false, "false" ].each do |falsehood|

                  context "when passed #{falsehood} with destroy" do

                    before do
                      animal.person_attributes =
                        { id: person.id, _destroy: falsehood }
                    end

                    it "does not destroy the existing document" do
                      expect(animal.person).to eq(person)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    animal.person_attributes =
                      { id: person.id, _destroy: true }
                  end

                  it "does not delete the document" do
                    expect(animal.person).to eq(person)
                  end
                end
              end

              context "when update only is true" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for \
                    :person,
                    update_only: true,
                    allow_destroy: true
                end

                context "when the id matches" do

                  before do
                    animal.person_attributes =
                      { id: person.id, title: "Madam" }
                  end

                  it "updates the existing document" do
                    expect(animal.person.title).to eq("Madam")
                  end
                end

                context "when the id does not match" do

                  before do
                    animal.person_attributes =
                      { id: BSON::ObjectId.new.to_s, title: "Madam" }
                  end

                  it "updates the existing document" do
                    expect(animal.person.title).to eq("Madam")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    animal.person_attributes =
                      { id: person.id, title: "Madam", _destroy: "true" }
                  end

                  it "deletes the existing document" do
                    expect(animal.person).to be_nil
                  end
                end
              end
            end
          end

          context "when the nested document is invalid" do

            before do
              Person.validates_format_of :ssn, without: /\$\$\$/
            end

            after do
              Person.reset_callbacks(:validate)
            end

            before do
              animal.person_attributes = { ssn: '$$$' }
            end

            it "does not propagate invalidity to parent" do
              expect(animal.person).to_not be_valid
              expect(animal).to be_valid
            end
          end
        end

        context "when a type is passed" do

          let(:tool) do
            Tool.new
          end

          before do
            tool.palette_attributes ={ _type: "BigPalette" }
          end

          it "instantiates an object of the given type" do
            expect(tool.palette.class).to eq(BigPalette)
          end
        end
      end

      context "when the relation is an embeds many" do

        context "when the parent document is persisted" do

          let(:person) do
            Person.create!
          end

          before do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses
          end

          after do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses
          end

          context "when setting the child attributes" do

            let(:attributes) do
              { "foo" => { "street" => "Maybachufer" } }
            end

            before do
              person.addresses_attributes = attributes
            end

            it "sets the child documents" do
              expect(person.addresses.first.street).to eq("Maybachufer")
            end

            it "does not persist the child documents" do
              expect(person.addresses.first).to_not be_persisted
            end

            context "when saving the parent" do

              before do
                person.save!
                person.reload
              end

              it "saves the child documents" do
                expect(person.addresses.first).to be_persisted
              end
            end
          end
        end

        let(:person) do
          Person.new
        end

        let(:address_one) do
          Address.new(street: "Unter den Linden")
        end

        let(:address_two) do
          Address.new(street: "Kurfeurstendamm")
        end

        context "when a limit is specified" do

          before do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses, limit: 2
          end

          after do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses
          end

          context "when more are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "street" => "Maybachufer" },
                "bar" => { "street" => "Alexander Platz" },
                "baz" => { "street" => "Unter den Linden" }
              }
            end

            it "raises an error" do
              expect {
                person.addresses_attributes = attributes
              }.to raise_error(Mongoid::Errors::TooManyNestedAttributeRecords)
            end
          end

          context "when less are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "street" => "Maybachufer" },
                "bar" => { "street" => "Alexander Platz" }
              }
            end

            before do
              person.addresses_attributes = attributes
            end

            it "sets the documents on the relation" do
              expect(person.addresses.size).to eq(2)
            end
          end

          context "when an array of attributes are passed" do

            let(:attributes) do
              [
                { "street" => "Maybachufer" },
                { "street" => "Alexander Platz" }
              ]
            end

            before do
              person.addresses_attributes = attributes
            end

            it "sets the documents on the relation" do
              expect(person.addresses.size).to eq(2)
            end
          end

          context "when cascading callbacks" do

            before do
              Band.accepts_nested_attributes_for :records
            end

            after do
              Band.send(:undef_method, :records_attributes=)
            end

            let(:band) do
              Band.new
            end

            let(:attributes) do
              [
                { "name" => "101" },
                { "name" => "Ultra" }
              ]
            end

            before do
              band.records_attributes = attributes
            end

            context "when the parent is saved" do

              before do
                band.save!
              end

              it "runs the first child create callbacks" do
                expect(band.records.first.before_create_called).to be true
              end

              it "runs the last child create callbacks" do
                expect(band.records.last.before_create_called).to be true
              end
            end
          end
        end

        context "when ids are passed" do

          before do
            person.addresses << [ address_one, address_two ]
          end

          context "when no destroy attributes are passed" do

            context "when the ids match" do

              before do
                person.addresses_attributes =
                  {
                    "foo" => { "id" => address_one.id, "street" => "Maybachufer" },
                    "bar" => { "id" => address_two.id, "street" => "Alexander Platz" }
                  }
              end

              it "updates the first existing document" do
                expect(person.addresses.first.street).to eq("Maybachufer")
              end

              it "updates the second existing document" do
                expect(person.addresses.second.street).to eq("Alexander Platz")
              end

              it "does not add new documents" do
                expect(person.addresses.size).to eq(2)
              end
            end

            context "when the ids match in an array of attributes" do

              context "when passing in id" do

                before do
                  person.addresses_attributes =
                    [
                      { "id" => address_one.id, "street" => "Maybachufer" },
                      { "id" => address_two.id, "street" => "Alexander Platz" }
                    ]
                end

                it "updates the first existing document" do
                  expect(person.addresses.collect { |a| a['street'] }).to include('Maybachufer')
                end

                it "updates the second existing document" do
                  expect(person.addresses.collect { |a| a['street'] }).to include('Alexander Platz')
                end

                it "does not add new documents" do
                  expect(person.addresses.size).to eq(2)
                end
              end

              context "when passing in _id" do

                before do
                  person.addresses_attributes =
                    [
                      { "_id" => address_one.id, "street" => "Maybachufer" },
                      { "_id" => address_two.id, "street" => "Alexander Platz" }
                    ]
                end

                it "updates the first existing document" do
                  expect(person.addresses.collect { |a| a['street'] }).to include('Maybachufer')
                end

                it "updates the second existing document" do
                  expect(person.addresses.collect { |a| a['street'] }).to include('Alexander Platz')
                end

                it "does not add new documents" do
                  expect(person.addresses.size).to eq(2)
                end
              end
            end

            context "when the ids match in an array of attributes and start with '_'" do

              before do
                person.addresses_attributes =
                  [
                    { "_id" => address_one.id, "street" => "Maybachufer" },
                    { "_id" => address_two.id, "street" => "Alexander Platz" }
                  ]
              end

              it "updates the first existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Maybachufer')
              end

              it "updates the second existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Alexander Platz')
              end

              it "does not add new documents" do
                expect(person.addresses.size).to eq(2)
              end
            end

            context "when the ids are _id symbols" do

              before do
                person.addresses_attributes =
                  [
                    { _id: address_one.id, "street" => "Maybachufer" },
                    { _id: address_two.id, "street" => "Alexander Platz" }
                  ]
              end

              it "updates the first existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Maybachufer')
              end

              it "updates the second existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Alexander Platz')
              end

              it "does not add new documents" do
                expect(person.addresses.size).to eq(2)
              end
            end

            context "when the ids are id symbols" do

              before do
                person.addresses_attributes =
                  [
                    { id: address_one.id, "street" => "Maybachufer" },
                    { id: address_two.id, "street" => "Alexander Platz" }
                  ]
              end

              it "updates the first existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Maybachufer')
              end

              it "updates the second existing document" do
                expect(person.addresses.collect { |a| a['street'] }).to include('Alexander Platz')
              end

              it "does not add new documents" do
                expect(person.addresses.size).to eq(2)
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.addresses_attributes =
                    { "foo" => { "id" => "test", "street" => "Test" } }
                }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Address with id\(s\)/)
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                context "when the parent validation failed" do

                  class BandWithAllowDestroyedRecords < Band
                    validates_presence_of :name
                    accepts_nested_attributes_for :records, :allow_destroy => true
                  end

                  let!(:band) do
                    BandWithAllowDestroyedRecords.create(name: "Depeche Mode")
                  end

                  let!(:record) do
                    band.records.create!
                  end

                  let(:attributes) do
                    {
                      name: nil,
                      records_attributes: { "foo" => { "id" => record.id, "_destroy" => true }}
                    }
                  end

                  before do
                    band.update_attributes(attributes)
                  end

                  it "does not remove the child document" do
                    expect(band.records).to_not be_empty
                  end

                  it "keeps the child flagged for destruction" do
                    expect(record).to be_flagged_for_destroy
                  end

                  it "does not persist any change" do
                    expect(band.reload.records).to eq([ record ])
                  end
                end

                context "when the child accesses the parent after destroy" do

                  before do
                    Band.accepts_nested_attributes_for :records, :allow_destroy => true
                  end

                  after do
                    Band.send(:undef_method, :records_attributes=)
                  end

                  let!(:band) do
                    Band.create!
                  end

                  let!(:record) do
                    band.records.create!
                  end

                  before do
                    band.records_attributes =
                      { "foo" => { "id" => record.id, "_destroy" => true }}
                    band.save!
                  end

                  it "deletes the child document" do
                    expect(band.records).to be_empty
                  end

                  it "persists the changes" do
                    expect(band.reload.records).to be_empty
                  end
                end

                context "when the child has defaults" do

                  before do
                    Person.accepts_nested_attributes_for :appointments, allow_destroy: true
                  end

                  after do
                    Person.send(:undef_method, :appointments_attributes=)
                  end

                  context "when the parent is persisted" do

                    let!(:persisted) do
                      Person.create!(age: 42)
                    end

                    context "when the child halts the callback chain in a before callback" do

                      context "when the child is not paranoid" do

                        let(:actor) do
                          Actor.create!
                        end

                        let!(:thing) do
                          actor.things.create!
                        end

                        before do
                          actor.things_attributes =
                            { "foo" => { "id" => thing.id, "_destroy" => true }}
                          actor.save
                        end

                        it "does not destroy the child" do
                          expect(actor.reload.things).to_not be_empty
                        end
                      end
                    end

                    context "when only 1 child has the default persisted" do

                      let!(:app_one) do
                        persisted.appointments.create!
                      end

                      let!(:app_two) do
                        persisted.appointments.create!.tap do |app|
                          app.unset(:timed)
                        end
                      end

                      context "when destroying both children" do

                        let(:from_db) do
                          Person.find(persisted.id)
                        end

                        before do
                          from_db.appointments_attributes =
                            {
                              "bar" => { "id" => app_one.id, "_destroy" => true },
                              "foo" => { "id" => app_two.id, "_destroy" => true }
                            }
                          from_db.save!
                        end

                        it "destroys both children" do
                          expect(from_db.appointments).to be_empty
                        end

                        it "persists the deletes" do
                          expect(from_db.reload.appointments).to be_empty
                        end
                      end
                    end
                  end
                end

                context "when the child is not paranoid" do

                  before do
                    Person.send(:undef_method, :addresses_attributes=)
                    Person.accepts_nested_attributes_for :addresses, allow_destroy: true
                  end

                  after do
                    Person.send(:undef_method, :addresses_attributes=)
                    Person.accepts_nested_attributes_for :addresses
                  end

                  [ 1, "1", true, "true" ].each do |truth|

                    context "when passed a #{truth} with destroy" do

                      context "when the parent is new" do

                        context "when provided a hash of attributes" do

                          before do
                            person.addresses_attributes =
                              {
                                "bar" => { "id" => address_one.id.to_s, "_destroy" => truth },
                                "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                              }
                          end

                          it "deletes the marked document" do
                            expect(person.addresses.size).to eq(1)
                          end

                          it "does not delete the unmarked document" do
                            expect(person.addresses.first.street).to eq("Alexander Platz")
                          end
                        end

                        context "when provided an array of attributes" do

                          before do
                            person.addresses_attributes =
                              [
                                { "id" => address_one.id.to_s, "_destroy" => truth },
                                { "id" => address_two.id, "street" => "Alexander Platz" }
                              ]
                          end

                          it "deletes the marked document" do
                            expect(person.addresses.size).to eq(1)
                          end

                          it "does not delete the unmarked document" do
                            expect(person.addresses.first.street).to eq("Alexander Platz")
                          end
                        end
                      end

                      context "when the parent is persisted" do

                        let!(:persisted) do
                          Person.create! do |p|
                            p.addresses << [ address_one, address_two ]
                          end
                        end

                        context "when setting, pulling, and pushing in one op" do

                          before do
                            persisted.addresses_attributes =
                              {
                                "bar" => { "id" => address_one.id, "_destroy" => truth },
                                "foo" => { "id" => address_two.id, "street" => "Alexander Platz" },
                                "baz" => { "street" => "Potsdammer Platz" }
                              }
                          end

                          it "does not remove the first document from the relation" do
                            expect(persisted.addresses.size).to eq(3)
                          end

                          it "flags the destroyed document for removal" do
                            expect(address_one).to be_marked_for_destruction
                          end

                          it "does not delete the unmarked document" do
                            expect(persisted.addresses.second.street).to eq(
                              "Alexander Platz"
                            )
                          end

                          it "adds the new document to the relation" do
                            expect(persisted.addresses.last.street).to eq(
                              "Potsdammer Platz"
                            )
                          end

                          it "has the proper persisted count" do
                            expect(persisted.addresses.count).to eq(2)
                          end

                          it "does not delete the removed document" do
                            expect(address_one).to_not be_destroyed
                          end

                          context "when saving the parent" do

                            before do
                              persisted.save!
                            end

                            it "deletes the marked document from the relation" do
                              expect(persisted.reload.addresses.count).to eq(2)
                            end

                            it "does not delete the unmarked document" do
                              expect(persisted.reload.addresses.first.street).to eq(
                                "Alexander Platz"
                              )
                            end

                            it "persists the new document to the relation" do
                              expect(persisted.reload.addresses.last.street).to eq(
                                "Potsdammer Platz"
                              )
                            end
                          end
                        end

                        context "when pulling and pushing in one op" do

                          before do
                            persisted.addresses_attributes =
                              {
                                "bar" => { "id" => address_one.id, "_destroy" => truth },
                                "baz" => { "street" => "Potsdammer Platz" }
                              }
                          end

                          it "does not remove the first document from the relation" do
                            expect(persisted.addresses.size).to eq(3)
                          end

                          it "marks the first document for destruction" do
                            expect(address_one).to be_marked_for_destruction
                          end

                          it "adds the new document to the relation" do
                            expect(persisted.addresses.last.street).to eq(
                              "Potsdammer Platz"
                            )
                          end

                          it "has the proper persisted count" do
                            expect(persisted.addresses.count).to eq(2)
                          end

                          it "does not delete the removed document" do
                            expect(address_one).to_not be_destroyed
                          end

                          context "when saving the parent" do

                            before do
                              persisted.save!
                            end

                            it "deletes the marked document from the relation" do
                              expect(persisted.reload.addresses.count).to eq(2)
                            end

                            it "persists the new document to the relation" do
                              expect(persisted.reload.addresses.last.street).to eq(
                                "Potsdammer Platz"
                              )
                            end
                          end
                        end
                      end
                    end
                  end

                  [ 0, "0", false, "false" ].each do |falsehood|

                    context "when passed a #{falsehood} with destroy" do

                      before do
                        person.addresses_attributes =
                          {
                            "bar" => { "id" => address_one.id, "_destroy" => falsehood },
                            "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                          }
                      end

                      it "does not delete the marked document" do
                        expect(person.addresses.size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.addresses.last.street).to eq("Alexander Platz")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => {
                            "id" => address_one.id, "street" => "Maybachufer", "_destroy" => truth },
                          "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not ignore the marked document" do
                      expect(person.addresses.first.street).to eq("Maybachufer")
                    end

                    it "does not delete the unmarked document" do
                      expect(person.addresses.last.street).to eq("Alexander Platz")
                    end

                    it "does not add additional documents" do
                      expect(person.addresses.size).to eq(2)
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "id" => address_one.id, "_destroy" => falsehood },
                          "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not delete the marked document" do
                      expect(person.addresses.size).to eq(2)
                    end

                    it "does not delete the unmarked document" do
                      expect(person.addresses.last.street).to eq("Alexander Platz")
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => {
                            "id" => address_one.id, "street" => "Maybachufer", "_destroy" => truth },
                          "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not ignore the marked document" do
                      expect(person.addresses.first.street).to eq("Maybachufer")
                    end

                    it "does not delete the unmarked document" do
                      expect(person.addresses.last.street).to eq("Alexander Platz")
                    end

                    it "does not add additional documents" do
                      expect(person.addresses.size).to eq(2)
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "id" => address_one.id, "_destroy" => falsehood },
                          "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not delete the marked document" do
                      expect(person.addresses.size).to eq(2)
                    end

                    it "does not delete the unmarked document" do
                      expect(person.addresses.last.street).to eq("Alexander Platz")
                    end
                  end
                end
              end
            end
          end
        end

        context "when no ids are passed" do

          context "when no destroy attributes are passed" do

            before do
              person.addresses_attributes =
                {
                  "4" => { "street" => "Maybachufer" },
                  "1" => { "street" => "Frederichstrasse" },
                  "2" => { "street" => "Alexander Platz" }
                }
            end

            it "builds a new first document" do
              expect(person.addresses.first.street).to eq("Frederichstrasse")
            end

            it "builds a new second document" do
              expect(person.addresses.second.street).to eq("Alexander Platz")
            end

            it "builds a new third document" do
              expect(person.addresses.third.street).to eq("Maybachufer")
            end

            it "does not add extra documents" do
              expect(person.addresses.size).to eq(3)
            end

            it "adds the documents in the sorted hash key order" do
              expect(person.addresses.map(&:street)).to eq(
                [ "Frederichstrasse", "Alexander Platz", "Maybachufer" ]
              )
            end
          end

          context "when a reject block is supplied" do

            before do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: ->(attrs){ attrs["street"].blank? }
            end

            after do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when the attributes match" do

              before do
                person.addresses_attributes =
                  { "3" => { "city" => "Berlin" } }
              end

              it "does not add the new document" do
                expect(person.addresses).to be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.addresses_attributes =
                  { "3" => { "street" => "Maybachufer" } }
              end

              it "adds the new document" do
                expect(person.addresses.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.addresses.first.street).to eq("Maybachufer")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: :all_blank
            end

            after do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when all attributes are empty" do

              before do
                person.addresses_attributes =
                  { "3" => { "city" => "" } }
              end

              it "does not add the new document" do
                expect(person.addresses).to be_empty
              end
            end

            context "when an attribute is not-empty" do

              before do
                person.addresses_attributes =
                  { "3" => { "street" => "Maybachufer" } }
              end

              it "adds the new document" do
                expect(person.addresses.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.addresses.first.street).to eq("Maybachufer")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, allow_destroy: true
              end

              after do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "bar" => { "street" => "Maybachufer", "_destroy" => truth },
                        "foo" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "ignores the marked document" do
                    expect(person.addresses.size).to eq(1)
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.first.street).to eq("Alexander Platz")
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "0" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "1" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.addresses.first.street).to eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.last.street).to eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    expect(person.addresses.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, allow_destroy: false
              end

              after do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "0" => { "street" => "Maybachufer", "_destroy" => truth },
                        "1" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.addresses.first.street).to eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.last.street).to eq("Alexander Platz")
                  end

                  it "adds the correct number of documents" do
                    expect(person.addresses.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "0" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "1" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.addresses.first.street).to eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.last.street).to eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    expect(person.addresses.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "0" => { "street" => "Maybachufer", "_destroy" => truth },
                        "1" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.addresses.first.street).to eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.last.street).to eq("Alexander Platz")
                  end

                  it "adds the correct number of documents" do
                    expect(person.addresses.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "0" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "1" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.addresses.first.street).to eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    expect(person.addresses.last.street).to eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    expect(person.addresses.size).to eq(2)
                  end
                end
              end
            end
          end

          context "when 'reject_if: :all_blank' and 'allow_destroy: true' are specified" do

            before do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: :all_blank, allow_destroy: true
            end

            after do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when all attributes are blank and _destroy has a truthy, non-blank value" do

              before do
                person.addresses_attributes =
                  { "3" => { last_name: "", _destroy: "0" } }
              end

              it "does not add the document" do
                expect(person.addresses).to be_empty
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before do
            Person.validates_associated(:addresses)
          end

          after do
            Person.reset_callbacks(:validate)
          end

          before do
            person.addresses_attributes = {
              "0" => { street: '123' }
            }
          end

          it "propagates invalidity to parent" do
            expect(person.addresses.first).to_not be_valid
            expect(person).to_not be_valid
          end
        end

        context "when a type is passed" do

          let(:canvas) do
            Canvas.new
          end

          before do
            Canvas.send(:undef_method, :shapes_attributes=)
            Canvas.accepts_nested_attributes_for :shapes
            canvas.shapes_attributes =
              {
                "foo" => { "_type" => "Square" },
                "bar" => { "_type" => "Circle" }
              }
          end

          it "instantiates an object of the given type" do
            expect(canvas.shapes.map(&:class)).to eq([Square, Circle])
          end
        end
      end

      context "when the relation is a references one" do

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for \
              :game, reject_if: ->(attrs){ attrs[:name].blank? }
          end

          after do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for :game
          end

          context "when the attributes match" do

            before do
              person.game_attributes = { score: 10 }
            end

            it "does not add the document" do
              expect(person.game).to be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "adds the document" do
              expect(person.game.name).to eq("Tron")
            end
          end
        end

        context "when reject_if => :all_blank is specified" do

          before do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for \
              :game, reject_if: :all_blank
          end

          after do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for :game
          end

          context "when all attributes are empty" do

            before do
              person.game_attributes = { score: nil }
            end

            it "does not add the document" do
              expect(person.game).to be_nil
            end
          end

          context "when an attribute is non-empty" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "adds the document" do
              expect(person.game.name).to eq("Tron")
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "builds a new document" do
              expect(person.game.name).to eq("Tron")
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, allow_destroy: true
              end

              after do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { name: "Tron", _destroy: "1" }
              end

              it "does not build the document" do
                expect(person.game).to be_nil
              end
            end

            context "when allow_destroy is false" do

              before do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, allow_destroy: false
              end

              after do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { name: "Tron", _destroy: "1" }
              end

              it "builds the document" do
                expect(person.game.name).to eq("Tron")
              end
            end
          end

          context "with empty attributes" do

            before do
              person.game_attributes = {}
            end

            it "does not build the document" do
              expect(person.game).to be_nil
            end
          end

          context "when there is an existing document" do

            context "with no destroy attribute" do

              before do
                person.game = Game.new(name: "Tron")
                person.game_attributes = { name: "Pong" }
              end

              it "replaces the document" do
                expect(person.game.name).to eq("Pong")
              end
            end

            context "when updating attributes" do

              let!(:pizza) do
                Pizza.create(name: "large")
              end

              before do
                pizza.topping = Topping.create!(name: "cheese")
                pizza.update_attributes!(topping_attributes: { name: "onions" })
              end

              it "persists the attribute changes" do
                expect(pizza.reload.topping.name).to eq("onions")
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(name: "Tron")
                  person.game_attributes = { name: "Pong", _destroy: "1" }
                end

                it "does not replace the document" do
                  expect(person.game.name).to eq("Tron")
                end
              end

              context "when allow_destroy is false" do

                before do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(name: "Tron")
                  person.game_attributes = { name: "Pong", _destroy: "1" }
                end

                it "replaces the document" do
                  expect(person.game.name).to eq("Pong")
                end
              end
            end
          end
        end

        context "when an id is passed" do

          context "when there is an existing record" do

            let(:game) do
              Game.new(name: "Tron")
            end

            before do
              person.game = game
            end

            context "when the id matches" do

              context "when passed keys as symbols" do

                before do
                  person.game_attributes =
                    { id: game.id, name: "Pong" }
                end

                it "updates the existing document" do
                  expect(person.game.name).to eq("Pong")
                end
              end

              context "when passed keys as strings" do

                before do
                  person.game_attributes =
                    { "id" => game.id, "name" => "Pong" }
                end

                it "updates the existing document" do
                  expect(person.game.name).to eq("Pong")
                end
              end

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      person.game_attributes =
                        { id: game.id, _destroy: truth }
                    end

                    it "destroys the existing document" do
                      expect(person.game).to be_nil
                    end
                  end
                end

                [ nil, 0, "0", false, "false" ].each do |falsehood|

                  context "when passed #{falsehood} with destroy" do

                    before do
                      person.game_attributes =
                        { id: game.id, _destroy: falsehood }
                    end

                    it "does not destroy the existing document" do
                      expect(person.game).to eq(game)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.game_attributes =
                      { id: game.id, _destroy: true }
                  end

                  it "does not destroy the document" do
                    expect(person.game).to eq(game)
                  end
                end
              end

              context "when update only is true" do

                before do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for \
                    :game,
                    update_only: true,
                    allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when the id matches" do

                  before do
                    person.game_attributes =
                      { id: game.id, name: "Donkey Kong" }
                  end

                  it "updates the existing document" do
                    expect(person.game.name).to eq("Donkey Kong")
                  end
                end

                context "when the id does not match" do

                  before do
                    person.game_attributes =
                      { id: BSON::ObjectId.new.to_s, name: "Pong" }
                  end

                  it "updates the existing document" do
                    expect(person.game.name).to eq("Pong")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.game_attributes =
                      { id: game.id, _destroy: true }
                  end

                  it "destroys the existing document" do
                    expect(person.game).to be_nil
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before do
            Person.validates_associated(:game)
          end

          after do
            Person.reset_callbacks(:validate)
          end

          before do
            person.game_attributes = { name: '$$$' }
          end

          it "propagates invalidity to parent" do
            expect(person.game).to_not be_valid
            expect(person).to_not be_valid
          end
        end

        context "when a type is passed" do

          let(:driver) do
            Driver.new
          end

          before do
            Driver.send(:undef_method, :vehicle_attributes=)
            Driver.accepts_nested_attributes_for :vehicle
            driver.vehicle_attributes = { "_type" => "Truck" }
          end

          it "instantiates an object of the given type" do
            expect(driver.vehicle.class).to eq(Truck)
          end
        end
      end

      context "when the relation is referenced in" do

        context "when the child is new" do

          let(:game) do
            Game.new
          end

          context "when no id has been passed" do

            context "when no destroy attribute passed" do

              before do
                game.person_attributes = { title: "Sir" }
              end

              it "builds a new document" do
                expect(game.person.title).to eq("Sir")
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "does not build a new document" do
                  expect(game.person).to be_nil
                end
              end

              context "when allow_destroy is false" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "builds a new document" do
                  expect(game.person.title).to eq("Sir")
                end
              end
            end
          end

          context "when an id has been passed" do

            let(:person) do
              Person.new
            end

            context "when no destroy attribute passed" do

              context "when the id matches" do

                before do
                  game.person_attributes = { id: person.id, title: "Sir" }
                end

                it "updates the existing document" do
                  expect(game.person.title).to eq("Sir")
                end
              end
            end

            context "when there is an existing document" do

              before do
                game.person = person
              end

              context "when allow destroy is true" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      game.person_attributes =
                        { id: person.id, _destroy: truth }
                    end

                    it "destroys the existing document" do
                      expect(game.person).to be_nil
                    end
                  end
                end

                [ nil, 0, "0", false, "false" ].each do |falsehood|

                  context "when passed #{falsehood} with destroy" do

                    before do
                      game.person_attributes =
                        { id: person.id, _destroy: falsehood }
                    end

                    it "does not destroy the existing document" do
                      expect(game.person).to eq(person)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    game.person_attributes =
                      { id: person.id, _destroy: true }
                  end

                  it "does not delete the document" do
                    expect(game.person).to eq(person)
                  end
                end
              end

              context "when update only is true" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for \
                    :person,
                    update_only: true,
                    allow_destroy: true
                end

                context "when the id matches" do

                  before do
                    game.person_attributes =
                      { id: person.id, title: "Madam" }
                  end

                  it "updates the existing document" do
                    expect(game.person.title).to eq("Madam")
                  end
                end

                context "when the id does not match" do

                  before do
                    game.person_attributes =
                      { id: BSON::ObjectId.new.to_s, title: "Madam" }
                  end

                  it "updates the existing document" do
                    expect(game.person.title).to eq("Madam")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    game.person_attributes =
                      { id: person.id, title: "Madam", _destroy: "true" }
                  end

                  it "deletes the existing document" do
                    expect(game.person).to be_nil
                  end
                end
              end
            end
          end

          context "when the nested document is invalid" do

            before do
              Person.validates_format_of :ssn, without: /\$\$\$/
            end

            after do
              Person.reset_callbacks(:validate)
            end

            before do
              game.person_attributes = { ssn: '$$$' }
            end

            it "propagates invalidity to parent" do
              expect(game.person).to_not be_valid
              expect(game).to_not be_valid
            end
          end
        end

        context "when a type is passed" do

          let(:vehicle) do
            Vehicle.new
          end

          before do
            Vehicle.send(:undef_method, :driver_attributes=)
            Vehicle.accepts_nested_attributes_for :driver
            vehicle.driver_attributes = { "_type" => "Learner" }
          end

          it "instantiates an object of the given type" do
            expect(vehicle.driver.class).to eq(Learner)
          end
        end
      end

      context "when the relation is a references many" do

        let(:person) do
          Person.new
        end

        let(:post_one) do
          Post.new(title: "First post")
        end

        let(:post_two) do
          Post.new(title: "First response")
        end

        context "when a limit is specified" do

          before do
            Person.send(:undef_method, :posts_attributes=)
            Person.accepts_nested_attributes_for :posts, limit: 2
          end

          after do
            Person.send(:undef_method, :posts_attributes=)
            Person.accepts_nested_attributes_for :posts
          end

          context "when more are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "title" => "First" },
                "bar" => { "title" => "Second" },
                "baz" => { "title" => "Third" }
              }
            end

            it "raises an error" do
              expect {
                person.posts_attributes = attributes
              }.to raise_error(Mongoid::Errors::TooManyNestedAttributeRecords)
            end
          end

          context "when less are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "title" => "First" },
                "bar" => { "title" => "Second" }
              }
            end

            before do
              person.posts_attributes = attributes
            end

            it "sets the documents on the relation" do
              expect(person.posts.size).to eq(2)
            end

            it "does not persist the new documents" do
              expect(person.posts.count).to eq(0)
            end
          end
        end

        context "when ids are passed" do

          let(:person) do
            Person.create!
          end

          before do
            person.posts << [ post_one, post_two ]
          end

          context "when no destroy attributes are passed" do

            context "when the ids match" do

              before do
                person.posts_attributes =
                  {
                    "0" => { "id" => post_one.id, "title" => "First" },
                    "1" => { "id" => post_two.id, "title" => "Second" }
                  }
              end

              context "when reloading the document" do

                it "updates the first existing document" do
                  expect(person.posts(true)[0].title).to eq("First")
                end

                it "updates the second existing document" do
                  expect(person.posts(true)[1].title).to eq("Second")
                end

                it "does not add new documents" do
                  expect(person.posts(true).size).to eq(2)
                end
              end

              context "when there are no documents" do

                before do
                  person.posts.clear
                end

                it "raises a document not found error" do
                  expect {
                    person.posts_attributes =
                      { "0" =>
                        { "id" => BSON::ObjectId.new.to_s, "title" => "Rogue" }
                      }
                  }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Post with id\(s\)/)
                end
              end
            end

            context "when the parent is freshly loaded from the db" do

              before do
                person.reload
              end

              context "when updating valid documents with invalid values" do

                before do
                  person.posts_attributes =
                    {
                      "0" => { "id" => post_one.id, "title" => "testing again" },
                      "1" => { "id" => post_two.id, "title" => "$$$" }
                    }
                  person.save!
                end

                it "does not perist the invalid value" do
                  expect(post_two.reload.title).to eq("First response")
                end
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.posts_attributes =
                    { "foo" => { "id" => "test", "title" => "Test" } }
                }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Post with id\(s\)/)
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => { "id" => post_one.id, "_destroy" => truth },
                          "1" => { "id" => post_two.id, "title" => "My Blog" }
                        }
                    end

                    context "when reloading the documents" do

                      it "deletes the marked document" do
                        expect(person.posts(true).size).to eq(1)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true).first.title).to eq("My Blog")
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => { "id" => post_one.id, "_destroy" => falsehood },
                          "1" => { "id" => post_two.id, "title" => "My Blog" }
                        }
                    end

                    context "when reloading the document" do

                      it "does not delete the marked document" do
                        expect(person.posts(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true).map(&:title)).to include("My Blog")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => {
                            "id" => post_one.id, "title" => "Another Title", "_destroy" => truth },
                          "1" => { "id" => post_two.id, "title" => "New Title" }
                        }
                    end

                    context "when reloading the document" do

                      it "does not ignore the marked document" do
                        expect(person.posts(true)[0].title).to eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true)[1].title).to eq("New Title")
                      end

                      it "does not add additional documents" do
                        expect(person.posts(true).size).to eq(2)
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => { "id" => post_one.id, "_destroy" => falsehood },
                          "1" => { "id" => post_two.id, "title" => "New Title" }
                        }
                    end

                    context "when reloading the documents" do

                      it "does not delete the marked document" do
                        expect(person.posts(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true)[1].title).to eq("New Title")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts
                end

                after do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => {
                            "id" => post_one.id,
                            "title" => "Another Title",
                            "_destroy" => truth
                          },
                          "1" => { "id" => post_two.id, "title" => "New Title" }
                        }
                    end

                    context "when reloading" do

                      it "does not ignore the marked document" do
                        expect(person.posts(true).find(post_one.id).title).to eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true).find(post_two.id).title).to eq("New Title")
                      end

                      it "does not add additional documents" do
                        expect(person.posts(true).size).to eq(2)
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.posts_attributes =
                        {
                          "0" => { "id" => post_one.id, "_destroy" => falsehood },
                          "1" => { "id" => post_two.id, "title" => "New Title" }
                        }
                    end

                    context "when reloading" do

                      it "does not delete the marked document" do
                        expect(person.posts(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.posts(true)[1].title).to eq("New Title")
                      end
                    end
                  end
                end
              end
            end
          end
        end

        context "when no ids are passed" do

          context "when no destroy attributes are passed" do

            context "when passing a hash of attributes" do

              before do
                person.posts_attributes =
                  {
                    "4" => { "title" => "Third" },
                    "1" => { "title" => "First" },
                    "2" => { "title" => "Second" }
                  }
              end

              it "builds a new first document" do
                expect(person.posts[0].title).to eq("First")
              end

              it "builds a new second document" do
                expect(person.posts[1].title).to eq("Second")
              end

              it "builds a new third document" do
                expect(person.posts[2].title).to eq("Third")
              end

              it "does not add extra documents" do
                expect(person.posts.size).to eq(3)
              end

              it "does not persist the documents" do
                expect(person.posts.count).to eq(0)
              end

              it "adds the documents in the sorted hash key order" do
                expect(person.posts.map(&:title)).to eq(
                  [ "First", "Second", "Third" ]
                )
              end
            end

            context "when passing an array of attributes" do

              context "when the parent is saved" do

                before do
                  person.save!
                  person.posts_attributes =
                    [
                      { "title" => "Third" },
                      { "title" => "First" },
                      { "title" => "Second" }
                    ]
                end

                it "builds a new first document" do
                  expect(person.posts.first.title).to eq("Third")
                end

                it "builds a new second document" do
                  expect(person.posts.second.title).to eq("First")
                end

                it "builds a new third document" do
                  expect(person.posts.third.title).to eq("Second")
                end

                it "does not add extra documents" do
                  expect(person.posts.size).to eq(3)
                end

                it "does not persist the documents" do
                  expect(person.posts.count).to eq(0)
                end
              end
            end
          end

          context "when a reject block is supplied" do

            before do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for \
                :posts, reject_if: ->(attrs){ attrs["title"].blank? }
            end

            after do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for :posts
            end

            context "when the attributes match" do

              before do
                person.posts_attributes =
                  { "3" => { "content" => "My first blog" } }
              end

              it "does not add the new document" do
                expect(person.posts).to be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.posts_attributes =
                  { "3" => { "title" => "Blogging" } }
              end

              it "adds the new document" do
                expect(person.posts.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.posts.first.title).to eq("Blogging")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for \
                :posts, reject_if: :all_blank
            end

            after do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for :posts
            end

            context "when all attributes are blank" do

              before do
                person.posts_attributes =
                  { "3" => { "content" => "" } }
              end

              it "does not add the new document" do
                expect(person.posts).to be_empty
              end
            end

            context "when an attribute is non-empty" do

              before do
                person.posts_attributes =
                  { "3" => { "title" => "Blogging" } }
              end

              it "adds the new document" do
                expect(person.posts.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.posts.first.title).to eq("Blogging")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts, allow_destroy: true
              end

              after do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => truth },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "ignores the marked document" do
                    expect(person.posts.size).to eq(1)
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.first.title).to eq("Blog Two")
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => falsehood },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.posts.first.title).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.last.title).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.posts.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts, allow_destroy: false
              end

              after do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => truth },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.posts.first.title).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.last.title).to eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    expect(person.posts.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => falsehood },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.posts.first.title).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.last.title).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.posts.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => truth },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.posts.first.title).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.last.title).to eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    expect(person.posts.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.posts_attributes =
                      {
                        "0" => { "title" => "New Blog", "_destroy" => falsehood },
                        "1" => { "title" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.posts.first.title).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.posts.last.title).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.posts.size).to eq(2)
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before do
            Person.validates_associated(:posts)
          end

          after do
            Person.reset_callbacks(:validate)
          end

          before do
            person.posts_attributes = {
              "0" => { title: "$$$" }
            }
          end

          it "propagates invalidity to parent" do
            expect(person).to_not be_valid
            expect(person.posts.first).to_not be_valid
          end
        end

        context "when a type is passed" do

          let(:shipping_container) do
            ShippingContainer.new
          end

          before do
            ShippingContainer.send(:undef_method, :vehicles_attributes=)
            ShippingContainer.accepts_nested_attributes_for :vehicles
            shipping_container.vehicles_attributes =
              {
                "foo" => { "_type" => "Car" },
                "bar" => { "_type" => "Truck" }
              }
          end

          it "instantiates an object of the given type" do
            expect(shipping_container.vehicles.map(&:class)).to eq([Car, Truck])
          end
        end
      end

      context "when the relation is a references many to many" do

        let(:person) do
          Person.new
        end

        let(:preference_one) do
          Preference.new(name: "First preference")
        end

        let(:preference_two) do
          Preference.new(name: "First response")
        end

        context "when a limit is specified" do

          before do
            Person.send(:undef_method, :preferences_attributes=)
            Person.accepts_nested_attributes_for :preferences, limit: 2
          end

          after do
            Person.send(:undef_method, :preferences_attributes=)
            Person.accepts_nested_attributes_for :preferences
          end

          context "when more are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "name" => "First" },
                "bar" => { "name" => "Second" },
                "baz" => { "name" => "Third" }
              }
            end

            it "raises an error" do
              expect {
                person.preferences_attributes = attributes
              }.to raise_error(Mongoid::Errors::TooManyNestedAttributeRecords)
            end
          end

          context "when less are provided than the limit" do

            let(:attributes) do
              {
                "foo" => { "name" => "First" },
                "bar" => { "name" => "Second" }
              }
            end

            before do
              person.preferences_attributes = attributes
            end

            it "sets the documents on the relation" do
              expect(person.preferences.size).to eq(2)
            end
          end
        end

        context "when ids are passed" do

          let(:person) do
            Person.create!
          end

          before do
            person.preferences << [ preference_one, preference_two ]
          end

          context "when no destroy attributes are passed" do

            context "when the ids match" do

              before do
                person.preferences_attributes =
                  {
                    "0" => { "id" => preference_one.id, "name" => "First" },
                    "1" => { "id" => preference_two.id, "name" => "Second" }
                  }
              end

              context "when reloading the document" do

                it "updates the first existing document" do
                  expect(person.preferences(true).first.name).to eq("First")
                end

                it "updates the second existing document" do
                  expect(person.preferences(true).second.name).to eq("Second")
                end

                it "does not add new documents" do
                  expect(person.preferences(true).size).to eq(2)
                end
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.preferences_attributes =
                    { "foo" => { "id" => "test", "name" => "Test" } }
                }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Preference with id\(s\)/)
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                before do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences, allow_destroy: true
                end

                after do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => { "id" => preference_one.id, "_destroy" => truth },
                          "1" => { "id" => preference_two.id, "name" => "My Blog" }
                        }
                    end

                    context "when reloading the documents" do

                      it "deletes the marked document" do
                        expect(person.preferences(true).size).to eq(1)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true).first.name).to eq("My Blog")
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => { "id" => preference_one.id, "_destroy" => falsehood },
                          "1" => { "id" => preference_two.id, "name" => "My Blog" }
                        }
                    end

                    context "when reloading the document" do

                      it "does not delete the marked document" do
                        expect(person.preferences(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true)[1].name).to eq("My Blog")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences, allow_destroy: false
                end

                after do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => {
                            "id" => preference_one.id, "name" => "Another Title", "_destroy" => truth },
                          "1" => { "id" => preference_two.id, "name" => "New Title" }
                        }
                    end

                    context "when reloading the document" do

                      it "does not ignore the marked document" do
                        expect(person.preferences(true)[0].name).to eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true)[1].name).to eq("New Title")
                      end

                      it "does not add additional documents" do
                        expect(person.preferences(true).size).to eq(2)
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => { "id" => preference_one.id, "_destroy" => falsehood },
                          "1" => { "id" => preference_two.id, "name" => "New Title" }
                        }
                    end

                    context "when reloading the documents" do

                      it "does not delete the marked document" do
                        expect(person.preferences(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true)[1].name).to eq("New Title")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => {
                            "id" => preference_one.id, "name" => "Another Title", "_destroy" => truth },
                          "1" => { "id" => preference_two.id, "name" => "New Title" }
                        }
                    end

                    context "when reloading" do

                      it "does not ignore the marked document" do
                        expect(person.preferences(true)[0].name).to eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true)[1].name).to eq("New Title")
                      end

                      it "does not add additional documents" do
                        expect(person.preferences(true).size).to eq(2)
                      end
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.preferences_attributes =
                        {
                          "0" => { "id" => preference_one.id, "_destroy" => falsehood },
                          "1" => { "id" => preference_two.id, "name" => "New Title" }
                        }
                    end

                    context "when reloading" do

                      it "does not delete the marked document" do
                        expect(person.preferences(true).size).to eq(2)
                      end

                      it "does not delete the unmarked document" do
                        expect(person.preferences(true)[1].name).to eq("New Title")
                      end
                    end
                  end
                end
              end
            end
          end
        end

        context "when no ids are passed" do

          context "when no destroy attributes are passed" do

            before do
              person.preferences_attributes =
                {
                  "4" => { "name" => "Third" },
                  "1" => { "name" => "First" },
                  "2" => { "name" => "Second" }
                }
            end

            it "builds a new first document" do
              expect(person.preferences.first.name).to eq("First")
            end

            it "builds a new second document" do
              expect(person.preferences.second.name).to eq("Second")
            end

            it "builds a new third document" do
              expect(person.preferences.third.name).to eq("Third")
            end

            it "does not add extra documents" do
              expect(person.preferences.size).to eq(3)
            end

            it "adds the documents in the sorted hash key order" do
              expect(person.preferences.map(&:name)).to eq(
                [ "First", "Second", "Third" ]
              )
            end
          end

          context "when a reject block is supplied" do

            before do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for \
                :preferences, reject_if: ->(attrs){ attrs["name"].blank? }
            end

            after do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for :preferences
            end

            context "when the attributes match" do

              before do
                person.preferences_attributes =
                  { "3" => { "content" => "My first blog" } }
              end

              it "does not add the new document" do
                expect(person.preferences).to be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.preferences_attributes =
                  { "3" => { "name" => "Blogging" } }
              end

              it "adds the new document" do
                expect(person.preferences.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.preferences.first.name).to eq("Blogging")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for \
                :preferences, reject_if: :all_blank
            end

            after do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for :preferences
            end

            context "when all attributes are empty" do

              before do
                person.preferences_attributes =
                  { "3" => { "content" => "" } }
              end

              it "does not add the new document" do
                expect(person.preferences).to be_empty
              end
            end

            context "when an attribute is non-empty" do

              before do
                person.preferences_attributes =
                  { "3" => { "name" => "Blogging" } }
              end

              it "adds the new document" do
                expect(person.preferences.size).to eq(1)
              end

              it "sets the correct attributes" do
                expect(person.preferences.first.name).to eq("Blogging")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences, allow_destroy: true
              end

              after do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => truth },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "ignores the marked document" do
                    expect(person.preferences.size).to eq(1)
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.first.name).to eq("Blog Two")
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => falsehood },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.preferences.first.name).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.last.name).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.preferences.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences, allow_destroy: false
              end

              after do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => truth },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.preferences.first.name).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.last.name).to eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    expect(person.preferences.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => falsehood },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.preferences.first.name).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.last.name).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.preferences.size).to eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences
              end

              [ 1, "1", true, "true" ].each do |truth|

                context "when passed a #{truth} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => truth },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "adds the marked document" do
                    expect(person.preferences.first.name).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.last.name).to eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    expect(person.preferences.size).to eq(2)
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.preferences_attributes =
                      {
                        "0" => { "name" => "New Blog", "_destroy" => falsehood },
                        "1" => { "name" => "Blog Two" }
                      }
                  end

                  it "adds the new marked document" do
                    expect(person.preferences.first.name).to eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    expect(person.preferences.last.name).to eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    expect(person.preferences.size).to eq(2)
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before do
            Person.validates_associated(:preferences)
          end

          after do
            Person.reset_callbacks(:validate)
          end

          before do
            person.preferences_attributes = {
              "0" => { name: 'x' }
            }
          end

          it "propagates invalidity to parent" do
            expect(person.preferences.first).to_not be_valid
            expect(person).to_not be_valid
          end
        end
      end
    end
  end

  describe "#update_attributes!" do

    before do
      Person.send(:undef_method, :addresses_attributes=)
      Person.accepts_nested_attributes_for :addresses
    end

    context "when embedding one level behind a has many" do

      let(:node) do
        Node.create!
      end

      let!(:server) do
        node.servers.create!(name: "prod")
      end

      context "when adding a new embedded document" do

        let(:attributes) do
          { servers_attributes:
            { "0" =>
              {
                _id: server.id,
                filesystems_attributes: {
                  "0" => { name: "NFS" }
                }
              }
            }
          }
        end

        before do
          node.update_attributes!(attributes)
        end

        it "adds the new embedded document" do
          expect(server.reload.filesystems.first.name).to eq("NFS")
        end

        it "does not add more than one document" do
          expect(server.reload.filesystems.count).to eq(1)
        end
      end
    end

    context "when deleting the child document" do

      let(:person) do
        Person.create!
      end

      let!(:service) do
        person.services.create!(sid: "123")
      end

      let(:attributes) do
        { services_attributes:
          { "0" =>
            { _id: service.id, sid: service.sid, _destroy: 1 }
          }
        }
      end

      before do
        person.update_attributes!(attributes)
      end

      it "removes the document from the parent" do
        expect(person.services).to be_empty
      end

      it "deletes the document" do
        expect(service).to be_destroyed
      end

      it "runs the before destroy callbacks" do
        expect(service.before_destroy_called).to be true
      end

      it "runs the after destroy callbacks" do
        expect(service.after_destroy_called).to be true
      end

      it "clears the delayed atomic pulls from the parent" do
        expect(person.delayed_atomic_pulls).to be_empty
      end
    end

    context "when nesting multiple levels and parent is timestamped" do

      after do
        Address.reset_callbacks(:save)
      end

      let(:dokument) do
        Dokument.create!
      end

      let!(:address) do
        dokument.addresses.create!(street: "hobrecht")
      end

      let!(:location) do
        address.locations.create!(name: "work")
      end

      let(:attributes) do
        {
          locations_attributes: {
            a: { name: "home" }
          }
        }
      end

      before do
        address.update_attributes!(attributes)
        address.reload
      end

      it "does not add any extra locations" do
        expect(address.locations.size).to eq(2)
      end
    end

    context "when nesting multiple levels" do

      let!(:person) do
        Person.create!
      end

      context "when second level is a one to many" do

        let(:person_one) do
          Person.create!
        end

        let!(:address_one) do
          person_one.addresses.create!(street: "hobrecht")
        end

        let!(:location_one) do
          address_one.locations.create!(name: "home")
        end

        context "when destroying a second level document" do

          let(:attributes) do
            { addresses_attributes:
              { "0" =>
                {
                  _id: address_one.id,
                  locations_attributes: { "0" => { _id: location_one.id, _destroy: true }}
                }
              }
            }
          end

          before do
            person_one.update_attributes!(attributes)
          end

          it "deletes the document from the relation" do
            expect(address_one.locations).to be_empty
          end

          it "persists the change" do
            expect(address_one.reload.locations).to be_empty
          end
        end

        context "when destroying a second level document with callbacks" do

          let(:band) do
            Band.create!(name: "Tool")
          end

          let(:record) do
            band.records.create!(name: "Undertow")
          end

          let!(:track) do
            record.tracks.create!(name: "Sober")
          end

          context "when cascading callbacks" do

            before do
              Band.accepts_nested_attributes_for :records
              Record.accepts_nested_attributes_for :tracks, allow_destroy: true
            end

            after do
              Band.send(:undef_method, :records_attributes=)
              Record.send(:undef_method, :tracks_attributes=)
            end

            let(:attributes) do
              { records_attributes:
                { "0" =>
                  {
                    _id: record.id,
                    tracks_attributes: { "0" => { _id: track.id, _destroy: true }}
                  }
                }
              }
            end

            before do
              band.update_attributes!(attributes)
            end

            it "removes the child from the relation" do
              expect(record.tracks).to be_empty
            end

            it "deletes the child document" do
              expect(track).to be_destroyed
            end

            it "runs the child's callbacks" do
              expect(track.before_destroy_called).to be true
            end
          end
        end

        context "when adding new documents in both levels" do

          context "when no documents has previously existed" do

            let(:attributes) do
              { addresses_attributes:
                { "0" =>
                  {
                    street: "Alexanderstr",
                    locations_attributes: { "0" => { name: "Home" } }
                  }
                }
              }
            end

            before do
              person.update_attributes!(attributes)
            end

            let(:address) do
              person.addresses.first
            end

            let(:location) do
              address.locations.first
            end

            it "adds the new first level embedded document" do
              expect(address.street).to eq("Alexanderstr")
            end

            it "adds the nested embedded document" do
              expect(location.name).to eq("Home")
            end
          end

          context "when adding to an existing document in the first level" do

            let!(:address) do
              person.addresses.create!(street: "hobrecht")
            end

            let!(:location) do
              address.locations.create!(name: "work")
            end

            let(:attributes) do
              {
                addresses_attributes: {
                  a: { id: address.id, locations_attributes: { b: { name: "home" }}},
                  c: { street: "pfluger" }
                }
              }
            end

            before do
              person.update_attributes!(attributes)
              person.reload
            end

            it "adds the new location to the existing address" do
              expect(person.addresses.first.locations.count).to eq(2)
            end

            it "adds the new address" do
              expect(person.addresses.count).to eq(2)
            end
          end
        end
      end

      context "when the second level is a one to one" do

        context "when the nested document is new" do

          let(:attributes) do
            { addresses_attributes:
              { "0" =>
                {
                  street: "Alexanderstr",
                  code_attributes: { name: "Home" }
                }
              }
            }
          end

          before do
            person.update_attributes!(attributes)
          end

          let(:address) do
            person.addresses.first
          end

          let(:code) do
            address.code
          end

          it "adds the new first level embedded document" do
            expect(address.street).to eq("Alexanderstr")
          end

          it "adds the nested embedded document" do
            expect(code.name).to eq("Home")
          end
        end
      end

      context "when the nested document is getting updated" do

        context "when the nested document is not polymorphic" do

          let!(:address) do
            person.addresses.create!(street: "Alexanderstr", number: 1)
          end

          let!(:code) do
            address.create_code(name: "Home")
          end

          let(:attributes) do
            { addresses_attributes:
              { "0" =>
                {
                  _id: address.id,
                  number: 45,
                  code_attributes: {
                    _id: code.id,
                    name: "Work"
                  }
                }
              }
            }
          end

          before do
            person.update_attributes!(attributes)
          end

          it "updates the first level embedded document" do
            expect(address.number).to eq(45)
          end

          it "updates the nested embedded document" do
            expect(code.name).to eq("Work")
          end
        end

        context "when the nested document is polymorphic" do

          context "when the first level is an embeds many" do

            let!(:address) do
              person.addresses.create!(street: "Alexanderstr", number: 1)
            end

            let!(:target) do
              address.create_target(name: "test")
            end

            let(:attributes) do
              { addresses_attributes:
                { "0" =>
                  {
                    _id: address.id,
                    number: 45,
                    target_attributes: {
                      _id: target.id,
                      name: "updated"
                    }
                  }
                }
              }
            end

            before do
              person.update_attributes!(attributes)
            end

            it "updates the first level embedded document" do
              expect(address.number).to eq(45)
            end

            it "updates the nested embedded document" do
              expect(target.name).to eq("updated")
            end
          end

          context "when the first level is an embeds one" do

            context "when the id is passed as a string" do

              let!(:name) do
                person.create_name(first_name: "john", last_name: "doe")
              end

              let!(:language) do
                name.create_language(name: "english")
              end

              let(:attributes) do
                { name_attributes:
                  {
                    language_attributes: {
                      _id: language.id.to_s,
                      name: "deutsch"
                    }
                  }
                }
              end

              before do
                person.update_attributes!(attributes)
              end

              it "updates the nested embedded document" do
                expect(language.name).to eq("deutsch")
              end
            end
          end
        end
      end
    end

    context "when the relation is a has many" do

      context "when updating with valid attributes" do

        let(:user) do
          User.create!
        end

        let(:params) do
          { posts_attributes:
            { "0" => { title: "Testing" }}
          }
        end

        before do
          user.update_attributes!(params)
        end

        around do |example|
          original_relations = User.relations
          User.has_many :posts, foreign_key: :author_id, validate: false, autosave: true
          example.run
          user.relations = original_relations
        end

        let(:post) do
          user.posts.first
        end

        it "adds the new document to the relation" do
          expect(post.title).to eq("Testing")
        end

        it "autosaves the relation" do
          expect(user.posts(true).first.title).to eq("Testing")
        end
      end

      context "when the document is freshly loaded from the db" do

        let!(:node) do
          Node.create!
        end

        let!(:server) do
          node.servers.create!(name: "test")
        end

        before do
          node.reload
        end

        context "when updating invalid attributes" do

          let!(:update) do
            node.update_attributes({
              servers_attributes: { "0" => { "_id" => server.id, "name" => "" }}
            })
          end

          it "returns false" do
            expect(update).to be false
          end

          it "does not update the child document" do
            expect(server.reload.name).to eq("test")
          end

          it "adds the errors to the document" do
            expect(node.errors[:servers]).to_not be_nil
          end
        end
      end
    end

    context "when the relation is an embeds many" do

      let(:league) do
        League.create!
      end

      let!(:division) do
        league.divisions.create!(name: "Old Name")
      end

      context "when additional validation is set" do

        before do
          League.validates_presence_of(:divisions)
        end

        after do
          League.reset_callbacks(:validate)
        end

        context "when validation fails" do

          let(:division) do
            Division.new
          end

          let(:league) do
            League.create!(divisions: [division])
          end

          let(:error_raising_update) do
            league.update!(:divisions => nil)
          end

          before do
            league.update(:divisions => nil)
            league.reload
          end

          it "the update raises an error" do
            expect{ error_raising_update }.to raise_error(Mongoid::Errors::Validations)
          end

          it "the update does not occur" do
            expect(league.divisions.first).to eq(division)
          end

          it "the document is inaccurately marked destroyed (you fixed the bug if you broke this!)" do
            expect(division).to be_destroyed
          end
        end
      end

      context "when no additional validation is set" do

        let(:params) do
          { divisions_attributes:
            { "0" => { id: division.id.to_s, name: "New Name" }}
          }
        end

        before do
          league.update_attributes!(params)
        end

        it "sets the nested attributes" do
          expect(league.reload.divisions.first.name).to eq("New Name")
        end

        context "with corrupted data" do

          before do
            league[:league] = params
          end

          let(:new_params) do
            { divisions_attributes:
              { "0" => { id: division.id.to_s, name: "Name" }}
            }
          end

          before do
            league.update_attributes!(new_params)
          end

          it "sets the nested attributes" do
            expect(league.reload.divisions.first.name).to eq("Name")
          end
        end
      end
    end
  end

  context "when destroying has_many child using nested attributes" do
    let(:school) do
      School.create
    end

    let!(:student) do
      school.students.create
    end

    before do
      school.attributes = {
        '_id': school.id,
        'students_attributes': [{
          '_id': student.id,
          '_destroy': 1
          }]
        }
    end

    it "is able to access the parent in the after_destroy callback" do
      expect(school.after_destroy_triggered).to eq(true)
    end
  end

  context "when destroying has_many child using nested attributes" do
    let(:school) do
      HabtmmSchool.create!(students: [student])
    end

    let(:student) do
      HabtmmStudent.create!
    end

    before do
      student.schools << school
      school.attributes = {
        '_id': school.id,
        'students_attributes': [{
          '_id': student.id,
          '_destroy': 1
          }]
        }
    end

    it "is able to access the parent in the after_destroy callback" do
      expect(school.reload.after_destroy_triggered).to eq(true)
    end
  end

  context "when using a multi-leveled nested attribute on a referenced association" do
    let(:author) { NestedAuthor.create }
    let(:one_level_params) { { post_attributes: { title: 'test' } } }
    let(:two_levels_params) { { post_attributes: { comments_attributes: [ { body: 'test' } ] } } }

    it "creates a 1st-depth child model" do
      author.update_attributes(one_level_params)
      expect(author.post.persisted?).to be true
    end

    it "creates a 1st-depth child model, and a 2nd-depth child model" do
      author.update_attributes(two_levels_params)
      expect(author.post.comments.count).to eq 1
    end

    context "the 1st-depth child model already exists" do
      it "creates a 2nd-depth child model" do
        author.create_post(title: 'test')
        author.update_attributes(two_levels_params)
        expect(author.post.comments.count).to eq 1
      end
    end
  end
end
