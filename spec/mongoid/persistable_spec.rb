require "spec_helper"

describe Mongoid::Persistable do

  describe "#atomically" do

    let(:document) do
      Band.create(member_count: 0, likes: 60, origin: "London")
    end

    context "when providing a block" do

      shared_examples_for "an atomically updatable root document" do

        it "performs inc updates" do
          expect(document.member_count).to eq(10)
        end

        it "performs bit updates" do
          expect(document.likes).to eq(12)
        end

        it "performs set updates" do
          expect(document.name).to eq("Placebo")
        end

        it "performs unset updates" do
          expect(document.origin).to be_nil
        end

        it "returns true" do
          expect(update).to be true
        end

        it "persists inc updates" do
          expect(document.reload.member_count).to eq(10)
        end

        it "persists bit updates" do
          expect(document.reload.likes).to eq(12)
        end

        it "persists set updates" do
          expect(document.reload.name).to eq("Placebo")
        end

        it "persists unset updates" do
          expect(document.reload.origin).to be_nil
        end
      end

      context "when not chaining the operations" do

        let(:operations) do
          {
            "$inc" => { "member_count" => 10 },
            "$bit" => { "likes" => { :and => 13 }},
            "$set" => { "name" => "Placebo" },
            "$unset" => { "origin" => true }
          }
        end

        before do
          expect_any_instance_of(Mongo::Collection::View).to receive(:update_one).with(operations).and_call_original
        end

        let!(:update) do
          document.atomically do
            document.inc(member_count: 10)
            document.bit(likes: { and: 13 })
            document.set(name: "Placebo")
            document.unset(:origin)
          end
        end

        it_behaves_like "an atomically updatable root document"
      end

      context "when chaining the operations" do

        let(:operations) do
          {
            "$inc" => { "member_count" => 10 },
            "$bit" => { "likes" => { :and => 13 }},
            "$set" => { "name" => "Placebo" },
            "$unset" => { "origin" => true }
          }
        end

        before do
          expect_any_instance_of(Mongo::Collection::View).to receive(:update_one).with(operations).and_call_original
        end

        let!(:update) do
          document.atomically do
            document.
              inc(member_count: 10).
              bit(likes: { and: 13 }).
              set(name: "Placebo").
              unset(:origin)
          end
        end

        it_behaves_like "an atomically updatable root document"
      end

      context "when given multiple operations of the same type" do

        let(:operations) do
          {
            "$inc" => { "member_count" => 10, "other_count" => 10 },
            "$bit" => { "likes" => { :and => 13 }},
            "$set" => { "name" => "Placebo" },
            "$unset" => { "origin" => true }
          }
        end

        before do
          expect_any_instance_of(Mongo::Collection::View).to receive(:update_one).with(operations).and_call_original
        end

        let!(:update) do
          document.atomically do
            document.
              inc(member_count: 10).
              inc(other_count: 10).
              bit(likes: { and: 13 }).
              set(name: "Placebo").
              unset(:origin)
          end
        end

        it_behaves_like "an atomically updatable root document"

        it "performs multiple inc updates" do
          expect(document.other_count).to eq(10)
        end

        it "persists multiple inc updates" do
          expect(document.reload.other_count).to eq(10)
        end
      end

      context "when expecting the document to be yielded" do

        let(:operations) do
          {
            "$inc" => { "member_count" => 10 },
            "$bit" => { "likes" => { :and => 13 }},
            "$set" => { "name" => "Placebo" },
            "$unset" => { "origin" => true }
          }
        end

        before do
          expect_any_instance_of(Mongo::Collection::View).to receive(:update_one).with(operations).and_call_original
        end

        let!(:update) do
          document.atomically do |doc|
            doc.
              inc(member_count: 10).
              bit(likes: { and: 13 }).
              set(name: "Placebo").
              unset(:origin)
          end
        end

        it_behaves_like "an atomically updatable root document"
      end

      context "when nesting atomically calls" do

        before do
          class Band
            def my_updates
              atomically do |d|
                d.set(name: "Placebo")
                d.unset(:origin)
              end
            end
          end
        end

        let!(:update) do
          document.atomically do |doc|
            doc.inc(member_count: 10)
            doc.bit(likes: { and: 13 })
            doc.my_updates
          end
        end

        it_behaves_like "an atomically updatable root document"
      end
    end

    context "when providing no block "do

      it "returns true" do
        expect(document.atomically).to be true
      end
    end
  end

  describe "#fail_due_to_valiation!" do

    let(:document) do
      Band.new
    end

    it "raises the validation error" do
      expect {
        document.fail_due_to_validation!
      }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  describe "#fail_due_to_callback!" do

    let(:document) do
      Band.new
    end

    it "raises the callback error" do
      expect {
        document.fail_due_to_callback!(:save!)
      }.to raise_error(Mongoid::Errors::Callback)
    end
  end
end
