require "spec_helper"

describe Mongoid::NestedAttributes do

  before do
    Person.accepts_nested_attributes_for :name
    Name.accepts_nested_attributes_for :person
  end

  after do
    Person.send(:undef_method, :name_attributes=)
    Name.send(:undef_method, :person_attributes=)
  end

  describe "##{name}_attributes=" do

    context "when the parent document is new" do

      context "when the relation is an embeds one" do

        let(:person) do
          Person.new
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

            before do
              person.name_attributes = { :first_name => "Leo", :_destroy => "1" }
            end

            it "does not build the document" do
              person.name.should be_nil
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

              before do
                person.name = Name.new(:first_name => "Michael")
                person.name_attributes = { :first_name => "Jack", :_destroy => "1" }
              end

              it "does not replace the document" do
                person.name.first_name.should == "Michael"
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

              context "when allow destroy is false" do

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :allow_destroy => false
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

                before do
                  Person.send(:undef_method, :name_attributes=)
                  Person.accepts_nested_attributes_for :name, :update_only => true
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

              before do
                animal.person_attributes = { :title => "Sir", :_destroy => 1 }
              end

              it "does not build a new document" do
                animal.person.should be_nil
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

              context "when allow destroy is false" do

                before do
                  Animal.send(:undef_method, :person_attributes=)
                  Animal.accepts_nested_attributes_for :person, :allow_destroy => false
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
                  Animal.accepts_nested_attributes_for :person, :update_only => true
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

      end
    end
  end
end
