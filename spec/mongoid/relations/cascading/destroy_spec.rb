require "spec_helper"

describe Mongoid::Relations::Cascading::Destroy do

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

      it "destroys all documents in the relation" do
        post.expects(:destroy)
        strategy.cascade
      end
    end

    context "when no documents exist" do

      before do
        person.expects(:posts).returns([])
      end

      it "does not destroy anything" do
        post.expects(:destroy).never
        strategy.cascade
      end
    end
  end
end
