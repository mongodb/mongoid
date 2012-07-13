require 'spec_helper'

describe Mongoid::Relations::Cascading::Restrict do

  before :each do
    Person.has_many :drugs, validate: false, dependent: :restrict
  end

  after :each do
    Person.cascades.delete("drugs")
    Person.has_many :drugs, validate: false
  end

  let(:person) do
    Person.new
  end

  let(:metadata) do
    stub(name: :drugs)
  end

  let(:strategy) do
    described_class.new(person, metadata)
  end

  describe "#cascade" do

    let(:drug) do
      stub
    end

    context "when the document exists" do

      context "when person has no drugs" do

        before do
          person.should_receive(:drugs).and_return([ ])
        end

        it "deletes the person" do
          expect { strategy.cascade }.to_not raise_error(Mongoid::Errors::DeleteRestriction)
        end
      end

      context "when person has drugs" do

        before do
          person.should_receive(:drugs).and_return([ drug ])
        end

        it "it raises an error" do
          expect { strategy.cascade }.to raise_error(Mongoid::Errors::DeleteRestriction)
        end
      end
    end

    context "when no document exists" do
      before do
        person.should_receive(:drugs).and_return([])
      end

      it "doesn't delete anything" do
        drug.should_receive(:delete).never
        strategy.cascade
      end
    end
  end
end
