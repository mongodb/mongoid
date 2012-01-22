require "spec_helper"

describe Mongoid::Cursor do

  let(:collection) do
    Person.collection
  end

  (Mongoid::Cursor::OPERATIONS - [ :timeout ]).each do |name|

    let(:cursor) do
      described_class.new(Person, collection, nil)
    end

    describe "##{name}" do

      it "delegates to the proxy" do
        cursor.should respond_to(name)
      end
    end
  end

  describe "#collection" do

    it "returns the mongoid collection" do
      cursor.collection.should eq(collection)
    end
  end

  describe "#each" do

    let(:proxy) do
      Mongo::Cursor.allocate
    end

    let(:cursor) do
      described_class.new(Person, collection, proxy)
    end

    before do
      Mongoid.logger = ::Logger.new($stdout)
    end

    after do
      Mongoid.logger = nil
    end

    context "when no error occurs" do

      before do
        proxy.expects(:next_document).yields({})
      end

      it "yields to the next document" do
        cursor.each do |doc|
          doc.attributes.except("_id").should == Person.instantiate.attributes.except("_id")
        end
      end
    end

    context "when a connection error occurs" do

      before do
        Mongoid.max_retries_on_connection_failure = 1
      end

      after do
        Mongoid.max_retries_on_connection_failure = 0
      end

      let(:seq) do
        sequence("cursor")
      end

      before do
        proxy.expects(:next_document).in_sequence(seq).raises(
          Mongo::ConnectionFailure.new
        )
        proxy.expects(:next_document).in_sequence(seq).returns({})
        proxy.expects(:next_document).in_sequence(seq).returns(nil)
      end

      it "retries the yield to the next document" do
        cursor.each do |doc|
          doc.should be_a(Person)
        end
      end
    end
  end
end
