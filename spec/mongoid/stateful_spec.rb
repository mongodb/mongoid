# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Stateful do

  describe "#new_record?" do

    context "when calling new on the document" do

      let(:person) do
        Person.new("_id" => BSON::ObjectId.new)
      end

      it "returns true" do
        expect(person).to be_a_new_record
      end
    end

    context "when the object has been saved" do

      let(:person) do
        Person.instantiate("_id" => BSON::ObjectId.new)
      end

      it "returns false" do
        expect(person).to_not be_a_new_record
      end
    end

    context "when the object has not been saved" do

      let(:person) do
        Person.new
      end

      it "returns true" do
        expect(person).to be_a_new_record
      end
    end
  end

  describe '#previously_new_record?' do
    it "returns correct values" do
      person = Person.new
      expect(person).not_to be_a_previously_new_record
      person.save!
      expect(person).to be_a_previously_new_record
      person.title = "Title"
      person.save!
      expect(person).not_to be_a_previously_new_record
    end

    it "resets after reload" do
      person = Person.create!
      expect(person).to be_a_previously_new_record
      person.reload
      expect(person).not_to be_a_previously_new_record
    end
  end

  describe "#persisted?" do

    let(:person) do
      Person.new
    end

    it "delegates to new_record?" do
      expect(person).to_not be_persisted
    end

    context "when the object has been destroyed" do
      before do
        person.save!
        person.destroy
      end

      it "returns false" do
        expect(person).to_not be_persisted
      end
    end
  end

  describe "#previously_persisted?" do
    it "returns true after being destroyed" do
      person = Person.create!
      expect(person).not_to be_previously_persisted
      person.destroy
      expect(person).to be_previously_persisted
    end
  end

  describe "destroyed?" do

    let(:person) do
      Person.new
    end

    context "when destroyed is true" do

      before do
        person.destroyed = true
      end

      it "returns true" do
        expect(person).to be_destroyed
      end
    end

    context "when destroyed is false" do

      before do
        person.destroyed = false
      end

      it "returns true" do
        expect(person).to_not be_destroyed
      end
    end

    context "when destroyed is nil" do

      before do
        person.destroyed = nil
      end

      it "returns false" do
        expect(person).to_not be_destroyed
      end
    end
  end

  describe "#readonly?" do

    let(:document) do
      Band.new
    end

    context "when legacy_readonly is true" do
      config_override :legacy_readonly, true

      context "when the selected fields are set" do

        before do
          document.__selected_fields = { test: 1 }
        end

        it "returns true" do
          expect(document).to be_readonly
        end
      end

      context "when no readonly has been set" do

        it "returns false" do
          expect(document).to_not be_readonly
        end
      end

      context "when the readonly! method is called" do

        let(:op) do
          document.readonly!
        end

        it "returns false" do
          op
          expect(document).to_not be_readonly
        end

        it "warns" do
          expect(Mongoid::Warnings).to receive(:warn_legacy_readonly)
          op
        end
      end

      context "when overriding readonly?" do

        let(:doc) { ReadonlyModel.create! }

        before do
          class ReadonlyModel
            include Mongoid::Document

            attr_accessor :locked

            def readonly?
              !!locked
            end
          end
        end

        after do
          Object.send(:remove_const, :ReadonlyModel)
        end

        it "raises when readonly? is true" do
          expect(doc.readonly?).to be false
          doc.locked = true
          expect(doc.readonly?).to be true
          expect do
            doc.destroy
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end

    context "when legacy_readonly is false" do
      config_override :legacy_readonly, false

      context "when the selected fields are set" do

        before do
          document.__selected_fields = { test: 1 }
        end

        it "returns false" do
          expect(document).to_not be_readonly
        end
      end

      context "when the readonly! method is called" do

        before do
          document.readonly!
        end

        it "returns true" do
          expect(document).to be_readonly
        end
      end

      context "when no readonly has been set" do

        it "returns false" do
          expect(document).to_not be_readonly
        end
      end

      context "when overriding readonly?" do

        let(:doc) { ReadonlyModel.new }

        before do
          class ReadonlyModel
            include Mongoid::Document

            attr_accessor :locked

            def readonly?
              !!locked
            end
          end
        end

        after do
          Object.send(:remove_const, :ReadonlyModel)
        end

        it "raises when readonly? is true" do
          expect(doc.readonly?).to be false
          doc.locked = true
          expect(doc.readonly?).to be true
          expect do
            doc.save!
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
