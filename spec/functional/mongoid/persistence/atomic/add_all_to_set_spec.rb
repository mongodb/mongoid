require "spec_helper"

describe Mongoid::Persistence::Atomic::AddAllToSet do

  before do
    Person.delete_all
  end

  describe "#persist" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      let!(:added) do
        person.add_all_to_set(:aliases, [ "Bond", "James" ])
      end

      it "adds the value onto the array" do
        person.aliases.should == [ "Bond", "James" ]
      end

      it "does not reset the dirty flagging" do
        person.changes["aliases"].should == [nil, ["Bond", "James"]]
      end

      it "returns the new array value" do
        added.should == [ "Bond", "James" ]
      end
    end

    context "when the field exists" do

      context "when the value is unique" do

        let(:person) do
          Person.create(:ssn => "123-34-3456", :aliases => [ "007" ])
        end

        let!(:added) do
          person.add_all_to_set(:aliases, [ "Bond", "James" ])
        end

        let(:reloaded) do
          person.reload
        end

        it "adds the value onto the array" do
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
          added.should == [ "007", "Bond", "James" ]
        end
      end

      context "when the value is not unique" do

        let(:person) do
          Person.create(:ssn => "123-34-3456", :aliases => [ "Bond" ])
        end

        let!(:added) do
          person.add_all_to_set(:aliases, [ "Bond", "James" ])
        end

        let(:reloaded) do
          person.reload
        end

        it "does not add the value" do
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

        it "returns the array value" do
          added.should == [ "Bond", "James" ]
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create(:ssn => "123-34-3457")
      end

      let!(:added) do
        person.add_all_to_set(:aliases, [ "Bond", "James" ])
      end

      let(:reloaded) do
        person.reload
      end

      it "adds the value onto the array" do
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
        added.should == [ "Bond", "James" ]
      end
    end
  end
end
