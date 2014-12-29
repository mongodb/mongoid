require 'spec_helper'

describe Mongoid::Relations::Cascading::RestrictWithError do

  before :each do
    Person.has_many :drugs, validate: false, dependent: :restrict_with_error
  end

  after :each do
    Person.cascades.delete("drugs")
    Person.has_many :drugs, validate: false
  end

  let(:person) do
    Person.new
  end

  let(:metadata) do
    double(name: :drugs, relation: Mongoid::Relations::Referenced::Many)
  end

  let(:strategy) do
    described_class.new(person, metadata)
  end

  describe "#cascade" do

    let(:drug) do
      double
    end

    context "when the document exists" do

      context "when person has no drugs" do

        before do
          expect(person).to receive(:drugs).and_return([ ])
        end

        it "deletes the person" do
          expect { strategy.cascade }.to_not raise_error
        end
      end

      context "when person has drugs" do

        before do
          expect(person).to receive(:drugs).and_return([ drug ])
        end

        it "it throw an symbol" do
          expect { strategy.cascade }.to throw_symbol(:skip_delete)
        end

        it "add the error message" do
          catch(:skip_delete) { strategy.cascade }
          expect(person.errors[:base]).to include('Cannot delete record because dependent drugs exist')
        end

        it "does not deletes the parent" do
          catch(:skip_delete) { strategy.cascade }
          expect(person).to_not be_destroyed
        end
      end
    end

    context "when no document exists" do
      before do
        expect(person).to receive(:drugs).and_return([])
      end

      it "doesn't delete anything" do
        expect(drug).to receive(:delete).never
        strategy.cascade
      end
    end
  end
end
