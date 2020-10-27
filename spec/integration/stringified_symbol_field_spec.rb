require "spec_helper"

describe "StringifiedSymbol fields" do

  before do
    StringifiedSymbol.destroy_all
  end

  context "when querying the database" do

    let!(:document) do
      StringifiedSymbol.create(status: :test)
    end

    let(:string_query) do
      {'status' => {'$eq' => 'test'}}
    end

    let(:symbol_query) do
      {'status' => {'$eq' => :test}}
    end

    it "can be queried with a string" do
      doc = StringifiedSymbol.where(string_query).first
      expect(doc.status).to eq(:test)
    end

    it "can be queried with a symbol" do
      doc = StringifiedSymbol.where(symbol_query).first
      expect(doc.status).to eq(:test)
    end
  end

# Using command monitoring to test that StringifiedSymbol sends a string and returns a symbol
  before(:all) do
    CONFIG[:clients][:other] = CONFIG[:clients][:default].dup
    CONFIG[:clients][:other][:database] = 'other'
    Mongoid::Clients.clients.values.each(&:close)
    Mongoid::Config.send(:clients=, CONFIG[:clients])
    Mongoid::Clients.with_name(:other).subscribe(Mongo::Monitoring::COMMAND, EventSubscriber.new)
  end

  let(:subscriber) do
    client = Mongoid::Clients.with_name(:other)
    monitoring = client.send(:monitoring)
    subscriber = monitoring.subscribers['Command'].find do |s|
      s.is_a?(EventSubscriber)
    end
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
    StringifiedSymbol.create(status: :test)
  end

  let!(:document2) do
    StringifiedSymbol.where(query).first
  end

  context "when inserting document" do

    it "sends the value as a string" do
      event = insert_events.first
      doc = event.command["documents"].first
      expect(doc["status"]).to eq("test")
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
      client = Mongoid::Clients.with_name(:other)
      client["stringified_symbols"].insert_one(status: BSON::Symbol::Raw.new("test"), _id: 12)
    end

    it "receives the value as a symbol" do
      expect(StringifiedSymbol.find(12).status).to eq(:test)
    end

    it "saves the value as a string" do
      ss = StringifiedSymbol.find(12)
      ss.status = :other
      ss.save
      event = update_events.first
      expect(event.command["updates"].first["u"]["$set"]["status"]).to eq("other")
    end
  end
end
