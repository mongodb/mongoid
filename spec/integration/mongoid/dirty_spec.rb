require "spec_helper"

describe Mongoid::Dirty do

  before do
    Person.collection.remove
  end

  after do
    Person.collection.remove
  end

  context "when fields are getting changed" do

    before do
      @person = Person.create(:title => "MC", :ssn => "234-11-2533", :some_dynamic_field => 'blah')
      @person.title = "DJ"
      @person.write_attribute(:ssn, "222-22-2222")

      @person.some_dynamic_field = 'bloop'
    end

    it "marks the document as changed" do
      @person.changed?.should == true
    end

    it "marks field changes" do
      @person.changes.should == {
        "title" => [ "MC", "DJ" ],
        "ssn" => [ "234-11-2533", "222-22-2222" ],
        "some_dynamic_field" => [ "blah", "bloop" ]
      }
    end

    it "marks changed fields" do
      @person.changed.should == [ "title", "ssn", "some_dynamic_field" ]
    end

    it "marks the field as changed" do
      @person.title_changed?.should == true
    end

    it "stores previous field values" do
      @person.title_was.should == "MC"
    end

    it "marks field changes" do
      @person.title_change.should == [ "MC", "DJ" ]
    end

    it "allows reset of field changes" do
      @person.reset_title!
      @person.title.should == "MC"
      @person.changed.should == [ "ssn", "some_dynamic_field" ]
    end

    context "after a save" do

      before do
        @person.save!
      end

      it "clears changes" do
        @person.changed?.should == false
      end

      it "stores previous changes" do
        @person.previous_changes["title"].should == [ "MC", "DJ" ]
        @person.previous_changes["ssn"].should == [ "234-11-2533", "222-22-2222" ]
      end
    end
  end

  context "when associations are getting changed" do

    before do
      @person = Person.create(:addresses => [Address.new])
      @person.addresses = [Address.new]
    end

    it "should not set the association to nil when hitting the database" do
      @person.setters.should_not == {"addresses" => nil}
    end
  end
end
