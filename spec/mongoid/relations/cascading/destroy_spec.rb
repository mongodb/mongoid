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
        person.should_receive(:posts).and_return([ post ])
      end

      it "destroys all documents in the relation" do
        post.should_receive(:destroy)
        strategy.cascade
      end
    end

    context "when no documents exist" do

      before do
        person.should_receive(:posts).and_return([])
      end

      it "does not destroy anything" do
        post.should_receive(:destroy).never
        strategy.cascade
      end
    end
  end
end
