# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Embedded::EmbeddedIn::Binding do

  let(:person) do
    Person.new
  end

  let(:name) do
    Name.new
  end

  let(:address) do
    Address.new
  end

  let(:name_association) do
    Name.relations["namable"]
  end

  let(:address_association) do
    Address.relations["addressable"]
  end

  let(:person_association) do
    Person.relations["addresses"]
  end

  describe "#bind_one" do

    context "when the child of an embeds one" do

      let(:binding) do
        described_class.new(name, person, name_association)
      end

      context "when the document is bindable" do

        before do
          binding.bind_one
        end

        it "parentizes the documents" do
          expect(name._parent).to eq(person)
        end

        it "sets the inverse relation" do
          expect(person.name).to eq(name)
        end
      end

      context "when the document is not bindable" do

        before do
          person.name = name
        end

        it "does nothing" do
          expect(name).to receive(:namable=).with(person).never
          expect(name).to receive(:namable=).with(nil).once
          binding.bind_one
        end
      end
    end

    context "when the child of an embeds many" do

      let(:binding) do
        described_class.new(address, person, address_association)
      end

      context "when the document is bindable" do

        context "when the base has no association" do

          before do
            binding.bind_one
          end

          it "parentizes the documents" do
            expect(address._parent).to eq(person)
          end

          it "sets the inverse relation" do
            expect(person.addresses).to include(address)
          end
        end

        context "when the base has an association" do

          before do
            address._association = person_association
          end

          it "does not overwrite the existing association" do
            expect(address).to receive(:_association=).never
            binding.bind_one
          end
        end
      end

      context "when the document is not bindable" do

        before do
          person.addresses = [ address ]
        end

        it "does nothing" do
          expect(address).to receive(:addressable=).never
          binding.bind_one
        end
      end
    end
  end

  describe "#unbind_one" do

    context "when the child of an embeds one" do

      let(:binding) do
        described_class.new(name, person, name_association)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          binding.unbind_one
        end

        it "removes the inverse relation" do
          expect(person.name).to be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          expect(name).to receive(:namable=).never
          binding.unbind_one
        end
      end
    end

    context "when the child of an embeds many" do

      let(:binding) do
        described_class.new(address, person, address_association)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          binding.unbind_one
        end

        it "removes the inverse relation" do
          expect(person.addresses).to be_empty
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          expect(address).to receive(:addressable=).never
          binding.unbind_one
        end
      end
    end
  end
end
