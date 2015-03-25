require "spec_helper"

describe Mongoid::Relations::Cascading::Nullify do

  let(:person) do
    Person.new
  end

  describe "#cascade" do

    let(:relation) do
      double
    end

    let(:metadata) do
      double(name: :posts)
    end

    let(:strategy) do
      described_class.new(person, metadata)
    end

    before do
      expect(person).to receive(:posts).and_return(relation)
    end

    it "nullifies the relation" do
      expect(relation).to receive(:nullify)
      strategy.cascade
    end
  end
end
