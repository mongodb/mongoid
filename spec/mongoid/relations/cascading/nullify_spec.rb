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
      person.should_receive(:posts).and_return(relation)
    end

    it "nullifies the relation" do
      relation.should_receive(:nullify)
      strategy.cascade
    end
  end
end
