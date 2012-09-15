require "spec_helper"

describe Mongoid::Contextual::FindAndModify do

  describe "#result" do

    let!(:depeche) do
      Band.create(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create(name: "Tool")
    end

    let!(:collection) do
      Band.collection
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(collection, criteria, { "$inc" => { likes: 1 }})
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

      context "when providing values that needs to be cast" do

        let(:date_time) do
          DateTime.new(1978, 1, 1)
        end

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(collection, criteria, { "$set" => { created: date_time }})
        end

        let!(:result) do
          context.result
        end

        it "returns the first matching document" do
          result["name"].should eq("Depeche Mode")
        end

        it "updates the document in the database" do
          depeche.reload.created.should eq(date_time)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(collection, criteria, { "$inc" => { likes: 1 }})
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
          described_class.new(collection, criteria, { "$inc" => { likes: 1 }})
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
          described_class.new(collection, criteria, { "$inc" => { likes: 1 }}, new: true)
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
          described_class.new(collection, criteria, {}, remove: true)
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

      context "when upserting" do

        let(:criteria) do
          Band.where(name: "The Mars Volta")
        end

        let(:context) do
          described_class.new(collection, criteria, { "$inc" => { likes: 1 }}, upsert: true)
        end

        let(:result) do
          context.result
        end

        it "creates the document if it does not exist" do
          expect {
            result
          }.to change{Band.where(name: "The Mars Volta").count}.from(0).to(1)
        end

        it "updates the document in the database if it does exist" do
          the_mars_volta = Band.create(name: "The Mars Volta")

          expect {
            result
          }.to_not change{Band.where(name: "The Mars Volta").count}

          the_mars_volta.reload.likes.should eq(1)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(collection, criteria, { "$inc" => { likes: 1 }})
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
