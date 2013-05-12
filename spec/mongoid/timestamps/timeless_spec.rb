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
          document.created_at.should be_nil
        end

        it "does not set the updated timestamp" do
          document.updated_at.should be_nil
        end

        it "clears out the timeless option after save" do
          Mongoid::Threaded.timeless.should be_false
        end

        context "when subsequently persisting" do

          before do
            document.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            document.updated_at.should_not be_nil
          end
        end
      end

      context "when used on the class" do

        let!(:document) do
          Dokument.timeless.create
        end

        it "does not set the created timestamp" do
          document.created_at.should be_nil
        end

        it "does not set the updated timestamp" do
          document.updated_at.should be_nil
        end

        it "clears out the timeless option after save" do
          Mongoid::Threaded.timeless.should be_false
        end

        context "when subsequently persisting" do

          before do
            document.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            document.updated_at.should_not be_nil
          end
        end
      end
    end
  end
end
