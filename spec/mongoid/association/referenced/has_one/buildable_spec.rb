# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Association::Referenced::HasOne::Buildable do

  let(:base) do
    double(new_record?: false)
  end

  describe "#build" do

    let(:document) do
      association.build(base, object)
    end

    let(:association) do
      Mongoid::Association::Referenced::HasOne.new(Person, :account)
    end

    context "when provided an id" do

      let!(:account) do
        Account.create!(person_id: object, name: 'banking')
      end

      let(:object) do
        BSON::ObjectId.new
      end

      before do
        expect(Account).to receive(:where).with(association.foreign_key => object).and_call_original
      end

      it "sets the document" do
        expect(document).to eq(account)
      end
    end

    context "when provided a object" do

      let(:object) do
        Account.new
      end

      it "returns the object" do
        expect(document).to eq(object)
      end

      context 'when the object is already related to another object' do

        let(:original_person) do
          Person.new
        end

        let(:object) do
          Account.new(person: original_person)
        end

        let!(:document) do
          association.build(Person.new, object)
        end

        it 'clears the object of its previous relation' do
          expect(original_person.account).to be_nil
        end

        it 'returns the object' do
          expect(document).to eq(object)
        end
      end
    end

    context "when the document is not found" do

      let(:object) do
        BSON::ObjectId.new
      end

      it "returns nil" do
        expect(document).to be_nil
      end
    end

    context "when the document is persisted" do

      let(:person) do
        Person.create
      end

      let!(:game) do
        Game.create(person: person)
      end

      it "returns the document" do
        expect(person.game).to eq(game)
      end
    end

    context "when the document have a non standard pk" do

      let(:person) do
        Person.create
      end

      let!(:cat) do
        Cat.create(person: person)
      end

      it "returns the document" do
        expect(person.cat).to eq(cat)
      end
    end
  end
end
