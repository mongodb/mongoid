require "spec_helper"

describe Mongoid::Relations::Cascading::Delete do

  let(:person) do
    Person.new
  end

  let(:metadata) do
    stub(name: :posts)
  end

  let(:strategy) do
    described_class.new(person, metadata)
  end

  describe "#cascade" do

    let(:post) do
      stub
    end

    context "when the documents exist" do

      before do
        person.expects(:posts).returns([ post ])
      end

      it "deletes all documents in the relation" do
        post.expects(:delete)
        strategy.cascade
      end
    end

    context "when no documents exist" do

      before do
        person.expects(:posts).returns([])
      end

      it "does not delete anything" do
        post.expects(:delete).never
        strategy.cascade
      end
    end
  end
end
