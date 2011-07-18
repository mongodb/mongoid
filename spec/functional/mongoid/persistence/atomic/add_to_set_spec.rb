require "spec_helper"

describe Mongoid::Persistence::Atomic::AddToSet do

  before do
    Person.delete_all
  end

  describe "#persist" do

    context "when the document is new" do

      let(:person) do
        Person.new
      end

      let!(:added) do
        person.add_to_set(:aliases, "Bond")
      end

      it "adds the value onto the array" do
        person.aliases.should == [ "Bond" ]
      end

      it "does not reset the dirty flagging" do
        person.changes["aliases"].should == [nil, ["Bond"]]
      end

      it "returns the new array value" do
        added.should == [ "Bond" ]
      end
    end

    context "when the field exists" do

      context "when the value is unique" do

        let(:person) do
          Person.create(:ssn => "123-34-3456", :aliases => [ "007" ])
        end

        let!(:added) do
          person.add_to_set(:aliases, "Bond")
        end

        let(:reloaded) do
          person.reload
        end

        it "adds the value onto the array" do
          person.aliases.should == [ "007", "Bond" ]
        end

        it "persists the data" do
          reloaded.aliases.should == [ "007", "Bond" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "resets the document dirty flag" do
          person.should_not be_changed
        end

        it "returns the new array value" do
          added.should == [ "007", "Bond" ]
        end
      end

      context "when the value is not unique" do

        let(:person) do
          Person.create(:ssn => "123-34-3456", :aliases => [ "Bond" ])
        end

        let!(:added) do
          person.add_to_set(:aliases, "Bond")
        end

        let(:reloaded) do
          person.reload
        end

        it "does not add the value" do
          person.aliases.should == [ "Bond" ]
        end

        it "persists the data" do
          reloaded.aliases.should == [ "Bond" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "resets the document dirty flag" do
          person.should_not be_changed
        end

        it "returns the array value" do
          added.should == [ "Bond" ]
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create(:ssn => "123-34-3457")
      end

      let!(:added) do
        person.add_to_set(:aliases, "Bond")
      end

      let(:reloaded) do
        person.reload
      end

      it "adds the value onto the array" do
        person.aliases.should == [ "Bond" ]
      end

      it "persists the data" do
        reloaded.aliases.should == [ "Bond" ]
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns the new array value" do
        added.should == [ "Bond" ]
      end
    end
  end
end
