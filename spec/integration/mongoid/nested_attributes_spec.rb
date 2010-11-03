require "spec_helper"

describe Mongoid::NestedAttributes do

  describe "##{name}_attributes=" do

    context "when the parent document is new" do

      context "when the relation is an embeds one" do

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before :all do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for \
              :name, :reject_if => lambda { |attrs| attrs[:first_name].blank? }
          end

          after :all do
            Person.send(:undef_method, :name_attributes=)
            Person.accepts_nested_attributes_for :name
          end

          context "when the attributes match" do

            before do
              person.name_attributes = { :last_name => "Lang" }
            end

            it "does not add the document" do
              person.name.should be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.name_attributes = { :first_name => "Lang" }
            end

            it "adds the document" do
              person.name.first_name.should == "Lang"
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.name_attributes = { :first_name => "Leo" }
            end

            it "builds a new document" do
              person.name.first_name.should == "Leo"
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before :all do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, :allow_destroy => true
              end

              after :all do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              before do
                person.name_attributes = { :first_name => "Leo", :_destroy => "1" }
              end

              it "does not build the document" do
                person.name.should be_nil
              end
            end

            context "when allow_destroy is false" do

              before :all do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name, :allow_destroy => false
              end

              after :all do
                Person.send(:undef_method, :name_attributes=)
                Person.accepts_nested_attributes_for :name
              end

              before do
                person.name_attributes = { :first_name => "Leo", :_destroy => "1" }
              end

              it "builds the document" do
                person.name.first_name.should == "Leo"
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
                person.name = Name.new(:first_name => "Michael")
                person.name_attributes = { :first_name => "Jack" }
              end

              it "replaces the document" do
                person.name.first_name.should == "Jack"
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(:first_name => "Michael")
                  person.name_attributes = { :first_name => "Jack", :_destroy => "1" }
                end

                it "does not replace the document" do
                  person.name.first_name.should == "Michael"
                end
              end

              context "when allow_destroy is false" do

                before :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :allow_destroy => false
                end

                after :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                before do
                  person.name = Name.new(:first_name => "Michael")
                  person.name_attributes = { :first_name => "Jack", :_destroy => "1" }
                end

                it "replaces the document" do
                  person.name.first_name.should == "Jack"
                end
              end
            end
          end
        end

        context "when an id is passed" do

          context "when there is an existing record" do

            let(:name) do
              Name.new(:first_name => "Joe")
            end

            before do
              person.name = name
            end

            context "when the id matches" do

              context "when passed keys as symbols" do

                before do
                  person.name_attributes =
                    { :_id => name.id.to_s, :first_name => "Bob" }
                end

                it "updates the existing document" do
                  person.name.first_name.should == "Bob"
                end
              end

              context "when passed keys as strings" do

                before do
                  person.name_attributes =
                    { "_id" => name.id.to_s, "first_name" => "Bob" }
                end

                it "updates the existing document" do
                  person.name.first_name.should == "Bob"
                end
              end

              context "when allow_destroy is true" do

                before :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      person.name_attributes =
                        { :_id => name.id, :_destroy => truth }
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
                        { :_id => name.id, :_destroy => falsehood }
                    end

                    it "does not destroy the existing document" do
                      person.name.should == name
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :allow_destroy => false
                end

                after :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.name_attributes =
                      { :_id => name.id, :_destroy => true }
                  end

                  it "does not destroy the document" do
                    person.name.should == name
                  end
                end
              end

              context "when update only is true" do

                before :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for \
                    :name,
                    :update_only => true,
                    :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name
                end

                context "when the id matches" do

                  before do
                    person.name_attributes =
                      { :_id => name.id, :first_name => "Ro" }
                  end

                  it "updates the existing document" do
                    person.name.first_name.should == "Ro"
                  end
                end

                context "when the id does not match" do

                  before do
                    person.name_attributes =
                      { :_id => "1", :first_name => "Durran" }
                  end

                  it "updates the existing document" do
                    person.name.first_name.should == "Durran"
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.name_attributes =
                      { :_id => name.id, :_destroy => true }
                  end

                  it "destroys the existing document" do
                    person.name.should be_nil
                  end
                end
              end
            end
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
                animal.person_attributes = { :title => "Sir" }
              end

              it "builds a new document" do
                animal.person.title.should == "Sir"
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, :allow_destroy => true
                end

                after :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { :title => "Sir", :_destroy => 1 }
                end

                it "does not build a new document" do
                  animal.person.should be_nil
                end
              end

              context "when allow_destroy is false" do

                before :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, :allow_destroy => false
                end

                after :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                before do
                  animal.person_attributes = { :title => "Sir", :_destroy => 1 }
                end

                it "builds a new document" do
                  animal.person.title.should == "Sir"
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
                  animal.person_attributes = { :_id => person.id, :title => "Sir" }
                end

                it "updates the existing document" do
                  animal.person.title.should == "Sir"
                end
              end
            end

            context "when there is an existing document" do

              before do
                animal.person = person
              end

              context "when allow destroy is true" do

                before :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, :allow_destroy => true
                end

                after :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      animal.person_attributes =
                        { :_id => person.id, :_destroy => truth }
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
                        { :_id => person.id, :_destroy => falsehood }
                    end

                    it "does not destroy the existing document" do
                      animal.person.should == person
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, :allow_destroy => false
                end

                after :all do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    animal.person_attributes =
                      { :_id => person.id, :_destroy => true }
                  end

                  it "does not delete the document" do
                    animal.person.should == person
                  end
                end
              end

              context "when update only is true" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for \
                    :person,
                    :update_only => true,
                    :allow_destroy => true
                end

                context "when the id matches" do

                  before do
                    animal.person_attributes =
                      { :_id => person.id, :title => "Madam" }
                  end

                  it "updates the existing document" do
                    animal.person.title.should == "Madam"
                  end
                end

                context "when the id does not match" do

                  before do
                    animal.person_attributes =
                      { :_id => "1", :title => "Madam" }
                  end

                  it "updates the existing document" do
                    animal.person.title.should == "Madam"
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    animal.person_attributes =
                      { :_id => person.id, :title => "Madam", :_destroy => "true" }
                  end

                  it "deletes the existing document" do
                    animal.person.should be_nil
                  end
                end
              end
            end
          end
        end
      end

      context "when the relation is an embeds many" do

        let(:person) do
          Person.new
        end

        let(:address_one) do
          Address.new(:street => "Unter den Linden")
        end

        let(:address_two) do
          Address.new(:street => "Kurfeurstendamm")
        end

        context "when a limit is specified" do

          before :all do
            Person.send(:undef_method, :addresses_attributes=)
            Person.accepts_nested_attributes_for :addresses, :limit => 2
          end

          after :all do
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
              person.addresses.size.should == 2
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
                    "foo" => { "_id" => address_one.id, "street" => "Maybachufer" },
                    "bar" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                  }
              end

              it "updates the first existing document" do
                person.addresses.first.street.should == "Maybachufer"
              end

              it "updates the second existing document" do
                person.addresses.second.street.should == "Alexander Platz"
              end

              it "does not add new documents" do
                person.addresses.size.should == 2
              end
            end

            context "when the ids do not match" do

              it "raises an error" do
                expect {
                  person.addresses_attributes =
                    { "foo" => { "_id" => "test", "street" => "Test" } }
                }.to raise_error
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when the ids match" do

              context "when allow_destroy is true" do

                before :all do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses, :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "_id" => address_one.id, "_destroy" => truth },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "deletes the marked document" do
                      person.addresses.size.should == 1
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.first.street.should == "Alexander Platz"
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "_id" => address_one.id, "_destroy" => falsehood },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not delete the marked document" do
                      person.addresses.size.should == 2
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should == "Alexander Platz"
                    end
                  end
                end
              end

              context "when allow_destroy is false" do

                before :all do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses, :allow_destroy => false
                end

                after :all do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => {
                            "_id" => address_one.id, "street" => "Maybachufer", "_destroy" => truth },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not ignore the marked document" do
                      person.addresses.first.street.should == "Maybachufer"
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should == "Alexander Platz"
                    end

                    it "does not add additional documents" do
                      person.addresses.size.should == 2
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "_id" => address_one.id, "_destroy" => falsehood },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not delete the marked document" do
                      person.addresses.size.should == 2
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should == "Alexander Platz"
                    end
                  end
                end
              end

              context "when allow_destroy is undefined" do

                before :all do
                  Person.send(:undef_method, :addresses_attributes=)
                  Person.accepts_nested_attributes_for :addresses
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed a #{truth} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => {
                            "_id" => address_one.id, "street" => "Maybachufer", "_destroy" => truth },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not ignore the marked document" do
                      person.addresses.first.street.should == "Maybachufer"
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should == "Alexander Platz"
                    end

                    it "does not add additional documents" do
                      person.addresses.size.should == 2
                    end
                  end
                end

                [ 0, "0", false, "false" ].each do |falsehood|

                  context "when passed a #{falsehood} with destroy" do

                    before do
                      person.addresses_attributes =
                        {
                          "bar" => { "_id" => address_one.id, "_destroy" => falsehood },
                          "foo" => { "_id" => address_two.id, "street" => "Alexander Platz" }
                        }
                    end

                    it "does not delete the marked document" do
                      person.addresses.size.should == 2
                    end

                    it "does not delete the unmarked document" do
                      person.addresses.last.street.should == "Alexander Platz"
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
              person.addresses.first.street.should == "Frederichstrasse"
            end

            it "builds a new second document" do
              person.addresses.second.street.should == "Alexander Platz"
            end

            it "builds a new third document" do
              person.addresses.third.street.should == "Maybachufer"
            end

            it "does not add extra documents" do
              person.addresses.size.should == 3
            end

            it "adds the documents in the sorted hash key order" do
              person.addresses.map(&:street).should ==
                [ "Frederichstrasse", "Alexander Platz", "Maybachufer" ]
            end
          end

          context "when a reject block is supplied" do

            before :all do
              Person.send(:undef_method, :addresses_attributes=)
              Person.accepts_nested_attributes_for \
                :addresses, :reject_if => lambda { |attrs| attrs["street"].blank? }
            end

            after :all do
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
                person.addresses.size.should == 1
              end

              it "sets the correct attributes" do
                person.addresses.first.street.should == "Maybachufer"
              end
            end
          end

          context "when destroy attributes are passed" do

            context "when allow_destroy is true" do

              before :all do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, :allow_destroy => true
              end

              after :all do
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
                    person.addresses.size.should == 1
                  end

                  it "adds the new unmarked document" do
                    person.addresses.first.street.should == "Alexander Platz"
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "bar" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "foo" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    person.addresses.first.street.should == "Maybachufer"
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should == "Alexander Platz"
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should == 2
                  end
                end
              end
            end

            context "when allow destroy is false" do

              before :all do
                Person.send(:undef_method, :addresses_attributes=)
                Person.accepts_nested_attributes_for :addresses, :allow_destroy => false
              end

              after :all do
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

                  it "adds the the marked document" do
                    person.addresses.first.street.should == "Maybachufer"
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should == "Alexander Platz"
                  end

                  it "adds the correct number of documents" do
                    person.addresses.size.should == 2
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "bar" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "foo" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    person.addresses.first.street.should == "Maybachufer"
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should == "Alexander Platz"
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should == 2
                  end
                end
              end
            end

            context "when allow destroy is not defined" do

              before :all do
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

                  it "adds the the marked document" do
                    person.addresses.first.street.should == "Maybachufer"
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should == "Alexander Platz"
                  end

                  it "adds the correct number of documents" do
                    person.addresses.size.should == 2
                  end
                end
              end

              [ 0, "0", false, "false" ].each do |falsehood|

                context "when passed a #{falsehood} with destroy" do

                  before do
                    person.addresses_attributes =
                      {
                        "bar" => { "street" => "Maybachufer", "_destroy" => falsehood },
                        "foo" => { "street" => "Alexander Platz" }
                      }
                  end

                  it "adds the new marked document" do
                    person.addresses.first.street.should == "Maybachufer"
                  end

                  it "adds the new unmarked document" do
                    person.addresses.last.street.should == "Alexander Platz"
                  end

                  it "does not add extra documents" do
                    person.addresses.size.should == 2
                  end
                end
              end
            end
          end
        end
      end

      context "when the relation is a references one" do

        let(:person) do
          Person.new
        end

        context "when a reject proc is specified" do

          before :all do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for \
              :game, :reject_if => lambda { |attrs| attrs[:name].blank? }
          end

          after :all do
            Person.send(:undef_method, :game_attributes=)
            Person.accepts_nested_attributes_for :game
          end

          context "when the attributes match" do

            before do
              person.game_attributes = { :score => 10 }
            end

            it "does not add the document" do
              person.game.should be_nil
            end
          end

          context "when the attributes do not match" do

            before do
              person.game_attributes = { :name => "Tron" }
            end

            it "adds the document" do
              person.game.name.should == "Tron"
            end
          end
        end

        context "when no id has been passed" do

          context "with no destroy attribute" do

            before do
              person.game_attributes = { :name => "Tron" }
            end

            it "builds a new document" do
              person.game.name.should == "Tron"
            end
          end

          context "with a destroy attribute" do

            context "when allow_destroy is true" do

              before :all do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, :allow_destroy => true
              end

              after :all do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { :name => "Tron", :_destroy => "1" }
              end

              it "does not build the document" do
                person.game.should be_nil
              end
            end

            context "when allow_destroy is false" do

              before :all do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game, :allow_destroy => false
              end

              after :all do
                Person.send(:undef_method, :game_attributes=)
                Person.accepts_nested_attributes_for :game
              end

              before do
                person.game_attributes = { :name => "Tron", :_destroy => "1" }
              end

              it "builds the document" do
                person.game.name.should == "Tron"
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
                person.game = Game.new(:name => "Tron")
                person.game_attributes = { :name => "Pong" }
              end

              it "replaces the document" do
                person.game.name.should == "Pong"
              end
            end

            context "with a destroy attribute" do

              context "when allow_destroy is true" do

                before :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(:name => "Tron")
                  person.game_attributes = { :name => "Pong", :_destroy => "1" }
                end

                it "does not replace the document" do
                  person.game.name.should == "Tron"
                end
              end

              context "when allow_destroy is false" do

                before :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, :allow_destroy => false
                end

                after :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                before do
                  person.game = Game.new(:name => "Tron")
                  person.game_attributes = { :name => "Pong", :_destroy => "1" }
                end

                it "replaces the document" do
                  person.game.name.should == "Pong"
                end
              end
            end
          end
        end

        context "when an id is passed" do

          context "when there is an existing record" do

            let(:game) do
              Game.new(:name => "Tron")
            end

            before do
              person.game = game
            end

            context "when the id matches" do

              context "when passed keys as symbols" do

                before do
                  person.game_attributes =
                    { :_id => game.id, :name => "Pong" }
                end

                it "updates the existing document" do
                  person.game.name.should == "Pong"
                end
              end

              context "when passed keys as strings" do

                before do
                  person.game_attributes =
                    { "_id" => game.id, "name" => "Pong" }
                end

                it "updates the existing document" do
                  person.game.name.should == "Pong"
                end
              end

              context "when allow_destroy is true" do

                before :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      person.game_attributes =
                        { :_id => game.id, :_destroy => truth }
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
                        { :_id => game.id, :_destroy => falsehood }
                    end

                    it "does not destroy the existing document" do
                      person.game.should == game
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game, :allow_destroy => false
                end

                after :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when a destroy attribute is passed" do

                  before do
                    person.game_attributes =
                      { :_id => game.id, :_destroy => true }
                  end

                  it "does not destroy the document" do
                    person.game.should == game
                  end
                end
              end

              context "when update only is true" do

                before :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for \
                    :game,
                    :update_only => true,
                    :allow_destroy => true
                end

                after :all do
                  Person.send(:undef_method, :game_attributes=)
                  Person.accepts_nested_attributes_for :game
                end

                context "when the id matches" do

                  before do
                    person.game_attributes =
                      { :_id => game.id, :name => "Donkey Kong" }
                  end

                  it "updates the existing document" do
                    person.game.name.should == "Donkey Kong"
                  end
                end

                context "when the id does not match" do

                  before do
                    person.game_attributes =
                      { :_id => "1", :name => "Pong" }
                  end

                  it "updates the existing document" do
                    person.game.name.should == "Pong"
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    person.game_attributes =
                      { :_id => game.id, :_destroy => true }
                  end

                  it "destroys the existing document" do
                    person.game.should be_nil
                  end
                end
              end
            end
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
                game.person_attributes = { :title => "Sir" }
              end

              it "builds a new document" do
                game.person.title.should == "Sir"
              end

            end

            context "when a destroy attribute is passed" do

              context "when allow_destroy is true" do

                before :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, :allow_destroy => true
                end

                after :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { :title => "Sir", :_destroy => 1 }
                end

                it "does not build a new document" do
                  game.person.should be_nil
                end
              end

              context "when allow_destroy is false" do

                before :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, :allow_destroy => false
                end

                after :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                before do
                  game.person_attributes = { :title => "Sir", :_destroy => 1 }
                end

                it "builds a new document" do
                  game.person.title.should == "Sir"
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
                  game.person_attributes = { :_id => person.id, :title => "Sir" }
                end

                it "updates the existing document" do
                  game.person.title.should == "Sir"
                end
              end
            end

            context "when there is an existing document" do

              before do
                game.person = person
              end

              context "when allow destroy is true" do

                before :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, :allow_destroy => true
                end

                after :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                [ 1, "1", true, "true" ].each do |truth|

                  context "when passed #{truth} with destroy" do

                    before do
                      game.person_attributes =
                        { :_id => person.id, :_destroy => truth }
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
                        { :_id => person.id, :_destroy => falsehood }
                    end

                    it "does not destroy the existing document" do
                      game.person.should == person
                    end
                  end
                end
              end

              context "when allow destroy is false" do

                before :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person, :allow_destroy => false
                end

                after :all do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for :person
                end

                context "when a destroy attribute is passed" do

                  before do
                    game.person_attributes =
                      { :_id => person.id, :_destroy => true }
                  end

                  it "does not delete the document" do
                    game.person.should == person
                  end
                end
              end

              context "when update only is true" do

                before do
                  Game.send(:undef_method, :person_attributes=)
                  Game.accepts_nested_attributes_for \
                    :person,
                    :update_only => true,
                    :allow_destroy => true
                end

                context "when the id matches" do

                  before do
                    game.person_attributes =
                      { :_id => person.id, :title => "Madam" }
                  end

                  it "updates the existing document" do
                    game.person.title.should == "Madam"
                  end
                end

                context "when the id does not match" do

                  before do
                    game.person_attributes =
                      { :_id => "1", :title => "Madam" }
                  end

                  it "updates the existing document" do
                    game.person.title.should == "Madam"
                  end
                end

                context "when passed a destroy truth" do

                  before do
                    game.person_attributes =
                      { :_id => person.id, :title => "Madam", :_destroy => "true" }
                  end

                  it "deletes the existing document" do
                    game.person.should be_nil
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
