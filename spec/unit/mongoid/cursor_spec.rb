require "spec_helper"

describe Mongoid::Cursor do

  let(:collection) do
    stub.quacks_like(Mongoid::Collection.allocate)
  end

  let(:mongo_cursor) do
    Mongo::Cursor.allocate.tap do |cursor|
      cursor.stubs(:inspect => "<Mongo::Cursor>")
    end
  end

  let(:proxy) do
    stub.quacks_like(mongo_cursor)
  end

  let(:cursor) do
    Mongoid::Cursor.new(Person, collection, proxy)
  end

  (Mongoid::Cursor::OPERATIONS - [ :timeout ]).each do |name|

    describe "##{name}" do

      before do
        proxy.expects(name)
      end

      it "delegates to the proxy" do
        cursor.send(name)
      end

      it "retries on connection failure" do
        cursor.expects(:retry_on_connection_failure).then.yields
        cursor.send(name)
      end
    end
  end

  describe "#collection" do

    it "returns the mongoid collection" do
      cursor.collection.should == collection
    end
  end

  describe "#each" do

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

  describe "#next_document" do

    before do
      proxy.expects(:next_document).returns({})
    end

    it "returns the next document from the proxied cursor" do
      doc = cursor.next_document
      doc.attributes.except("_id").should == Person.instantiate.attributes.except("_id")
    end
  end

  describe "#to_a" do

    before do
      proxy.expects(:to_a).returns([{}])
    end

    it "converts the proxy cursor to an array of documents" do
      docs = cursor.to_a
      docs[0].attributes.except("_id").should == Person.instantiate.attributes.except("_id")
    end
  end
end
