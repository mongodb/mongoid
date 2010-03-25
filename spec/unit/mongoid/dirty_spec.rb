require "spec_helper"

describe Mongoid::Dirty do

  describe "#attribute_change" do

    context "when the attribute has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns an array of the old value and new value" do
        @person.attribute_change("title").should ==
          [ "Grand Poobah", "Captain Obvious" ]
      end
    end

    context "when the attribute has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns an empty array" do
        @person.attribute_change("title").should be_nil
      end
    end
  end

  describe "#attribute_changed?" do

    context "when the attribute has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns true" do
        @person.attribute_changed?("title").should == true
      end
    end

    context "when the attribute has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns false" do
        @person.attribute_changed?("title").should == false
      end
    end
  end

  describe "#attribute_was" do

    context "when the attribute has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns the old value" do
        @person.attribute_was("title").should == "Grand Poobah"
      end
    end

    context "when the attribute has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns nil" do
        @person.attribute_was("title").should be_nil
      end
    end
  end

  describe "#changed" do

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns an array of changed field names" do
        @person.changed.should == [ "title" ]
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns an empty array" do
        @person.changed.should == []
      end
    end
  end

  describe "#changed?" do

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns true" do
        @person.should be_changed
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns false" do
        @person.should_not be_changed
      end
    end
  end

  describe "#changes" do

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns a hash of changes" do
        @person.changes.should ==
          { "title" => [ "Grand Poobah", "Captain Obvious" ] }
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns an empty hash" do
        @person.changes.should == {}
      end
    end
  end

  describe "#previous_changes" do

    before do
      @person = Person.new(:title => "Grand Poobah")
      @person.title = "Captain Obvious"
    end

    context "when the document has been saved" do

      before do
        @person.collection.expects(:save).returns(true)
        @person.save!
      end

      it "returns the changes before the save" do
        @person.previous_changes["title"].should ==
          [ "Grand Poobah", "Captain Obvious" ]
      end
    end

    context "when the document has not been saved" do

      it "returns an empty hash" do
        @person.previous_changes.should == {}
      end
    end
  end

  describe "#reset_attribute!" do

    context "when the attribute has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "resets the value to the original" do
        @person.reset_attribute!("title")
        @person.title.should == "Grand Poobah"
      end
    end

    context "when the attribute has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "does nothing" do
        @person.reset_attribute!("title")
        @person.title.should == "Grand Poobah"
      end
    end
  end
end
