# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Persistable::Upsertable do

  describe "#upsert" do

    context "when the document validates on upsert" do

      let(:account) do
        Account.new(name: "testing")
      end

      context "when the document is not valid in the upsert context" do

        before do
          account.upsert
        end

        it "adds the validation errors" do
          expect(account.errors[:nickname]).to_not be_empty
        end

        it "does not upsert the document" do
          expect(account).to be_a_new_record
        end
      end
    end

    context "when the document is new" do

      let!(:existing) do
        Band.create!(name: "Photek")
      end

      context "when a matching document exists in the db" do

        let(:updated) do
          Band.new(name: "Tool") do |band|
            band.id = existing.id
          end
        end

        before do
          updated.upsert
        end

        it "updates the existing document" do
          expect(existing.reload.name).to eq("Tool")
        end

        it "flags the document as persisted" do
          expect(existing).to be_persisted
        end

        context 'when existing document contains other fields' do
          let!(:existing) do
            Band.create!(name: "Photek", views: 42)
          end

          it 'removes the existing fields' do
            Band.count.should == 1

            existing.reload
            existing.views.should be nil
            existing.name.should == 'Tool'
          end
        end
      end

      context "when no matching document exists in the db" do

        let(:insert) do
          Band.new(name: "Tool")
        end

        before do
          insert.upsert
        end

        it "inserts a new document" do
          expect(insert.reload).to eq(insert)
        end

        it "does not modify any fields" do
          expect(insert.reload.name).to eq("Tool")
        end

        it "flags the document as persisted" do
          expect(insert).to be_persisted
        end
      end
    end

    context "when the document is not new" do

      let!(:existing) do
        Band.create!(name: "Photek")
      end

      context "when updating fields outside of the id" do

        before do
          existing.name = "Depeche Mode"
        end

        let!(:upsert) do
          existing.upsert
        end

        it "updates the existing document" do
          expect(existing.reload.name).to eq("Depeche Mode")
        end

        it "returns true" do
          expect(upsert).to be true
        end
      end
    end

    context "when the document is readonly" do

      context "when legacy_readonly is true" do
        config_override :legacy_readonly, true

        let!(:existing) do
          Band.create!(name: "Photek")
        end

        before do
          existing.name = "Depeche Mode"
        end

        let!(:upsert) do
          existing.upsert
        end

        it "updates the existing document" do
          expect(existing.reload.name).to eq("Depeche Mode")
        end

        it "returns true" do
          expect(upsert).to be true
        end
      end

      context "when legacy_readonly is false" do
        config_override :legacy_readonly, false

        let!(:existing) do
          Band.create!(name: "Photek").tap(&:readonly!)
        end

        before do
          existing.name = "Depeche Mode"
        end

        it 'raises a ReadonlyDocument error' do
          expect do
            existing.upsert
          end.to raise_error(Mongoid::Errors::ReadonlyDocument)
        end
      end
    end
  end
end
