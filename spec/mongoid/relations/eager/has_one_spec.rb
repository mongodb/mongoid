require "spec_helper"

describe Mongoid::Relations::Eager::HasOne do

  let(:person) do
    Person.create!
  end

  let!(:cat) do
    Cat.create!(person: person)
  end

  let(:docs) do
    Person.all.to_a
  end

  let(:cat_metadata) do
    Person.reflect_on_association(:cat)
  end

  let(:eager) do
    described_class.new(Person, [cat_metadata], docs).tap do |b|
      b.shift_relation
    end
  end

  describe ".grouped_doc" do

    it "aggregates by the relation primary key" do
      expect(eager.grouped_docs.keys).to eq([person.username])
    end
  end

  describe ".set_on_parent" do

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).with(:cat, :foo)
      end
      eager.set_on_parent(person.username, :foo)
    end
  end
end
