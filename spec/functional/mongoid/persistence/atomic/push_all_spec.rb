require "spec_helper"

describe Mongoid::Persistence::Atomic::PushAll do

  before do
    Person.delete_all
  end

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.create(:ssn => "123-34-3456", :aliases => [ "007" ])
      end

      let!(:pushed) do
        person.push_all(:aliases, [ "Bond", "James" ])
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "007", "Bond", "James" ]
      end

      it "persists the data" do
        reloaded.aliases.should == [ "007", "Bond", "James" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        pushed.should == [ "007", "Bond", "James" ]
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create(:ssn => "123-34-3457")
      end

      let!(:pushed) do
        person.push_all(:aliases, [ "Bond", "James" ])
      end

      let(:reloaded) do
        person.reload
      end

      it "pushes the value onto the array" do
        person.aliases.should == [ "Bond", "James" ]
      end

      it "persists the data" do
        reloaded.aliases.should == [ "Bond", "James" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        pushed.should == [ "Bond", "James" ]
      end
    end
  end
end
