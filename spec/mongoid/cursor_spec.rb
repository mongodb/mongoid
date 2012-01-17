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
end
