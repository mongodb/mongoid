require "spec_helper"

describe Mongoid::NestedAttributes do

  before do
    Person.accepts_nested_attributes_for :name
  end

  after do
    Person.send(:undef_method, :name_attributes=)
  end

  describe "##{name}_attributes=" do

    context "when the parent document is new" do

      let(:person) do
        Person.new
      end

      context "when the relation is an embeds one" do

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
    end
  end
end
