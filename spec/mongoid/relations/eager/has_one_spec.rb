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

  describe ".includes" do

    before do
      3.times { Cat.create!(person: person) }
      Cat.create!(person: Person.create!)
    end

    context "when including the has_one relation" do

      it "queries twice" do

        expect_query(2) do

          Person.all.includes(:cat).each do |person|
            expect(person.cat).to_not be_nil
          end
        end
      end
    end

    context "when including more than one has_one relation" do

      it "queries 3 times" do

        expect_query(3) do

          Person.all.includes(:cat, :account).each do |person|
            expect(person.cat).to_not be_nil
          end
        end
      end
    end
  end
end
