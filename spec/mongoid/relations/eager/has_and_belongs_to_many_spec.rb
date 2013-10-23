require "spec_helper"

describe Mongoid::Relations::Eager::HasAndBelongsToMany do

  describe ".grouped_docs" do

    let(:docs) do
      Person.all.to_a
    end

    let!(:person) do
      Person.create!(houses: [house])
    end

    let!(:house) do
      House.create!
    end

    let(:metadata) do
      Person.reflect_on_association(:houses)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    it "aggregates by the parent primary key" do
      expect(eager.grouped_docs.keys).to eq([person.id])
    end
  end

  describe ".set_on_parent" do

    let(:docs) do
      Person.all.to_a
    end

    let!(:person) do
      Person.create!(houses: [house])
    end

    let!(:house) do
      House.create!
    end

    let(:metadata) do
      Person.reflect_on_association(:houses)
    end

    let(:eager) do
      described_class.new([metadata], docs).tap do |b|
        b.shift_metadata
      end
    end

    it "sets the relation into the parent" do
      docs.each do |doc|
        expect(doc).to receive(:set_relation).with(:houses, :foo)
      end
      eager.set_on_parent(person.id, :foo)
    end
  end

  describe ".includes" do

    let(:person) do
      Person.create!
    end

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

    context "when the relation is not polymorphic" do

      let!(:preference) do
        person.preferences.create(name: "testing")
      end

      let!(:eager) do
        Person.includes(:preferences).last
      end

      it "puts the documents in the parent document" do
        expect(eager.ivar(:preferences)).to eq([ preference ])
      end

      it "does not query when touching the association" do
        expect_query(0) do
          expect(eager.preferences).to eq([ preference ])
        end
      end

      it "does not query when updating the association" do
        expect_query(0) do
          eager.preferences.first.name = "new pref"
          expect(eager.preferences.first.name).to eq("new pref")
        end
      end
    end
  end
end
