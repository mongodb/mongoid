require "spec_helper"

describe Mongoid::Persistence::Atomic::Pop do

  before do
    Person.delete_all
  end

  describe "#persist" do

    context "when the field exists" do

      let(:person) do
        Person.create(:ssn => "123-34-3456", :aliases => [ "007", "008", "009" ])
      end

      context "when popping the last element" do

        let!(:popped) do
          person.pop(:aliases, 1)
        end

        let(:reloaded) do
          person.reload
        end

        it "pops the value from the array" do
          person.aliases.should == [ "007", "008" ]
        end

        it "persists the data" do
          reloaded.aliases.should == [ "007", "008" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "resets the document dirty flag" do
          person.should_not be_changed
        end

        it "returns the new array value" do
          popped.should == [ "007", "008" ]
        end
      end

      context "when popping the first element" do

        let!(:popped) do
          person.pop(:aliases, -1)
        end

        let(:reloaded) do
          person.reload
        end

        it "pops the value from the array" do
          person.aliases.should == [ "008", "009" ]
        end

        it "persists the data" do
          reloaded.aliases.should == [ "008", "009" ]
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "resets the document dirty flag" do
          person.should_not be_changed
        end

        it "returns the new array value" do
          popped.should == [ "008", "009" ]
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.create(:ssn => "123-34-3457")
      end

      let!(:popped) do
        person.pop(:aliases, 1)
      end

      let(:reloaded) do
        person.reload
      end

      it "does not modify the field" do
        person.aliases.should be_nil
      end

      it "persists no data" do
        reloaded.aliases.should be_nil
      end

      it "removes the field from the dirty attributes" do
        person.changes["aliases"].should be_nil
      end

      it "resets the document dirty flag" do
        person.should_not be_changed
      end

      it "returns nil" do
        popped.should be_nil
      end
    end
  end
end
