require "spec_helper"

describe Mongoid::Relations::Synchronization do

  let(:agent) do
    Agent.create!
  end

  let(:user) do
    User.create!
  end

  let(:person) do
    Person.create!
  end

  describe ".update_inverse_keys" do

    context "when Unpersisted Account is Instantiated" do

      let(:account) do
        Account.new do |a|
          a.name = "testing"
          a.creator = user
          a.person = person
        end
      end

      it "should have persisted :agent" do
        agent.persisted?.should be_true
      end

      it "should have persisted :user" do
        user.persisted?.should be_true
      end

      it "should have persisted :person" do
        person.persisted?.should be_true
      end

      it "should not have persisted :account" do
        account.persisted?.should be_false
      end

      it "should have instantiated a .valid? :account" do
        account.valid?
        account.valid?.should be_true
      end

      context "and is Persisted" do

        it "should be able to :save" do
          account.save.should be_true
        end
      end

      context "check for existing Agent, then Persisted" do

        before do
          account.agents.where(:_id => agent.id).exists?
        end

        it "should be able to :save" do
          account.save.should be_true
        end
      end
    end
  end
end
