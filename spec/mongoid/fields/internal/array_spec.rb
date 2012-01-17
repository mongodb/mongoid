require "spec_helper"

describe Mongoid::Fields::Internal::Array do

  let(:field) do
    described_class.instantiate(:test, :type => Array)
  end

  describe "#add_atomic_changes" do

    let(:person) do
      Person.new
    end

    let(:mods) do
      {}
    end

    context "when adding and removing" do

      context "when there are no nil values" do

        before do
          person.aliases = [ "007", "008" ]
          field.add_atomic_changes(
            person, "aliases", "aliases", mods, [ "008" ], [ "009" ]
          )
        end

        it "adds the current to the modifications" do
          mods["aliases"].should eq([ "008" ])
        end
      end

      context "when there are nil values" do

        before do
          person.aliases = [ "007", nil ]
          field.add_atomic_changes(
            person, "aliases", "aliases", mods, [ nil ], [ "008" ]
          )
        end

        it "adds the current to the modifications" do
          mods["aliases"].should eq([ nil ])
        end
      end
    end
  end

  describe "#cast_on_read?" do

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when the default is a proc" do

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Array,
          :default => lambda { [ "test" ] }
        )
      end

      it "calls the proc" do
        field.eval_default(nil).should == [ "test" ]
      end
    end

    context "when the default is an array" do

      let(:default) do
        [ "test" ]
      end

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Array,
          :default => default
        )
      end

      it "returns the correct value" do
        field.eval_default(nil).should == default
      end

      it "returns a duped array" do
        field.eval_default(nil).should_not equal(default)
      end
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "returns the value" do
        field.selection([ 1, 2, 3 ]).should eq([ 1, 2, 3 ])
      end
    end

    context "when providing a complex criteria" do

      let(:criteria) do
        { "$ne" => "test" }
      end

      it "returns the criteria" do
        field.selection(criteria).should eq(criteria)
      end
    end
  end

  describe "#serialize" do

    context "when the value is not an array" do

      it "raises an error" do
        expect {
          field.serialize("test")
        }.to raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        field.serialize(["test"]).should == ["test"]
      end
    end
  end
end
