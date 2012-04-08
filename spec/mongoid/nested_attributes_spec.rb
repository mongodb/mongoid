require "spec_helper"

describe Mongoid::NestedAttributes do

  describe ".accepts_nested_attributes_for" do

    let(:person) do
      Person.new
    end

    before do
      Person.accepts_nested_attributes_for :favorites
    end

    after do
      Person.send(:undef_method, :favorites_attributes=)
      Person.nested_attributes.clear
    end

    it "adds a method for handling the attributes" do
      person.should respond_to(:favorites_attributes=)
    end

    it "adds the method name to the nested attributes list" do
      Person.nested_attributes.should eq([ "favorites_attributes=" ])
    end
  end

  describe "#initialize" do

    context "when the relation is an embeds one" do

      before(:all) do
        Person.send(:undef_method, :name_attributes=)
        Person.accepts_nested_attributes_for :name
      end

      let(:person) do
        Person.new(name_attributes: { first_name: "Johnny" })
      end

      it "sets the nested attributes" do
        person.name.first_name.should eq("Johnny")
      end
    end

    context "when the relation is an embeds many" do

      before(:all) do
        Person.send(:undef_method, :addresses_attributes=)
        Person.accepts_nested_attributes_for :addresses
      end

      let(:person) do
        Person.new(addresses_attributes: { "1" => { street: "Alexanderstr" }})
      end

      it "sets the nested attributes" do
        person.addresses.first.street.should eq("Alexanderstr")
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
          person.addresses.map(&:number).should eq((0..10).to_a)
        end
      end
    end

    context "when the relation is an embedded in" do

      before(:all) do
        Video.accepts_nested_attributes_for :person
      end

      let(:video) do
        Video.new(person_attributes: { title: "Sir" })
      end

      it "sets the nested attributes" do
        video.person.title.should eq("Sir")
      end
    end

    context "when the relation is a references one" do

      before(:all) do
        Person.send(:undef_method, :game_attributes=)
        Person.accepts_nested_attributes_for :game
      end

      let(:person) do
        Person.new(game_attributes: { name: "Tron" })
      end

      it "sets the nested attributes" do
        person.game.name.should eq("Tron")
      end
    end

    context "when the relation is a references many" do

      before(:all) do
        Person.send(:undef_method, :posts_attributes=)
        Person.accepts_nested_attributes_for :posts
      end

      let(:person) do
        Person.new(posts_attributes: { "1" => { title: "First" }})
      end

      it "sets the nested attributes" do
        person.posts.first.title.should eq("First")
      end
    end

    context "when the relation is a references and referenced in many" do

      before(:all) do
        Person.send(:undef_method, :preferences_attributes=)
        Person.accepts_nested_attributes_for :preferences
      end

      let(:person) do
        Person.new(preferences_attributes: { "1" => { name: "First" }})
      end

      it "sets the nested attributes" do
        person.preferences.first.name.should eq("First")
      end
    end

    context "when the relation is a referenced in" do

      before(:all) do
        Post.accepts_nested_attributes_for :person
      end

      let(:post) do
        Post.new(person_attributes: { title: "Sir" })
      end

      it "sets the nested attributes" do
        post.person.title.should eq("Sir")
      end
    end
  end

  describe "##{name}_attributes=" do

    context "when the parent document is new" do

      context "when the relation is an embeds one" do

        context "when the parent document is persisted" do

          let(:person) do
            Person.create
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
              person.name.last_name.should eq("Fischer")
            end

            it "does not persist the child document" do
              person.name.should_not be_persisted
            end

            context "when saving the parent" do

              before do
                person.save
                person.reload
              end

              it "persists the child document" do
                person.name.should be_persisted
              end
            end
          end
        end

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before(:all) do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for \
              :name, reject_if: ->(attrs){ attrs[:first_name].blank? }
          end

          after(:all) do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name
          end

          context "when the attributes match" do

            before do
              person.name_attributes = { last_name: "Lang" }
            end

            it "does not add the document" do
              person.name.should be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.name_attributes = { first_name: "Lang" }
            end

            it "adds the document" do
              person.name.first_name.should eq("Lang")
            end
          end
        end

        context "when :reject_if => :all_blank is specified" do

          before(:all) do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for \
              :name, reject_if: :all_blank
          end

          after(:all) do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name
          end

          context "when all attributes are empty" do

            before do
              person.name_attributes = { last_name: "" }
            end

            it "does not add the document" do
              person.name.should be_nil
            end
          end

          context "when an attribute is non-empty" do

            before do
              person.name_attributes = { first_name: "Lang" }
            end

            it "adds the document" do
              person.name.first_name.should eq("Lang")
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.name_attributes = { first_name: "Leo" }
            end

            it "builds a new document" do
              person.name.first_name.should eq("Leo")
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before(:all) do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, allow_destroy: true
              end

              after(:all) do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              before do
                person.name_attributes = { first_name: "Leo", _destroy: "1" }
              end

              it "does not build the document" do
                person.name.should be_nil
              end
            end

            context "when allow_destroy is false" do

              before(:all) do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, allow_destroy: false
              end

              after(:all) do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              before do
                person.name_attributes = { first_name: "Leo", _destroy: "1" }
              end

              it "builds the document" do
                person.name.first_name.should eq("Leo")
              end
            end
          end

          context "with empty attributes" do

            before do
              person.name_attributes = {}
            end

            it "does not build the document" do
              person.name.should be_nil
            end
          end

          context "when there is an existing document" do

            context "with no destroy attribute" do

              before do
                person.name = Name.new(first_name: "Michael")
                person.name_attributes = { first_name: "Jack" }
              end

              it "replaces the document" do
                person.name.first_name.should eq("Jack")
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: true
                end

                after(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(first_name: "Michael")
                  person.name_attributes = { first_name: "Jack", _destroy: "1" }
                end

                it "does not replace the document" do
                  person.name.first_name.should eq("Michael")
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: false
                end

                after(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(first_name: "Michael")
                  person.name_attributes = { first_name: "Jack", _destroy: "1" }
                end

                it "replaces the document" do
                  person.name.first_name.should eq("Jack")
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
                  person.name.first_name.should eq("Bob")
                end
              end

              context "when passed keys as strings" do

                before do
                  person.name_attributes =
                    { "id" => name.id.to_s, "first_name" => "Bob" }
                end

                it "updates the existing document" do
                  person.name.first_name.should eq("Bob")
                end
              end

              context "when allow_destroy is true" do

                before(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: true
                end

                after(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      person.name_attributes =
                        { id: name.id, _destroy: truth }
                    end

                    it "destroys the existing document" do
                      person.name.should be_nil
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
                      person.name.should eq(name)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, allow_destroy: false
                end

                after(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.name_attributes =
                      { id: name.id, _destroy: true }
                  end

                  it "does not destroy the document" do
                    person.name.should eq(name)
                  end
                end
              end

              context "when update only is true" do

                before(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for \
                    :name,
                    update_only: true,
                    allow_destroy: true
                end

                after(:all) do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when the id matches" do

                  before do
                    person.name_attributes =
                      { id: name.id, first_name: "Ro" }
                  end

                  it "updates the existing document" do
                    person.name.first_name.should eq("Ro")
                  end
                end

                context "when the id does not match" do

                  before do
                    person.name_attributes =
                      { id: BSON::ObjectId.new.to_s, first_name: "Durran" }
                  end

                  it "updates the existing document" do
                    person.name.first_name.should eq("Durran")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.name_attributes =
                      { id: name.id, _destroy: true }
                  end

                  it "destroys the existing document" do
                    person.name.should be_nil
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
                  person.quiz.topic.should eq("English")
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before(:all) do
            Person.validates_associated(:pet)
          end

          after(:all) do
            Person.reset_callbacks(:validate)
          end

          before do
            person.pet_attributes = { name: "$$$" }
          end

          it "propagates invalidity to parent" do
            person.pet.should_not be_valid
            person.should_not be_valid
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
            canvas.writer.class.should eq(HtmlWriter)
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
                animal.person.title.should eq("Sir")
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "does not build a new document" do
                  animal.person.should be_nil
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "builds a new document" do
                  animal.person.title.should eq("Sir")
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
                  animal.person.title.should eq("Sir")
                end
              end
            end

            context "when there is an existing document" do

              before do
                animal.person = person
              end

              context "when allow destroy is true" do

                before(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after(:all) do
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
                      animal.person.should be_nil
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
                      animal.person.should eq(person)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after(:all) do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    animal.person_attributes =
                      { id: person.id, _destroy: true }
                  end

                  it "does not delete the document" do
                    animal.person.should eq(person)
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
                    animal.person.title.should eq("Madam")
                  end
                end

                context "when the id does not match" do

                  before do
                    animal.person_attributes =
                      { id: BSON::ObjectId.new.to_s, title: "Madam" }
                  end

                  it "updates the existing document" do
                    animal.person.title.should eq("Madam")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    animal.person_attributes =
                      { id: person.id, title: "Madam", _destroy: "true" }
                  end

                  it "deletes the existing document" do
                    animal.person.should be_nil
                  end
                end
              end
            end
          end

          context "when the nested document is invalid" do

            before(:all) do
              Person.validates_format_of :ssn, without: /\$\$\$/
            end

            after(:all) do
              Person.reset_callbacks(:validate)
            end

            before do
              animal.person_attributes = { ssn: '$$$' }
            end

            it "does not propagate invalidity to parent" do
              animal.person.should_not be_valid
              animal.should be_valid
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
            tool.palette.class.should eq(BigPalette)
          end
        end
      end

      context "when the relation is an embeds many" do

        context "when the parent document is persisted" do

          let(:person) do
            Person.create
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
              person.addresses.first.street.should eq("Maybachufer")
            end

            it "does not persist the child documents" do
              person.addresses.first.should_not be_persisted
            end

            context "when saving the parent" do

              before do
                person.save
                person.reload
              end

              it "saves the child documents" do
                person.addresses.first.should be_persisted
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

        let(:phone_one) do
          ParanoidPhone.new(number: "1")
        end

        let(:phone_two) do
          ParanoidPhone.new(number: "2")
        end

        context "when a limit is specified" do

          before(:all) do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses, limit: 2
          end

          after(:all) do
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
              person.addresses.size.should eq(2)
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
              person.addresses.size.should eq(2)
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
                person.addresses.first.street.should eq("Maybachufer")
              end

              it "updates the second existing document" do
                person.addresses.second.street.should eq("Alexander Platz")
              end

              it "does not add new documents" do
                person.addresses.size.should eq(2)
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
                  person.addresses.collect { |a| a['street'] }.should include('Maybachufer')
                end

                it "updates the second existing document" do
                  person.addresses.collect { |a| a['street'] }.should include('Alexander Platz')
                end

                it "does not add new documents" do
                  person.addresses.size.should eq(2)
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
                  person.addresses.collect { |a| a['street'] }.should include('Maybachufer')
                end

                it "updates the second existing document" do
                  person.addresses.collect { |a| a['street'] }.should include('Alexander Platz')
                end

                it "does not add new documents" do
                  person.addresses.size.should eq(2)
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
                person.addresses.collect { |a| a['street'] }.should include('Maybachufer')
              end

              it "updates the second existing document" do
                person.addresses.collect { |a| a['street'] }.should include('Alexander Platz')
              end

              it "does not add new documents" do
                person.addresses.size.should eq(2)
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
                person.addresses.collect { |a| a['street'] }.should include('Maybachufer')
              end

              it "updates the second existing document" do
                person.addresses.collect { |a| a['street'] }.should include('Alexander Platz')
              end

              it "does not add new documents" do
                person.addresses.size.should eq(2)
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
                person.addresses.collect { |a| a['street'] }.should include('Maybachufer')
              end

              it "updates the second existing document" do
                person.addresses.collect { |a| a['street'] }.should include('Alexander Platz')
              end

              it "does not add new documents" do
                person.addresses.size.should eq(2)
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.addresses_attributes =
                    { "foo" => { "id" => "test", "street" => "Test" } }
                }.to raise_error
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                context "when the child is not paranoid" do

                  before(:all) do
                    Person.send(:undef_method, :addresses_attributes=)
                    Person.accepts_nested_attributes_for :addresses, allow_destroy: true
                  end

                  after(:all) do
                    Person.send(:undef_method, :addresses_attributes=)
                    Person.accepts_nested_attributes_for :addresses
                  end

                  [ 1, "1", true, "true" ].each do |truth|

                    context "when passed a #{truth} with destroy" do

                      context "when the parent is new" do

                        before do
                          person.addresses_attributes =
                            {
                              "bar" => { "id" => address_one.id.to_s, "_destroy" => truth },
                              "foo" => { "id" => address_two.id, "street" => "Alexander Platz" }
                            }
                        end

                        it "deletes the marked document" do
                          person.addresses.size.should eq(1)
                        end

                        it "does not delete the unmarked document" do
                          person.addresses.first.street.should eq("Alexander Platz")
                        end
                      end

                      context "when the parent is persisted" do

                        let!(:persisted) do
                          Person.create do |p|
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

                          it "removes the first document from the relation" do
                            persisted.addresses.size.should eq(2)
                          end

                          it "does not delete the unmarked document" do
                            persisted.addresses.first.street.should eq(
                              "Alexander Platz"
                            )
                          end

                          it "adds the new document to the relation" do
                            persisted.addresses.last.street.should eq(
                              "Potsdammer Platz"
                            )
                          end

                          it "has the proper persisted count" do
                            persisted.addresses.count.should eq(1)
                          end

                          it "does not delete the removed document" do
                            address_one.should_not be_destroyed
                          end

                          context "when saving the parent" do

                            before do
                              persisted.with(safe: true).save
                            end

                            it "deletes the marked document from the relation" do
                              persisted.reload.addresses.count.should eq(2)
                            end

                            it "does not delete the unmarked document" do
                              persisted.reload.addresses.first.street.should eq(
                                "Alexander Platz"
                              )
                            end

                            it "persists the new document to the relation" do
                              persisted.reload.addresses.last.street.should eq(
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

                          it "removes the first document from the relation" do
                            persisted.addresses.size.should eq(2)
                          end

                          it "adds the new document to the relation" do
                            persisted.addresses.last.street.should eq(
                              "Potsdammer Platz"
                            )
                          end

                          it "has the proper persisted count" do
                            persisted.addresses.count.should eq(1)
                          end

                          it "does not delete the removed document" do
                            address_one.should_not be_destroyed
                          end

                          context "when saving the parent" do

                            before do
                              persisted.with(safe: true).save
                            end

                            it "deletes the marked document from the relation" do
                              persisted.reload.addresses.count.should eq(2)
                            end

                            it "persists the new document to the relation" do
                              persisted.reload.addresses.last.street.should eq(
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
                        person.addresses.size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.addresses.last.street.should eq("Alexander Platz")
                      end
                    end
                  end
                end

                context "when the child is paranoid" do

                  before(:all) do
                    Person.send(:undef_method, :paranoid_phones_attributes=)
                    Person.accepts_nested_attributes_for :paranoid_phones,
                      allow_destroy: true
                  end

                  after(:all) do
                    Person.send(:undef_method, :paranoid_phones_attributes=)
                    Person.accepts_nested_attributes_for :paranoid_phones
                  end

                  [ 1, "1", true, "true" ].each do |truth|

                    context "when passed a #{truth} with destroy" do

                      context "when the parent is persisted" do

                        let!(:persisted) do
                          Person.create do |p|
                            p.paranoid_phones << [ phone_one, phone_two ]
                          end
                        end

                        context "when setting, pulling, and pushing in one op" do

                          before do
                            persisted.paranoid_phones_attributes =
                              {
                                "bar" => { "id" => phone_one.id, "_destroy" => truth },
                                "foo" => { "id" => phone_two.id, "number" => "3" },
                                "baz" => { "number" => "4" }
                              }
                          end

                          it "removes the first document from the relation" do
                            persisted.paranoid_phones.size.should eq(2)
                          end

                          it "does not delete the unmarked document" do
                            persisted.paranoid_phones.first.number.should eq("3")
                          end

                          it "adds the new document to the relation" do
                            persisted.paranoid_phones.last.number.should eq("4")
                          end

                          it "has the proper persisted count" do
                            persisted.paranoid_phones.count.should eq(1)
                          end

                          it "soft deletes the removed document" do
                            phone_one.should be_destroyed
                          end

                          context "when saving the parent" do

                            before do
                              persisted.with(safe: true).save
                            end

                            it "deletes the marked document from the relation" do
                              persisted.reload.paranoid_phones.count.should eq(2)
                            end

                            it "does not delete the unmarked document" do
                              persisted.reload.paranoid_phones.first.number.should eq("3")
                            end

                            it "persists the new document to the relation" do
                              persisted.reload.paranoid_phones.last.number.should eq("4")
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses, allow_destroy: false
                end

                after(:all) do
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
                      person.addresses.first.street.should eq("Maybachufer")
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should eq("Alexander Platz")
                    end

                    it "does not add additional documents" do
                      person.addresses.size.should eq(2)
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
                      person.addresses.size.should eq(2)
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should eq("Alexander Platz")
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before(:all) do
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
                      person.addresses.first.street.should eq("Maybachufer")
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should eq("Alexander Platz")
                    end

                    it "does not add additional documents" do
                      person.addresses.size.should eq(2)
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
                      person.addresses.size.should eq(2)
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should eq("Alexander Platz")
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
              person.addresses.first.street.should eq("Frederichstrasse")
            end

            it "builds a new second document" do
              person.addresses.second.street.should eq("Alexander Platz")
            end

            it "builds a new third document" do
              person.addresses.third.street.should eq("Maybachufer")
            end

            it "does not add extra documents" do
              person.addresses.size.should eq(3)
            end

            it "adds the documents in the sorted hash key order" do
              person.addresses.map(&:street).should eq(
                [ "Frederichstrasse", "Alexander Platz", "Maybachufer" ]
              )
            end
          end

          context "when a reject block is supplied" do

            before(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: ->(attrs){ attrs["street"].blank? }
            end

            after(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when the attributes match" do

              before do
                person.addresses_attributes =
                  { "3" => { "city" => "Berlin" } }
              end

              it "does not add the new document" do
                person.addresses.should be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.addresses_attributes =
                  { "3" => { "street" => "Maybachufer" } }
              end

              it "adds the new document" do
                person.addresses.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.addresses.first.street.should eq("Maybachufer")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: :all_blank
            end

            after(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when all attributes are empty" do

              before do
                person.addresses_attributes =
                  { "3" => { "city" => "" } }
              end

              it "does not add the new document" do
                person.addresses.should be_empty
              end
            end

            context "when an attribute is not-empty" do

              before do
                person.addresses_attributes =
                  { "3" => { "street" => "Maybachufer" } }
              end

              it "adds the new document" do
                person.addresses.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.addresses.first.street.should eq("Maybachufer")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before(:all) do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, allow_destroy: true
              end

              after(:all) do
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

                  it "ignores the the marked document" do
                    person.addresses.size.should eq(1)
                  end

                  it "adds the new unmarked document" do
                    person.addresses.first.street.should eq("Alexander Platz")
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
                    person.addresses.first.street.should eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before(:all) do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, allow_destroy: false
              end

              after(:all) do
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

                  it "adds the the marked document" do
                    person.addresses.first.street.should eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should eq("Alexander Platz")
                  end

                  it "adds the correct number of documents" do
                    person.addresses.size.should eq(2)
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
                    person.addresses.first.street.should eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before(:all) do
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

                  it "adds the the marked document" do
                    person.addresses.first.street.should eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should eq("Alexander Platz")
                  end

                  it "adds the correct number of documents" do
                    person.addresses.size.should eq(2)
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
                    person.addresses.first.street.should eq("Maybachufer")
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should eq("Alexander Platz")
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should eq(2)
                  end
                end
              end
            end
          end

          context "when 'reject_if: :all_blank' and 'allow_destroy: true' are specified" do

            before(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, reject_if: :all_blank, allow_destroy: true
            end

            after(:all) do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for :addresses
            end

            context "when all attributes are blank and _destroy has a truthy, non-blank value" do

              before do
                person.addresses_attributes =
                  { "3" => { last_name: "", _destroy: "0" } }
              end

              it "does not add the document" do
                person.addresses.should be_empty
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before(:all) do
            Person.validates_associated(:addresses)
          end

          after(:all) do
            Person.reset_callbacks(:validate)
          end

          before do
            person.addresses_attributes = {
              "0" => { street: '123' }
            }
          end

          it "propagates invalidity to parent" do
            person.addresses.first.should_not be_valid
            person.should_not be_valid
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
            canvas.shapes.map(&:class).should eq([Square, Circle])
          end
        end
      end

      context "when the relation is a references one" do

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before(:all) do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for \
              :game, reject_if: ->(attrs){ attrs[:name].blank? }
          end

          after(:all) do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for :game
          end

          context "when the attributes match" do

            before do
              person.game_attributes = { score: 10 }
            end

            it "does not add the document" do
              person.game.should be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "adds the document" do
              person.game.name.should eq("Tron")
            end
          end
        end

        context "when reject_if => :all_blank is specified" do

          before(:all) do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for \
              :game, reject_if: :all_blank
          end

          after(:all) do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for :game
          end

          context "when all attributes are empty" do

            before do
              person.game_attributes = { score: nil }
            end

            it "does not add the document" do
              person.game.should be_nil
            end
          end

          context "when an attribute is non-empty" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "adds the document" do
              person.game.name.should eq("Tron")
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.game_attributes = { name: "Tron" }
            end

            it "builds a new document" do
              person.game.name.should eq("Tron")
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before(:all) do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, allow_destroy: true
              end

              after(:all) do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { name: "Tron", _destroy: "1" }
              end

              it "does not build the document" do
                person.game.should be_nil
              end
            end

            context "when allow_destroy is false" do

              before(:all) do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, allow_destroy: false
              end

              after(:all) do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { name: "Tron", _destroy: "1" }
              end

              it "builds the document" do
                person.game.name.should eq("Tron")
              end
            end
          end

          context "with empty attributes" do

            before do
              person.game_attributes = {}
            end

            it "does not build the document" do
              person.game.should be_nil
            end
          end

          context "when there is an existing document" do

            context "with no destroy attribute" do

              before do
                person.game = Game.new(name: "Tron")
                person.game_attributes = { name: "Pong" }
              end

              it "replaces the document" do
                person.game.name.should eq("Pong")
              end
            end

            context "when updating attributes" do

              let!(:pizza) do
                Pizza.create(name: "large")
              end

              before do
                pizza.topping = Topping.create(name: "cheese")
                pizza.update_attributes(topping_attributes: { name: "onions" })
              end

              it "persists the attribute changes" do
                pizza.reload.topping.name.should eq("onions")
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: true
                end

                after(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(name: "Tron")
                  person.game_attributes = { name: "Pong", _destroy: "1" }
                end

                it "does not replace the document" do
                  person.game.name.should eq("Tron")
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: false
                end

                after(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(name: "Tron")
                  person.game_attributes = { name: "Pong", _destroy: "1" }
                end

                it "replaces the document" do
                  person.game.name.should eq("Pong")
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
                  person.game.name.should eq("Pong")
                end
              end

              context "when passed keys as strings" do

                before do
                  person.game_attributes =
                    { "id" => game.id, "name" => "Pong" }
                end

                it "updates the existing document" do
                  person.game.name.should eq("Pong")
                end
              end

              context "when allow_destroy is true" do

                before(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: true
                end

                after(:all) do
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
                      person.game.should be_nil
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
                      person.game.should eq(game)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, allow_destroy: false
                end

                after(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.game_attributes =
                      { id: game.id, _destroy: true }
                  end

                  it "does not destroy the document" do
                    person.game.should eq(game)
                  end
                end
              end

              context "when update only is true" do

                before(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for \
                    :game,
                    update_only: true,
                    allow_destroy: true
                end

                after(:all) do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when the id matches" do

                  before do
                    person.game_attributes =
                      { id: game.id, name: "Donkey Kong" }
                  end

                  it "updates the existing document" do
                    person.game.name.should eq("Donkey Kong")
                  end
                end

                context "when the id does not match" do

                  before do
                    person.game_attributes =
                      { id: BSON::ObjectId.new.to_s, name: "Pong" }
                  end

                  it "updates the existing document" do
                    person.game.name.should eq("Pong")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.game_attributes =
                      { id: game.id, _destroy: true }
                  end

                  it "destroys the existing document" do
                    person.game.should be_nil
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before(:all) do
            Person.validates_associated(:game)
          end

          after(:all) do
            Person.reset_callbacks(:validate)
          end

          before do
            person.game_attributes = { name: '$$$' }
          end

          it "propagates invalidity to parent" do
            person.game.should_not be_valid
            person.should_not be_valid
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
            driver.vehicle.class.should eq(Truck)
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
                game.person.title.should eq("Sir")
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "does not build a new document" do
                  game.person.should be_nil
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { title: "Sir", _destroy: 1 }
                end

                it "builds a new document" do
                  game.person.title.should eq("Sir")
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
                  game.person.title.should eq("Sir")
                end
              end
            end

            context "when there is an existing document" do

              before do
                game.person = person
              end

              context "when allow destroy is true" do

                before(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: true
                end

                after(:all) do
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
                      game.person.should be_nil
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
                      game.person.should eq(person)
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, allow_destroy: false
                end

                after(:all) do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    game.person_attributes =
                      { id: person.id, _destroy: true }
                  end

                  it "does not delete the document" do
                    game.person.should eq(person)
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
                    game.person.title.should eq("Madam")
                  end
                end

                context "when the id does not match" do

                  before do
                    game.person_attributes =
                      { id: BSON::ObjectId.new.to_s, title: "Madam" }
                  end

                  it "updates the existing document" do
                    game.person.title.should eq("Madam")
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    game.person_attributes =
                      { id: person.id, title: "Madam", _destroy: "true" }
                  end

                  it "deletes the existing document" do
                    game.person.should be_nil
                  end
                end
              end
            end
          end

          context "when the nested document is invalid" do

            before(:all) do
              Person.validates_format_of :ssn, without: /\$\$\$/
            end

            after(:all) do
              Person.reset_callbacks(:validate)
            end

            before do
              game.person_attributes = { ssn: '$$$' }
            end

            it "propagates invalidity to parent" do
              game.person.should_not be_valid
              game.should_not be_valid
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
            vehicle.driver.class.should eq(Learner)
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

          before(:all) do
            Person.send(:undef_method, :posts_attributes=)
            Person.accepts_nested_attributes_for :posts, limit: 2
          end

          after(:all) do
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
              person.posts.size.should eq(2)
            end

            it "does not persist the new documents" do
              person.posts.count.should eq(0)
            end
          end
        end

        context "when ids are passed" do

          let(:person) do
            Person.create
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
                  person.posts(true).first.title.should eq("First")
                end

                it "updates the second existing document" do
                  person.posts(true).last.title.should eq("Second")
                end

                it "does not add new documents" do
                  person.posts(true).size.should eq(2)
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
                  }.to raise_error(Mongoid::Errors::DocumentNotFound)
                end
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.posts_attributes =
                    { "foo" => { "id" => "test", "title" => "Test" } }
                }.to raise_error
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
                        person.posts(true).size.should eq(1)
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).first.title.should eq("My Blog")
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
                        person.posts(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).map(&:title).should include("My Blog")
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
                        person.posts(true).first.title.should eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).last.title.should eq("New Title")
                      end

                      it "does not add additional documents" do
                        person.posts(true).size.should eq(2)
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
                        person.posts(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).last.title.should eq("New Title")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before(:all) do
                  Person.send(:undef_method, :posts_attributes=)
                  Person.accepts_nested_attributes_for :posts
                end

                after(:all) do
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
                        person.posts(true).find(post_one.id).title.should eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).find(post_two.id).title.should eq("New Title")
                      end

                      it "does not add additional documents" do
                        person.posts(true).size.should eq(2)
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
                        person.posts(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.posts(true).last.title.should eq("New Title")
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
                person.posts.first.title.should eq("First")
              end

              it "builds a new second document" do
                person.posts.second.title.should eq("Second")
              end

              it "builds a new third document" do
                person.posts.third.title.should eq("Third")
              end

              it "does not add extra documents" do
                person.posts.size.should eq(3)
              end

              it "does not persist the documents" do
                person.posts.count.should eq(0)
              end

              it "adds the documents in the sorted hash key order" do
                person.posts.map(&:title).should eq(
                  [ "First", "Second", "Third" ]
                )
              end
            end

            context "when passing an array of attributes" do

              context "when the parent is saved" do

                before do
                  person.save
                  person.posts_attributes =
                    [
                      { "title" => "Third" },
                      { "title" => "First" },
                      { "title" => "Second" }
                    ]
                end

                it "builds a new first document" do
                  person.posts.first.title.should eq("Third")
                end

                it "builds a new second document" do
                  person.posts.second.title.should eq("First")
                end

                it "builds a new third document" do
                  person.posts.third.title.should eq("Second")
                end

                it "does not add extra documents" do
                  person.posts.size.should eq(3)
                end

                it "does not persist the documents" do
                  person.posts.count.should eq(0)
                end
              end
            end
          end

          context "when a reject block is supplied" do

            before(:all) do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for \
                :posts, reject_if: ->(attrs){ attrs["title"].blank? }
            end

            after(:all) do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for :posts
            end

            context "when the attributes match" do

              before do
                person.posts_attributes =
                  { "3" => { "content" => "My first blog" } }
              end

              it "does not add the new document" do
                person.posts.should be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.posts_attributes =
                  { "3" => { "title" => "Blogging" } }
              end

              it "adds the new document" do
                person.posts.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.posts.first.title.should eq("Blogging")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before(:all) do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for \
                :posts, reject_if: :all_blank
            end

            after(:all) do
              Person.send(:undef_method, :posts_attributes=)
              Person.accepts_nested_attributes_for :posts
            end

            context "when all attributes are blank" do

              before do
                person.posts_attributes =
                  { "3" => { "content" => "" } }
              end

              it "does not add the new document" do
                person.posts.should be_empty
              end
            end

            context "when an attribute is non-empty" do

              before do
                person.posts_attributes =
                  { "3" => { "title" => "Blogging" } }
              end

              it "adds the new document" do
                person.posts.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.posts.first.title.should eq("Blogging")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before(:all) do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts, allow_destroy: true
              end

              after(:all) do
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

                  it "ignores the the marked document" do
                    person.posts.size.should eq(1)
                  end

                  it "adds the new unmarked document" do
                    person.posts.first.title.should eq("Blog Two")
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
                    person.posts.first.title.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.posts.last.title.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.posts.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before(:all) do
                Person.send(:undef_method, :posts_attributes=)
                Person.accepts_nested_attributes_for :posts, allow_destroy: false
              end

              after(:all) do
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

                  it "adds the the marked document" do
                    person.posts.first.title.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.posts.last.title.should eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    person.posts.size.should eq(2)
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
                    person.posts.first.title.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.posts.last.title.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.posts.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before(:all) do
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

                  it "adds the the marked document" do
                    person.posts.first.title.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.posts.last.title.should eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    person.posts.size.should eq(2)
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
                    person.posts.first.title.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.posts.last.title.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.posts.size.should eq(2)
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before(:all) do
            Person.validates_associated(:posts)
          end

          after(:all) do
            Person.reset_callbacks(:validate)
          end

          before do
            person.posts_attributes = {
              "0" => { title: "$$$" }
            }
          end

          it "propagates invalidity to parent" do
            person.should_not be_valid
            person.posts.first.should_not be_valid
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
            shipping_container.vehicles.map(&:class).should eq([Car, Truck])
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

          before(:all) do
            Person.send(:undef_method, :preferences_attributes=)
            Person.accepts_nested_attributes_for :preferences, limit: 2
          end

          after(:all) do
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
              person.preferences.size.should eq(2)
            end
          end
        end

        context "when ids are passed" do

          let(:person) do
            Person.create
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
                  person.preferences(true).first.name.should eq("First")
                end

                it "updates the second existing document" do
                  person.preferences(true).second.name.should eq("Second")
                end

                it "does not add new documents" do
                  person.preferences(true).size.should eq(2)
                end
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.preferences_attributes =
                    { "foo" => { "id" => "test", "name" => "Test" } }
                }.to raise_error
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                before(:all) do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences, allow_destroy: true
                end

                after(:all) do
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
                        person.preferences(true).size.should eq(1)
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).first.name.should eq("My Blog")
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
                        person.preferences(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).last.name.should eq("My Blog")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before(:all) do
                  Person.send(:undef_method, :preferences_attributes=)
                  Person.accepts_nested_attributes_for :preferences, allow_destroy: false
                end

                after(:all) do
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
                        person.preferences(true).first.name.should eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).last.name.should eq("New Title")
                      end

                      it "does not add additional documents" do
                        person.preferences(true).size.should eq(2)
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
                        person.preferences(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).last.name.should eq("New Title")
                      end
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before(:all) do
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
                        person.preferences(true).first.name.should eq("Another Title")
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).last.name.should eq("New Title")
                      end

                      it "does not add additional documents" do
                        person.preferences(true).size.should eq(2)
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
                        person.preferences(true).size.should eq(2)
                      end

                      it "does not delete the unmarked document" do
                        person.preferences(true).last.name.should eq("New Title")
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
              person.preferences.first.name.should eq("First")
            end

            it "builds a new second document" do
              person.preferences.second.name.should eq("Second")
            end

            it "builds a new third document" do
              person.preferences.third.name.should eq("Third")
            end

            it "does not add extra documents" do
              person.preferences.size.should eq(3)
            end

            it "adds the documents in the sorted hash key order" do
              person.preferences.map(&:name).should eq(
                [ "First", "Second", "Third" ]
              )
            end
          end

          context "when a reject block is supplied" do

            before(:all) do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for \
                :preferences, reject_if: ->(attrs){ attrs["name"].blank? }
            end

            after(:all) do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for :preferences
            end

            context "when the attributes match" do

              before do
                person.preferences_attributes =
                  { "3" => { "content" => "My first blog" } }
              end

              it "does not add the new document" do
                person.preferences.should be_empty
              end
            end

            context "when the attributes do not match" do

              before do
                person.preferences_attributes =
                  { "3" => { "name" => "Blogging" } }
              end

              it "adds the new document" do
                person.preferences.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.preferences.first.name.should eq("Blogging")
              end
            end
          end

          context "when :reject_if => :all_blank is supplied" do

            before(:all) do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for \
                :preferences, reject_if: :all_blank
            end

            after(:all) do
              Person.send(:undef_method, :preferences_attributes=)
              Person.accepts_nested_attributes_for :preferences
            end

            context "when all attributes are empty" do

              before do
                person.preferences_attributes =
                  { "3" => { "content" => "" } }
              end

              it "does not add the new document" do
                person.preferences.should be_empty
              end
            end

            context "when an attribute is non-empty" do

              before do
                person.preferences_attributes =
                  { "3" => { "name" => "Blogging" } }
              end

              it "adds the new document" do
                person.preferences.size.should eq(1)
              end

              it "sets the correct attributes" do
                person.preferences.first.name.should eq("Blogging")
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before(:all) do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences, allow_destroy: true
              end

              after(:all) do
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

                  it "ignores the the marked document" do
                    person.preferences.size.should eq(1)
                  end

                  it "adds the new unmarked document" do
                    person.preferences.first.name.should eq("Blog Two")
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
                    person.preferences.first.name.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.preferences.last.name.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.preferences.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before(:all) do
                Person.send(:undef_method, :preferences_attributes=)
                Person.accepts_nested_attributes_for :preferences, allow_destroy: false
              end

              after(:all) do
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

                  it "adds the the marked document" do
                    person.preferences.first.name.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.preferences.last.name.should eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    person.preferences.size.should eq(2)
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
                    person.preferences.first.name.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.preferences.last.name.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.preferences.size.should eq(2)
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before(:all) do
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

                  it "adds the the marked document" do
                    person.preferences.first.name.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.preferences.last.name.should eq("Blog Two")
                  end

                  it "adds the correct number of documents" do
                    person.preferences.size.should eq(2)
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
                    person.preferences.first.name.should eq("New Blog")
                  end

                  it "adds the new unmarked document" do
                    person.preferences.last.name.should eq("Blog Two")
                  end

                  it "does not add extra documents" do
                    person.preferences.size.should eq(2)
                  end
                end
              end
            end
          end
        end

        context "when the nested document is invalid" do

          before(:all) do
            Person.validates_associated(:preferences)
          end

          after(:all) do
            Person.reset_callbacks(:validate)
          end

          before do
            person.preferences_attributes = {
              "0" => { name: 'x' }
            }
          end

          it "propagates invalidity to parent" do
            person.preferences.first.should_not be_valid
            person.should_not be_valid
          end
        end
      end
    end
  end

  describe "#update_attributes" do

    before(:all) do
      Person.send(:undef_method, :addresses_attributes=)
      Person.accepts_nested_attributes_for :addresses
    end

    context "when deleting the child document" do

      let(:person) do
        Person.create
      end

      let!(:service) do
        person.services.create(sid: "123")
      end

      let(:attributes) do
        { services_attributes:
          { "0" =>
            { _id: service.id, sid: service.sid, _destroy: 1 }
          }
        }
      end

      before do
        person.update_attributes(attributes)
      end

      it "removes the document from the parent" do
        person.services.should be_empty
      end

      it "deletes the document" do
        service.should be_destroyed
      end

      it "runs the before destroy callbacks" do
        service.before_destroy_called.should be_true
      end

      it "runs the after destroy callbacks" do
        service.after_destroy_called.should be_true
      end

      it "clears the delayed atomic pulls from the parent" do
        person.delayed_atomic_pulls.should be_empty
      end
    end

    context "when nesting multiple levels" do

      let(:person) do
        Person.create
      end

      context "when second level is a one to many" do

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
          person.with(safe: true).update_attributes(attributes)
        end

        let(:address) do
          person.addresses.first
        end

        let(:location) do
          address.locations.first
        end

        it "adds the new first level embedded document" do
          address.street.should eq("Alexanderstr")
        end

        it "adds the nested embedded document" do
          location.name.should eq("Home")
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
            person.with(safe: true).update_attributes(attributes)
          end

          let(:address) do
            person.addresses.first
          end

          let(:code) do
            address.code
          end

          it "adds the new first level embedded document" do
            address.street.should eq("Alexanderstr")
          end

          it "adds the nested embedded document" do
            code.name.should eq("Home")
          end
        end
      end

      context "when the nested document is getting updated" do

        context "when the nested document is not polymorphic" do

          let!(:address) do
            person.addresses.create(street: "Alexanderstr", number: 1)
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
            person.with(safe: true).update_attributes(attributes)
          end

          it "updates the first level embedded document" do
            address.number.should eq(45)
          end

          it "updates the nested embedded document" do
            code.name.should eq("Work")
          end
        end

        context "when the nested document is polymorphic" do

          context "when the first level is an embeds many" do

            let!(:address) do
              person.addresses.create(street: "Alexanderstr", number: 1)
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
              person.with(safe: true).update_attributes(attributes)
            end

            it "updates the first level embedded document" do
              address.number.should eq(45)
            end

            it "updates the nested embedded document" do
              target.name.should eq("updated")
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
                person.with(safe: true).update_attributes(attributes)
              end

              it "updates the nested embedded document" do
                language.name.should eq("deutsch")
              end
            end
          end
        end
      end
    end

    context "when the relation is a has many" do

      let(:user) do
        User.create
      end

      let(:params) do
        { posts_attributes:
          { "0" => { title: "Testing" }}
        }
      end

      before do
        user.update_attributes(params)
      end

      it "adds the new document to the relation" do
        user.posts.first.title.should eq("Testing")
      end

      it "autosaves the relation" do
        user.posts(true).first.title.should eq("Testing")
      end
    end

    context "when the relation is an embeds many" do

      let(:league) do
        League.create
      end

      let!(:division) do
        league.divisions.create(name: "Old Name")
      end

      let(:params) do
        { divisions_attributes:
          { "0" => { id: division.id.to_s, name: "New Name" }}
        }
      end

      before do
        league.update_attributes(params)
      end

      it "sets the nested attributes" do
        league.reload.divisions.first.name.should eq("New Name")
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
          league.update_attributes(new_params)
        end

        it "sets the nested attributes" do
          league.reload.divisions.first.name.should eq("Name")
        end
      end
    end
  end
end
