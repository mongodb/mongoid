require "spec_helper"

describe Mongoid::Timestamps::Timeless do

  before do
    Person.delete_all
  end

  describe "#timeless" do

    context "when used as a proxy method" do

      context "when used on the document instance" do

        let(:person) do
          Person.new
        end

        before do
          person.timeless.save
        end

        it "does not set the created timestamp" do
          person.created_at.should be_nil
        end

        it "does not set the updated timestamp" do
          person.updated_at.should be_nil
        end

        it "clears out the timeless option after save" do
          Mongoid::Threaded.timeless.should be_false
        end

        context "when subsequently persisting" do

          before do
            person.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            person.updated_at.should_not be_nil
          end
        end
      end

      context "when used on the class" do

        let!(:person) do
          Person.timeless.create(:ssn => "354-12-1212")
        end

        it "does not set the created timestamp" do
          person.created_at.should be_nil
        end

        it "does not set the updated timestamp" do
          person.updated_at.should be_nil
        end

        it "clears out the timeless option after save" do
          Mongoid::Threaded.timeless.should be_false
        end

        context "when subsequently persisting" do

          before do
            person.update_attribute(:title, "Sir")
          end

          it "sets the updated timestamp" do
            person.updated_at.should_not be_nil
          end
        end
      end
    end
  end
end
