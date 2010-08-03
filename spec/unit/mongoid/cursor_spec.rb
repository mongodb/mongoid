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
    end
  end

  describe "#collection" do

    it "returns the mongoid collection" do
      cursor.collection.should == collection
    end
  end

  describe "#each" do

    before do
      proxy.expects(:each).yields({})
    end

    it "yields to the next document" do
      cursor.each do |doc|
        doc.attributes.except(:_id).should == Person.new.attributes.except(:_id)
      end
    end
  end

  describe "#next_document" do

    before do
      proxy.expects(:next_document).returns({})
    end

    it "returns the next document from the proxied cursor" do
      doc = cursor.next_document
      doc.attributes.except(:_id).should == Person.new.attributes.except(:_id)
    end
  end

  describe "#to_a" do

    before do
      proxy.expects(:to_a).returns([{}])
    end

    it "converts the proxy cursor to an array of documents" do
      docs = cursor.to_a
      docs[0].attributes.except(:_id).should == Person.new.attributes.except(:_id)
    end
  end
end
