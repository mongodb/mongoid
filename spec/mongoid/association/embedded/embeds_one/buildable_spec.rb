# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Embedded::EmbedsOne::Buildable do

  let(:base) do
    double
  end

  let(:options) do
    { }
  end

  describe "#build" do

    let(:document) do
      association.build(base, object)
    end

    let(:association) do
      Mongoid::Association::Embedded::EmbedsOne.new(Person, :name, options)
    end

    context "when provided nil" do

      let(:object) do
        nil
      end

      it "returns nil" do
        expect(document).to be_nil
      end
    end

    context "when provided a document" do

      let(:object) do
        Name.new
      end

      it "returns the document" do
        expect(document).to eq(object)
      end
    end

    context "when no type is in the object" do

      let(:object) do
        { "first_name" => "Corbin" }
      end

      it "creates the correct type of document" do
        expect(document).to be_a_kind_of(Name)
      end

      it "sets the object on the document" do
        expect(document.first_name).to eq("Corbin")
      end
    end

    context "when a type is in the object" do

      let(:association) do
        Mongoid::Association::Embedded::EmbedsOne.new(Person, :writer, options)
      end

      let(:object) do
        { "_type" => PdfWriter.name, "speed" => 100 }
      end

      it "creates the correct type of document" do
        expect(document).to be_a_kind_of(PdfWriter)
      end

      it "sets the object on the document" do
        expect(document.speed).to eq(100)
      end
    end
  end

  context 'when the object is already related to another object' do

    let(:person1) do
      Person.create!
    end

    let(:person2) do
      Person.create!
    end

    let(:passport) do
      Passport.new
    end

    before do
      person1.passport = passport
      # byebug
      person2.passport = passport
    end

    it 'clears the object of its previous relation' do
      pending "3291"
      expect(person1.passport).to be_nil
      expect(person2.passport).to eq(passport)
    end
  end
end
