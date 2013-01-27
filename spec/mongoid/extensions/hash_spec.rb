require "spec_helper"

describe Mongoid::Extensions::Hash do

  describe "#__evolve_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        evolved[:field].should eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        evolved[:field].should eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the empty string values" do
        evolved[:field].should be_empty
      end
    end

    context "when values have nils" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the nil values" do
        evolved[:field].should be_nil
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        mongoized[:field].should eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        mongoized[:field].should eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts the empty strings to nil" do
        mongoized[:field].should be_nil
      end
    end

    context "when values have nils" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "retains the nil values" do
        mongoized[:field].should be_nil
      end
    end
  end

  describe "#__consolidate__" do

    context "when the hash already contains the key" do

      context "when the $set is first" do

        let(:hash) do
          { "$set" => { name: "Tool" }, likes: 10, "$inc" => { plays: 1 }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          consolidated.should eq({
            "$set" => { name: "Tool", likes: 10 }, "$inc" => { plays: 1 }
          })
        end
      end

      context "when the $set is not first" do

        let(:hash) do
          { likes: 10, "$inc" => { plays: 1 }, "$set" => { name: "Tool" }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          consolidated.should eq({
            "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
          })
        end
      end
    end

    context "when the hash does not contain the key" do

      let(:hash) do
        { likes: 10, "$inc" => { plays: 1 }, name: "Tool"}
      end

      let(:consolidated) do
        hash.__consolidate__(Band)
      end

      it "moves the non hash values under the provided key" do
        consolidated.should eq({
          "$set" => { likes: 10, name: "Tool" }, "$inc" => { plays: 1 }
        })
      end
    end
  end

  context "when the hash key is a string" do

    let(:hash) do
      { "100" => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      nested.should eq "hundred"
    end
  end

  context "when the hash key is an integer" do

    let(:hash) do
      { 100 => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      nested.should eq("hundred")
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      Hash.demongoize(hash).should eq(hash)
    end
  end

  describe ".mongoize" do

    context "when object isn't nil" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:hash) do
        { date: date }
      end

      let(:mongoized) do
        Hash.mongoize(hash)
      end

      it "mongoizes each element in the hash" do
        mongoized[:date].should be_a(Time)
      end

      it "converts the elements properly" do
        mongoized[:date].should eq(date)
      end
    end

    context "when object is nil" do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it "returns nil" do
        mongoized.should be_nil
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it "mongoizes each element in the hash" do
      mongoized[:date].should be_a(Time)
    end

    it "converts the elements properly" do
      mongoized[:date].should eq(date)
    end
  end

  describe "#resizable?" do

    it "returns true" do
      {}.should be_resizable
    end
  end

  describe ".resizable?" do

    it "returns true" do
      Hash.should be_resizable
    end
  end
end
