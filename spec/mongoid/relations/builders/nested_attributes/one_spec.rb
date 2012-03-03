require "spec_helper"

describe Mongoid::Relations::Builders::NestedAttributes::One do

  let(:metadata) do
    Mongoid::Relations::Metadata.new(
      name: :name,
      relation: Mongoid::Relations::Embedded::One
    )
  end

  describe "#allow_destroy?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(metadata, {}, allow_destroy: true)
      end

      it "returns the option" do
        builder.allow_destroy?.should be_true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        builder.allow_destroy?.should be_false
      end
    end
  end

  describe "#build" do

    let(:person) do
      Person.new
    end

    context "when attributes are rejectable using a proc" do

      let(:options) do
        { reject_if: ->(attrs){ attrs[:first_name].blank? } }
      end

      let(:builder) do
        described_class.new(metadata, { last_name: "Lang" }, options)
      end

      before do
        builder.build(person)
      end

      it "does not change the relation" do
        person.name.should be_nil
      end
    end

    context "when attributes are rejectable using a symbol" do

      let(:options) do
        { reject_if: :reject_if_name_is_blank }
      end

      let(:builder) do
        described_class.new(metadata, { last_name: "Lang" }, options)
      end

      before do
        builder.build(person)
      end

      it "does not change the relation" do
        person.name.should be_nil
      end
    end



    context "when attributes are updatable" do

      let(:name) do
        person.build_name(last_name: "Ling")
      end

      let(:options) do
        {}
      end

      let(:builder) do
        described_class.new(metadata, {
          _id: name.id,
          last_name: "Lang"
        }, options)
      end

      before do
        builder.build(person)
      end

      it "updates the relation" do
        person.name.last_name.should eq("Lang")
      end
    end

    context "when attributes are replacable" do

      let(:options) do
        {}
      end

      let(:builder) do
        described_class.new(metadata, {
          last_name: "Lang"
        }, options)
      end

      before do
        builder.build(person)
      end

      it "updates the relation" do
        person.name.last_name.should eq("Lang")
      end
    end

    context "when attributes are deletable" do

      let(:name) do
        person.build_name(last_name: "Ling")
      end

      let(:options) do
        { allow_destroy: true }
      end

      let(:builder) do
        described_class.new(metadata, {
          id: name.id,
          last_name: "Lang",
          _destroy: true
        }, options)
      end

      before do
        builder.build(person)
      end

      it "deletes the relation" do
        person.name.should be_nil
      end
    end
  end

  describe "#destroy" do

    context "when the attribute exists" do

      let(:builder) do
        described_class.new(metadata, { _destroy: true }, {})
      end

      it "returns the value" do
        builder.destroy.should be_true
      end
    end

    context "when the attribute does not exist" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns nil" do
        builder.destroy.should be_nil
      end
    end
  end

  describe "#reject?" do

    context "when the proc is provided" do

      let(:options) do
        { reject_if: ->(attrs){ attrs[:first_name].blank? } }
      end

      context "when the proc matches" do

        let(:builder) do
          described_class.new(metadata, {}, options)
        end

        it "returns true" do
          builder.reject?(builder, { last_name: "Lang" }).should be_true
        end
      end

      context "when the proc does not match" do

        let(:builder) do
          described_class.new(metadata, {}, options)
        end

        it "returns false" do
          builder.reject?(builder, { first_name: "Lang" }).should be_false
        end
      end
    end

    context "when the proc is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        builder.reject?(builder, { first_name: "Lang" }).should be_false
      end
    end
  end

  describe "#update_only?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(metadata, {}, update_only: true)
      end

      it "returns the option" do
        builder.update_only?.should be_true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        builder.update_only?.should be_false
      end
    end
  end
end
