require "spec_helper"

describe Mongoid::Relations::Eager do

  describe ".preload" do

    context "when belongs_to" do

      let!(:drug) do
        Drug.create!(person: person, name: 'foo')
      end

      let(:person) do
        Person.create!
      end

      let(:criteria) do
        Drug.where(name: 'foo')
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      let(:inclusions) do
        [Drug.reflect_on_association(:person)]
      end

      let(:doc) { criteria.first }

      before do
      end

      it "groups by foreign_key" do
        doc.should_receive(:person_id).once
        context.preload(Drug, inclusions, [doc])
      end
      
      it "preloads the parent" do
        expect(doc.ivar(:person)).to be_false
        context.preload(Drug, inclusions, [doc])
        expect(doc.ivar(:person)).to eq(doc.person)
      end
    end
  end
end
