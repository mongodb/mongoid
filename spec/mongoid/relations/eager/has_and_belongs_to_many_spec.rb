require "spec_helper"

describe Mongoid::Relations::Eager::HasAndBelongsToMany do

  describe ".keys_from_docs" do

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

    it "aggregates by the foreign key" do
      expect(eager.keys_from_docs).to eq([house.id])
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
          Person.asc(:_id).includes(:houses).each do |person|
            expect(person.houses).to_not be_nil

            expect(person.houses.length).to be(3)
          end
        end
      end

      it "has all items" do
        Person.asc(:_id).includes(:houses).each do |person|
          expect(person.ivar(:houses).length).to be(3)
        end
      end
    end

    context "when the relation is not polymorphic" do

      let(:eager) do
        Person.asc(:_id).includes(:preferences).last
      end

      context "when the eager load has returned documents" do

        let!(:preference) do
          person.preferences.create(name: "testing")
        end

        before { eager }

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

      context "when the eager load has not returned documents" do

        before { eager }

        it "has an empty proxy" do
          expect(eager.preferences).to eq []
        end

        it "does not query when touching the association" do
          expect_query(0) do
            eager.preferences.entries
          end
        end

        it "returns the proxy" do
          expect do
            eager.preferences.create(name: "testing")
          end.to_not raise_error
        end
      end
    end
  end
end
