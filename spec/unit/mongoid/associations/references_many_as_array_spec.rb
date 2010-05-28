require "spec_helper"

describe Mongoid::Associations::ReferencesManyAsArray do

  let(:block) do
    Proc.new do
      def extension
        "Testing"
      end
    end
  end

  let(:options) do
    Mongoid::Associations::Options.new(
      :name => :preferences,
      :foreign_key => "preference_ids",
      :extend => block,
      :inverse_of => :people
    )
  end

  describe "#<<" do

    context "when the parent document is new" do

      let(:person) do
        Person.new
      end

      let(:preference) do
        Preference.new(:name => "Brightness")
      end

      before do
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options
        )
        @association << preference
      end

      it "appends the document to the association" do
        @association.target.first.should == preference
      end

      it "adds the id to the association ids" do
        person.preference_ids.should include(preference.id)
      end

      it "adds the reverse association id" do
        preference.person_ids.should include(person.id)
      end
    end

    context "when the parent document is not new" do

      let(:person) do
        Person.new
      end

      let(:preference) do
        Preference.new(:name => "Brightness")
      end

      before do
        person.instance_variable_set(:@new_record, false)
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options, []
        )
        @association << preference
      end

      it "appends the document to the association" do
        @association.target.first.should == preference
      end

      it "adds the id to the association ids" do
        person.preference_ids.should include(preference.id)
      end

      it "adds the reverse association id" do
        preference.person_ids.should include(person.id)
      end
    end
  end

  describe "#build" do

    context "when the parent is new" do

      let(:person) do
        Person.new
      end

      before do
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options
        )
        @preference = @association.build(:name => "Brightness")
      end

      it "appends the document to the association" do
        @association.target.first.should == @preference
      end

      it "adds the id to the association ids" do
        person.preference_ids.should include(@preference.id)
      end

      it "adds the reverse association id" do
        @preference.person_ids.should include(person.id)
      end
    end

    context "when the parent is not new" do

      let(:person) do
        Person.new
      end

      before do
        person.instance_variable_set(:@new_record, false)
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options, []
        )
        @preference = @association.build(:name => "Brightness")
      end

      it "appends the document to the association" do
        @association.target.first.should == @preference
      end

      it "adds the id to the association ids" do
        person.preference_ids.should include(@preference.id)
      end

      it "adds the reverse association id" do
        @preference.person_ids.should include(person.id)
      end
    end
  end

  describe "#initialize" do

    let(:person) do
      Person.new
    end

    context "when a target is not provided" do

      before do
        person.preference_ids = ["1", "2", "3"]
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options
        )
        @criteria = Preference.any_in(:_id => ["1", "2", "3"])
      end

      it "sets the association options" do
        @association.options.should == options
      end

      it "sets the target to the criteria for finding by ids" do
        @association.target.should == @criteria
      end
    end

    context "when a target is provided" do
      before do
        @preferences = [
          Preference.new,
          Preference.new
        ]
        @association = Mongoid::Associations::ReferencesManyAsArray.new(
          person, options, @preferences
        )
      end

      it "sets the target to the entries provided" do
        @association.target.should == @preferences
      end
    end
  end

  describe "#concat" do

    let(:person) do
      Person.new
    end

    let(:preference) do
      Preference.new(:name => "Brightness")
    end

    before do
      @association = Mongoid::Associations::ReferencesManyAsArray.new(
        person, options
      )
      @association.concat(preference)
    end

    it "delegates to <<" do
      @association.target.first.should == preference
    end
  end

  describe ".instantiate" do

    let(:person) do
      Person.new
    end

    context "when a target is not provided" do

      before do
        person.preference_ids = ["1", "2", "3"]
        @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
          person, options
        )
        @criteria = Preference.any_in(:_id => ["1", "2", "3"])
      end

      it "sets the association options" do
        @association.options.should == options
      end

      it "sets the target to the criteria for finding by ids" do
        @association.target.should == @criteria
      end
    end

    context "when a target is provided" do
      before do
        @preferences = [
          Preference.new,
          Preference.new
        ]
        @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
          person, options, @preferences
        )
      end

      it "sets the target to the entries provided" do
        @association.target.should == @preferences
      end
    end
  end

  describe "#method_missing" do

    let(:person) do
      Person.new
    end

    context "when target is a criteria" do

      before do
        person.preference_ids = ["1", "2", "3"]
        @association = Mongoid::Associations::ReferencesManyAsArray.instantiate(
          person, options
        )
      end

      it "executes the criteria and sends to the result" do
        Preference.expects(:any_in).with(:_id => ["1", "2", "3"]).returns([])
        @association.entries.should == []
      end
    end

    context "when target is an array" do

    end
  end

  describe "#push" do

    let(:person) do
      Person.new
    end

    let(:preference) do
      Preference.new(:name => "Brightness")
    end

    before do
      @association = Mongoid::Associations::ReferencesManyAsArray.new(
        person, options
      )
      @association.push(preference)
    end

    it "delegates to <<" do
      @association.target.first.should == preference
    end
  end
end
