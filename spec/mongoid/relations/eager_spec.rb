require "spec_helper"

describe Mongoid::Relations::Eager do

  describe ".preload" do

    let(:criteria) do
      Account.where(name: 'savings')
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    let(:inclusions) do
      includes.map do |key|
        Account.reflect_on_association(key)
      end
    end

    let(:doc) { criteria.first }

    context "when belongs_to" do

      let!(:account) do
        Account.create!(person: person, name: 'savings')
      end

      let(:person) do
        Person.create!
      end

      let(:includes) { [:person] }

      it "groups by foreign_key" do
        doc.should_receive(:person_id).once
        context.preload(Account, inclusions, [doc])
      end

      it "preloads the parent" do
        expect(doc.ivar(:person)).to be_false
        context.preload(Account, inclusions, [doc])
        expect(doc.ivar(:person)).to eq(doc.person)
      end
    end

    context "when has_one" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:comment) do
        Comment.create!(title: 'my account comment', account: account)
      end

      let(:includes) { [:comment] }

      it "preloads the child" do
        expect(doc.ivar(:comment)).to be_false
        context.preload(Account, inclusions, [doc])
        expect(doc.ivar(:comment)).to eq(doc.comment)
      end
    end

    context "when has_many" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:alert) do
        Alert.create!(account: account)
      end

      let(:includes) { [:alerts] }

      it "preloads the child" do
        expect(doc.ivar(:alerts)).to be_false
        context.preload(Account, inclusions, [doc])
        expect(doc.ivar(:alerts)).to eq(doc.alerts)
      end
    end

    context "when has_and_belongs_to_many" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:agent) do
        Agent.create!(accounts: [account])
      end

      let(:includes) { [:agents] }

      it "preloads the child" do
        expect(doc.ivar(:agents)).to be_false
        context.preload(Account, inclusions, [doc])
        expect(doc.ivar(:agents)).to eq(doc.agents)
      end
    end
  end
end
