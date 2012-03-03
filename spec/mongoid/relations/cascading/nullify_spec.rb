require "spec_helper"

describe Mongoid::Relations::Cascading::Nullify do

  let(:person) do
    Person.new
  end

  describe "#cascade" do

    let(:relation) do
      stub
    end

    let(:metadata) do
      stub(name: :posts)
    end

    let(:strategy) do
      described_class.new(person, metadata)
    end

    before do
      person.expects(:posts).returns(relation)
    end

    it "nullifies the relation" do
      relation.expects(:nullify)
      strategy.cascade
    end
  end
end
