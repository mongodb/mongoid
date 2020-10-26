require "spec_helper"

describe "StringifiedSymbol fields" do
  context "when querying the database" do

  before do
    StringifiedSymbol.destroy_all
  end

    let!(:document) do
      StringifiedSymbol.create(stringified_symbol: :test)
    end

    let(:string_query) do
      {'stringified_symbol' => {'$eq' => 'test'}}
    end

    let(:symbol_query) do
      {'stringified_symbol' => {'$eq' => :test}}
    end

    it "finds a symbol" do
      doc = StringifiedSymbol.where(string_query).first
      expect(doc.stringified_symbol).to eq(:test)
    end

    it "can be queried with a symbol" do
      doc = StringifiedSymbol.where(symbol_query).first
      expect(doc.stringified_symbol).to eq(:test)
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
    find_events = subscriber.started_events.select { |event| event.command_name.to_s == 'find' }
  end

  let(:insert_events) do
    insert_events = subscriber.started_events.select { |event| event.command_name.to_s == 'insert' }
  end

  before do
    subscriber.clear_events!
  end

  let(:query) do
    {'stringified_symbol' => {'$eq' => 'test'}}
  end

  let!(:document1) do
    StringifiedSymbol.with(client: :other) do |klass|
      klass.create(stringified_symbol: :test)
    end
  end

  let!(:document2) do
    StringifiedSymbol.with(client: :other) do |klass|
      klass.where(query).first
    end
  end

  context "when inserting document" do

    it "sends the value as a string" do
      event = insert_events.first
      doc = event.command["documents"].first
      expect(doc["stringified_symbol"]).to eq("test")
    end
  end

  context "when finding document" do

    it "receives the value as a symbol" do
      event = find_events.first
      expect(document2.stringified_symbol).to eq(:test)
    end
  end
end
