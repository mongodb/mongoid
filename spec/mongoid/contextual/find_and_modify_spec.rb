require "spec_helper"

describe Mongoid::Contextual::FindAndModify do

  describe "#result" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create(name: "Tool")
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria, { "$inc" => { likes: 1 }})
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["name"].should eq("Depeche Mode")
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria, { "$inc" => { likes: 1 }})
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["name"].should eq("Tool")
        end

        it "updates the document in the database" do
          tool.reload.likes.should eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let(:context) do
          described_class.new(criteria, { "$inc" => { likes: 1 }})
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["_id"].should eq(depeche.id)
        end

        it "limits the returned fields" do
          result["name"].should be_nil
        end

        it "updates the document in the database" do
          depeche.reload.likes.should eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria, { "$inc" => { likes: 1 }}, new: true)
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["name"].should eq("Depeche Mode")
        end

        it "returns the updated document" do
          result["likes"].should eq(1)
        end
      end

      context "when removing" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria, {}, remove: true)
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["name"].should eq("Depeche Mode")
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(criteria, { "$inc" => { likes: 1 }})
      end

      let(:result) do
        context.result
      end

      it "returns nil" do
        result.should be_nil
      end
    end
  end
end
