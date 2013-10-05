require "spec_helper"

describe Mongoid::Relations::Eager::HasAndBelongsToMany do

  let!(:person) do
    Person.create!(houses: [house])
  end

  let!(:house) do
    House.create!
  end

  let(:houses_metadata) do
    Person.reflect_on_association(:houses)
  end

  let(:docs) do
    Person.all.to_a
  end

  let(:eager) do
    described_class.new(Person, [houses_metadata], docs).tap do |b|
      b.shift_relation
    end
  end

  describe ".grouped_docs" do

    it "aggregates by the parent primary key" do
      expect(eager.grouped_docs.keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).with(:houses, :foo)
      end
      eager.set_on_parent(person.id, :foo)
    end
  end

  describe ".includes" do

    before do
      Person.create!(houses: 3.times.map { House.create! })
    end

    context "when including the has_and_belongs_to_many relation" do

      it "queries twice" do

        expect_query(2) do

          Person.all.includes(:houses).each do |person|
            expect(person.houses).to_not be_nil
          end
        end
      end
    end
  end
end
