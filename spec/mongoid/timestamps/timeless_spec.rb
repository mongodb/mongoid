require "spec_helper"

describe Mongoid::Timestamps::Timeless do

  describe "#timeless" do

    context "when used as a proxy method" do

      context "when used on the document instance" do

        let(:document) do
          Dokument.new
        end

        before do
          document.timeless.save
        end

        it "does not set the created timestamp" do
          expect(document.created_at).to be_nil
        end

        it "does not set the updated timestamp" do
          expect(document.updated_at).to be_nil
        end

        it "clears out the timeless option after save" do
          expect(Mongoid::Threaded.timeless).to be_false
        end

        context "when subsequently persisting" do

          before do
            document.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            expect(document.updated_at).to_not be_nil
          end
        end
      end

      context "when used on the class" do

        let!(:document) do
          Dokument.timeless.create
        end

        it "does not set the created timestamp" do
          expect(document.created_at).to be_nil
        end

        it "does not set the updated timestamp" do
          expect(document.updated_at).to be_nil
        end

        it "clears out the timeless option after save" do
          expect(Mongoid::Threaded.timeless).to be_false
        end

        context "when subsequently persisting" do

          before do
            document.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            expect(document.updated_at).to_not be_nil
          end
        end
      end
    end
  end
end
