require "spec_helper"

describe Mongoid::Collection do

  describe "#find" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    context "when no block supplied" do

      it "finds return a cursor" do
        collection.find({ :test => "value"}).should be_a(Mongoid::Cursor)
      end
    end

    context "when a block is supplied" do

      it "yields to the cursor and closes it" do
        collection.find({ :test => "value" }) do |cur|
          cur.should be_a(Mongoid::Cursor)
        end
      end
    end
  end

  describe "#find_one" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    let!(:person) do
      Person.create
    end

    context "when an enslave option does not exist" do

      it "sends the query to the master" do
        collection.find_one["_id"].should eq(person.id)
      end
    end
  end

  describe "#initialize" do

    context "when providing options" do

      let(:capped) do
        described_class.new(
          Person,
          "capped_people",
          :capped => true, :size => 10000, :max => 100
        )
      end

      let(:options) do
        capped.options
      end

      it "sets the capped option" do
        options["capped"].should be_true
      end

      it "sets the capped size" do
        options["size"].should eq(10000)
      end

      it "sets the max capped documents" do
        options["max"].should eq(100)
      end
    end
  end

  describe "#insert" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    let(:document) do
      { "field" => "value" }
    end

    context "when no inserter exists on the current thread" do

      it "delegates straight to the master collection" do
        collection.insert(document).should be_true
      end
    end
  end

  describe "#update" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    let(:selector) do
      { "_id" => BSON::ObjectId.new }
    end

    let(:document) do
      { "$set" => { "field" => "value" } }
    end

    context "when no updater exists on the current thread" do

      it "delegates straight to the master collection" do
        collection.update(selector, document).should be_true
      end
    end
  end

  context "Mongo::Collection write operations" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    Mongoid::Collections::Operations::WRITE.each do |name|

      it "defines #{name}" do
        collection.should respond_to(name)
      end
    end
  end

  context "Mongo::Collection read operations" do

    let(:collection) do
      described_class.new(Person, "people")
    end

    Mongoid::Collections::Operations::READ.each do |name|

      it "defines #{name}" do
        collection.should respond_to(name)
      end
    end
  end
end
