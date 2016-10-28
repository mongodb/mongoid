require "spec_helper"

describe Mongoid::Timestamps::Timeless do

  describe "#timeless" do

    before(:all) do
      class Chicken
        include Mongoid::Document
        include Mongoid::Timestamps

        before_save :lay_timeless_egg

        def lay_timeless_egg
          Egg.timeless.create!
        end
      end

      class Egg
        include Mongoid::Document
        include Mongoid::Timestamps
      end
    end

    after(:all) do
      Object.send(:remove_const, :Chicken)
      Object.send(:remove_const, :Egg)
    end

    context "when timeless is used on one instance and then not used on another instance" do

      let!(:first_instance) do
        egg = Egg.create!
        egg.timeless.save!
        egg
      end

      let!(:second_instance) do
        Egg.create!
      end

      it "second instance's created_at is not nil" do
        expect(second_instance.created_at).to_not be_nil
      end
    end

    context "when others persist in the scope of the chain" do

      context "when the root executes normally" do

        let!(:chicken) do
          Chicken.create!
        end

        it "creates the parent with a timestamp" do
          expect(chicken.created_at).to_not be_nil
        end

        it "creates the child with no timestamp" do
          expect(Egg.last.created_at).to be_nil
        end
      end

      context "when the root executes timeless" do

        let!(:chicken) do
          Chicken.timeless.create!
        end

        it "creates the parent with a timestamp" do
          expect(chicken.created_at).to be_nil
        end

        it "creates the child with no timestamp" do
          expect(Egg.last.created_at).to be_nil
        end
      end
    end

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
          expect(document).to_not be_timeless
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
          expect(document).to_not be_timeless
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
