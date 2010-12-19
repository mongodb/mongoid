require "spec_helper"

describe Mongoid::Relations::Cascading::Nullify do

  let(:klass) do
    Mongoid::Relations::Cascading::Nullify
  end

  let(:person) do
    Person.new
  end

  let(:metadata) do
    stub(:name => :posts, :foreign_key_setter => :person_id=)
  end

  let(:strategy) do
    klass.new(person, metadata)
  end

  describe "#cascade" do

    let(:post) do
      stub
    end

    context "when the documents exist" do

      before do
        person.expects(:posts).returns([ post ])
      end

      it "nullifies all documents in the relation" do
        post.expects(:person_id=).with(nil)
        post.expects(:save)
        strategy.cascade
      end
    end

    context "when no documents exist" do

      before do
        person.expects(:posts).returns([])
      end

      it "does not nullify anything" do
        post.expects(:person_id=).never
        strategy.cascade
      end
    end
  end
end
