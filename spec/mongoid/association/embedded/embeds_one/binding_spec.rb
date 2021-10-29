# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Embedded::EmbedsOne::Binding do

  let(:person) do
    Person.new
  end

  let(:target) do
    Name.new
  end

  let(:association) do
    Person.relations["name"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, target, association)
    end

    context "when the document is bindable" do

      before do
        binding.bind_one
      end

      it "parentizes the documents" do
        expect(target._parent).to eq(person)
      end

      it "sets the inverse relation" do
        expect(target.namable).to eq(person)
      end
    end

    context "when the document is not bindable" do

      before do
        target.namable = person
      end

      it "does nothing" do
        expect(person).to receive(:name=).never
        binding.bind_one
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, association)
    end

    context "when the document is unbindable" do

      before do
        binding.bind_one
        binding.unbind_one
      end

      it "removes the inverse relation" do
        expect(target.namable).to be_nil
      end
    end

    context "when the document is not unbindable" do

      it "does nothing" do
        expect(person).to receive(:name=).never
        binding.unbind_one
      end
    end
  end
end
