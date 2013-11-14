require "spec_helper"

describe Mongoid::Relations::Builders::NestedAttributes::Many do

  let(:metadata) do
    Mongoid::Relations::Metadata.new(
      name: :addresses,
      relation: Mongoid::Relations::Embedded::Many
    )
  end

  let(:person) do
    Person.new
  end

  describe "#allow_destroy?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(metadata, {}, allow_destroy: true)
      end

      it "returns the option" do
        expect(builder.allow_destroy?).to be true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        expect(builder.allow_destroy?).to be false
      end
    end
  end

  describe "#build" do

    let(:attributes) do
      {
        "foo" => { "street" => "Maybachufer" },
        "bar" => { "street" => "Alexander Platz" },
        "baz" => { "street" => "Unter den Linden" }
      }
    end

    context "when attributes are over limit" do

      let(:builder) do
        described_class.new(metadata, attributes, limit: 2)
      end

      it "raises an error" do
        expect {
          builder.build(person)
        }.to raise_error(Mongoid::Errors::TooManyNestedAttributeRecords)
      end
    end

    context "when rejectable using a proc" do

      let(:builder) do
        described_class.new(
          metadata,
          attributes,
          reject_if: ->(attrs){ attrs[:city].blank? }
        )
      end

      before do
        builder.build(person)
      end

      it "rejects the matching attributes" do
        expect(person.addresses).to be_empty
      end

    end

    context "when rejectable using a symbol" do

      let(:builder) do
        described_class.new(
          metadata,
          attributes,
          reject_if: :reject_if_city_is_empty
        )
      end

      before do
        builder.build(person)
      end

      it "rejects the matching attributes" do
        expect(person.addresses).to be_empty
      end

    end

    context "when ids are present" do

      let!(:address) do
        person.addresses.build(street: "Alexander Platz")
      end

      let(:attributes) do
        { "foo" => { "id" => address.id, "street" => "Maybachufer" } }
      end

      let(:builder) do
        described_class.new(metadata, attributes)
      end

      before do
        builder.build(person)
      end

      it "updates existing documents" do
        expect(person.addresses.first.street).to eq("Maybachufer")
      end
    end

    context "when ids are not present" do

      let(:attributes) do
        { "foo" => { "street" => "Maybachufer" } }
      end

      let(:builder) do
        described_class.new(metadata, attributes)
      end

      before do
        builder.build(person)
      end

      it "adds new documents" do
        expect(person.addresses.first.street).to eq("Maybachufer")
      end
    end
  end

  describe "#initialize" do

    let(:attributes) do
      {
        "4" => { "street" => "Maybachufer" },
        "1" => { "street" => "Frederichstrasse" },
        "2" => { "street" => "Alexander Platz" }
      }
    end

    let(:builder) do
      described_class.new(metadata, attributes, {})
    end

    it "sorts the attributes" do
      expect(builder.attributes.map { |e| e[0] }).to eq([ "1", "2", "4" ])
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
          expect(builder.reject?(builder, { last_name: "Lang" })).to be true
        end
      end

      context "when the proc does not match" do

        let(:builder) do
          described_class.new(metadata, {}, options)
        end

        it "returns false" do
          expect(builder.reject?(builder, { first_name: "Lang" })).to be false
        end
      end
    end

    context "when the proc is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        expect(builder.reject?(builder,{ first_name: "Lang" })).to be false
      end
    end
  end

  describe "#update_only?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(metadata, {}, update_only: true)
      end

      it "returns the option" do
        expect(builder.update_only?).to be true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(metadata, {}, {})
      end

      it "returns false" do
        expect(builder.update_only?).to be false
      end
    end
  end
end
