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
        Band.create(name: "Photek")
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
  end

  describe "#during_post_persist" do

    context "when registered model lifecycle callbacks directly/indirectly use Mongoid::Document.during_post_persist_callbacks " do

      context "when the document is sharded" do

        class ShardedProfile
          include Mongoid::Document

          attr_reader(
            :before_upsert_called,
            :before_upsert_val,
            :after_upsert_called,
            :after_upsert_val,
            :around_upsert_called,
            :around_upsert_val_pre_yield,
            :around_upsert_val_post_yield,
          )

          field :name, type: String

          shard_key :name

          before_upsert :beforeUpsertMethod

          around_upsert :aroundUpsertMethod

          after_upsert :afterUpsertMethod

          def beforeUpsertMethod
            @before_upsert_called = true

            @before_upsert_val = self.during_post_persist_callbacks
          end

          def aroundUpsertMethod
            @around_upsert_called = true
            @around_upsert_val_pre_yield = self.during_post_persist_callbacks
            yield
            @around_upsert_val_post_yield = self.during_post_persist_callbacks
          end

          def afterUpsertMethod
            @after_upsert_called = true

            @after_upsert_val = self.during_post_persist_callbacks
          end
        end

        let!(:profile) do
          ShardedProfile.create(name: "Alice")
        end

        context "when before_upsert " do

          it "returns true" do
            expect(profile.before_upsert_called).to be nil
            expect(profile.before_upsert_val).to be nil

            profile.name = "Bob"
            profile.upsert

            expect(profile.before_upsert_called).to be true
            expect(profile.before_upsert_val).to be false
          end
        end

        context "when around_upsert" do

          it "returns true" do
            expect(profile.around_upsert_called).to be nil
            expect(profile.around_upsert_val_pre_yield).to be nil
            expect(profile.around_upsert_val_post_yield).to be nil

            profile.name = "Bob"
            profile.upsert

            expect(profile.around_upsert_called).to be true
            expect(profile.around_upsert_val_pre_yield).to be false
            expect(profile.around_upsert_val_post_yield).to be true
          end
        end

        context "when after_upsert" do

          it "returns true" do
            expect(profile.after_upsert_called).to be nil
            expect(profile.after_upsert_val).to be nil

            profile.name = "Bob"
            profile.upsert

            expect(profile.after_upsert_called).to be true
            expect(profile.after_upsert_val).to be true
          end
        end
      end
    end
  end
end
