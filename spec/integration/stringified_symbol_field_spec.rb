require "spec_helper"

describe "StringifiedSymbol fields" do

  before do
    Order.destroy_all
  end

  context "when querying the database" do

    let!(:document) do
      Order.create(status: :test)
    end

    let(:string_query) do
      {'status' => {'$eq' => 'test'}}
    end

    let(:symbol_query) do
      {'status' => {'$eq' => :test}}
    end

    it "can be queried with a string" do
      doc = Order.where(string_query).first
      expect(doc.status).to eq(:test)
    end

    it "can be queried with a symbol" do
      doc = Order.where(symbol_query).first
      expect(doc.status).to eq(:test)
    end
  end

# Using command monitoring to test that StringifiedSymbol sends a string and returns a symbol
let(:client) { Order.collection.client }

  before do
    client.subscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  after do
    client.unsubscribe(Mongo::Monitoring::COMMAND, subscriber)
  end

  let(:subscriber) do
    EventSubscriber.new
  end

  let(:find_events) do
    subscriber.started_events.select { |event| event.command_name.to_s == 'find' }
  end

  let(:insert_events) do
    subscriber.started_events.select { |event| event.command_name.to_s == 'insert' }
  end

  let(:update_events) do
    subscriber.started_events.select { |event| event.command_name.to_s == 'update' }
  end

  before do
    subscriber.clear_events!
  end

  let(:query) do
    {'status' => {'$eq' => 'test'}}
  end

  let!(:document1) do
    Order.create(status: :test)
  end

  let!(:document2) do
    Order.where(query).first
  end

  context "when inserting document" do

    it "sends the value as a string" do
      event = insert_events.first
      doc = event.command["documents"].first
      expect(doc["status"]).to eq("test")
    end

    it "sends the value as a string" do
      Order.create(status: 42)
      event = insert_events.second
      doc = event.command["documents"].first
      expect(doc["status"]).to eq("42")
    end

    it "sends the value as a string" do
      Order.create(status: [0, 1, 2])
      event = insert_events.second
      doc = event.command["documents"].first
      expect(doc["status"]).to eq("[0, 1, 2]")
    end
  end

  context "when finding document" do

    it "receives the value as a symbol" do
      event = find_events.first
      expect(document2.status).to eq(:test)
    end
  end

  context "when reading a BSON Symbol field" do

    before do
      client["orders"].insert_one(status: BSON::Symbol::Raw.new("test"), _id: 12)
    end

    it "receives the value as a symbol" do
      expect(Order.find(12).status).to eq(:test)
    end

    it "saves the value as a string" do
      s = Order.find(12)
      s.status = :other
      s.save
      event = update_events.first
      expect(event.command["updates"].first["u"]["$set"]["status"]).to eq("other")
    end
  end

  context "when reading an integer" do

    before do
      Order.create(status: 42, _id: 13)
    end

    it "receives the value as a symbol" do
      expect(Order.find(13).status).to eq(:"42")
    end

    it "saves the value as a string" do
      s = Order.find(13)
      s.status = 24
      s.save
      event = update_events.first
      expect(event.command["updates"].first["u"]["$set"]["status"]).to eq("24")
    end
  end

  context "when reading an array" do
    before do
      Order.create(status: [0, 1, 2], _id: 14)
    end

    it "receives the value as a symbol" do
      expect(Order.find(14).status).to eq(:"[0, 1, 2]")
    end

    it "saves the value as a string" do
      s = Order.find(14)
      s.status = [3, 4, 5]
      s.save
      event = update_events.first
      expect(event.command["updates"].first["u"]["$set"]["status"]).to eq("[3, 4, 5]")
    end
  end
end
