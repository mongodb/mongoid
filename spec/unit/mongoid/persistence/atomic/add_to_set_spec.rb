require "spec_helper"

describe Mongoid::Persistence::Atomic::AddToSet do

  let(:collection) do
    stub
  end

  before do
    person.stubs(:collection).returns(collection)
  end

  after do
    person.unstub(:collection)
  end

  describe "#persist" do

    context "when the field exists" do

      context "when no duplicates exist" do

        let(:person) do
          Person.new(:aliases => [ "007" ])
        end

        context "when adding a single value" do

          let(:add_to_set) do
            described_class.new(person, :aliases, "Bond")
          end

          before do
            person.new_record = false
            collection.expects(:update).with(
              person.atomic_selector,
              { "$addToSet" => { "aliases" => "Bond" } },
              :safe => false
            )
          end

          let!(:added) do
            add_to_set.persist
          end

          it "adds the value onto the array" do
            person.aliases.should eq([ "007", "Bond" ])
          end

          it "removes the field from the dirty attributes" do
            person.changes["aliases"].should be_nil
          end

          it "returns the new array value" do
            added.should eq([ "007", "Bond" ])
          end
        end

        context "when adding multiple values" do

          let(:add_to_set) do
            described_class.new(person, :aliases, [ "Bond", "James" ])
          end

          before do
            person.new_record = false
            collection.expects(:update).with(
              person.atomic_selector,
              { "$addToSet" => { "aliases" => { "$each" => [ "Bond", "James" ] }}},
              :safe => false
            )
          end

          let!(:added) do
            add_to_set.persist
          end

          it "adds the value onto the array" do
            person.aliases.should eq([ "007", "Bond", "James" ])
          end

          it "removes the field from the dirty attributes" do
            person.changes["aliases"].should be_nil
          end

          it "returns the new array value" do
            added.should eq([ "007", "Bond", "James" ])
          end
        end
      end

      context "when duplicates exist" do

        let(:person) do
          Person.new(:aliases => [ "Bond" ])
        end

        context "when adding a single value" do

          let(:add_to_set) do
            described_class.new(person, :aliases, "Bond")
          end

          before do
            person.new_record = false
            collection.expects(:update).with(
              person.atomic_selector,
              { "$addToSet" => { "aliases" => "Bond" } },
              :safe => false
            )
          end

          let!(:added) do
            add_to_set.persist
          end

          it "does not add the value to the array" do
            person.aliases.should eq([ "Bond" ])
          end

          it "removes the field from the dirty attributes" do
            person.changes["aliases"].should be_nil
          end

          it "returns the array value" do
            added.should eq([ "Bond" ])
          end
        end

        context "when adding multiple values" do

          let(:add_to_set) do
            described_class.new(person, :aliases, [ "Bond", "James" ])
          end

          before do
            person.new_record = false
            collection.expects(:update).with(
              person.atomic_selector,
              { "$addToSet" => { "aliases" => { "$each" => [ "Bond", "James" ] }}},
              :safe => false
            )
          end

          let!(:added) do
            add_to_set.persist
          end

          it "adds the value onto the array" do
            person.aliases.should eq([ "Bond", "James" ])
          end

          it "removes the field from the dirty attributes" do
            person.changes["aliases"].should be_nil
          end

          it "returns the new array value" do
            added.should eq([ "Bond", "James" ])
          end
        end
      end
    end

    context "when the field does not exist" do

      let(:person) do
        Person.new
      end

      context "when adding a single value" do

        let(:add_to_set) do
          described_class.new(person, :aliases, "Bond")
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$addToSet" => { "aliases" => "Bond" } },
            :safe => false
          )
        end

        let!(:added) do
          add_to_set.persist
        end

        it "adds the value onto the array" do
          person.aliases.should eq([ "Bond" ])
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "returns the new array value" do
          added.should eq([ "Bond" ])
        end
      end

      context "when adding multiple values" do

        let(:add_to_set) do
          described_class.new(person, :aliases, [ "Bond", "James" ])
        end

        before do
          person.new_record = false
          collection.expects(:update).with(
            person.atomic_selector,
            { "$addToSet" => { "aliases" => { "$each" => [ "Bond", "James" ] }}},
            :safe => false
          )
        end

        let!(:added) do
          add_to_set.persist
        end

        it "adds the value onto the array" do
          person.aliases.should eq([ "Bond", "James" ])
        end

        it "removes the field from the dirty attributes" do
          person.changes["aliases"].should be_nil
        end

        it "returns the new array value" do
          added.should eq([ "Bond", "James" ])
        end
      end
    end
  end
end
