# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Nested::One do

  let(:association) do
    Person.relations['name']
  end

  describe "#allow_destroy?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(association, {}, allow_destroy: true)
      end

      it "returns the option" do
        expect(builder.allow_destroy?).to be true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(association, {}, {})
      end

      it "returns false" do
        expect(builder.allow_destroy?).to be false
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
        described_class.new(association, { last_name: "Lang" }, options)
      end

      before do
        builder.build(person)
      end

      it "does not change the relation" do
        expect(person.name).to be_nil
      end
    end

    context "when attributes are rejectable using a symbol" do

      let(:options) do
        { reject_if: :reject_if_name_is_blank }
      end

      let(:builder) do
        described_class.new(association, { last_name: "Lang" }, options)
      end

      before do
        builder.build(person)
      end

      it "does not change the relation" do
        expect(person.name).to be_nil
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
        described_class.new(association, {
          _id: name.id,
          last_name: "Lang"
        }, options)
      end

      before do
        builder.build(person)
      end

      it "updates the relation" do
        expect(person.name.last_name).to eq("Lang")
      end
    end

    context "when attributes are replacable" do

      let(:options) do
        {}
      end

      let(:builder) do
        described_class.new(association, {
          last_name: "Lang"
        }, options)
      end

      before do
        builder.build(person)
      end

      it "updates the relation" do
        expect(person.name.last_name).to eq("Lang")
      end
    end

    context "when attributes are deletable" do

      let(:name) do
        person.build_name(last_name: "Ling")
      end

      let(:options) do
        { allow_destroy: true }
      end

      %i(id _id).each do |id_field|
        context "#{id_field}" do
          let(:builder) do
            described_class.new(association, {
              id_field => name.id,
              last_name: "Lang",
              _destroy: true
            }, options)
          end

          before do
            builder.build(person)
          end

          it "deletes the relation" do
            expect(person.name).to be_nil
          end
        end
      end
    end
  end

  describe "#destroy" do

    context "when the attribute exists" do

      let(:builder) do
        described_class.new(association, { _destroy: true }, {})
      end

      it "returns the value" do
        expect(builder.destroy).to be true
      end
    end

    context "when the attribute does not exist" do

      let(:builder) do
        described_class.new(association, {}, {})
      end

      it "returns nil" do
        expect(builder.destroy).to be_nil
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
          described_class.new(association, {}, options)
        end

        it "returns true" do
          expect(builder.reject?(builder, { last_name: "Lang" })).to be true
        end
      end

      context "when the proc does not match" do

        let(:builder) do
          described_class.new(association, {}, options)
        end

        it "returns false" do
          expect(builder.reject?(builder, { first_name: "Lang" })).to be false
        end
      end
    end

    context "when the proc is not provided" do

      let(:builder) do
        described_class.new(association, {}, {})
      end

      it "returns false" do
        expect(builder.reject?(builder, { first_name: "Lang" })).to be false
      end
    end
  end

  describe "#update_only?" do

    context "when the option is provided" do

      let(:builder) do
        described_class.new(association, {}, update_only: true)
      end

      it "returns the option" do
        expect(builder.update_only?).to be true
      end
    end

    context "when the option is not provided" do

      let(:builder) do
        described_class.new(association, {}, {})
      end

      it "returns false" do
        expect(builder.update_only?).to be false
      end
    end
  end
end
