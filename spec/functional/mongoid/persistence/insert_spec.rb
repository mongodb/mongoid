require "spec_helper"

describe Mongoid::Persistence::Insert do

  before do
    Agent.delete_all
  end

  after do
    Agent.delete_all
    Agent.reset_callbacks :create
    Name.reset_callbacks :create
  end

  describe "#persist" do
    let(:agent) { Agent.new }

    context "when the document is not embedded" do
      it "runs the before_create callback once" do
        Agent.before_create :before_create_callback
        agent.expects(:before_create_callback).once
        agent.save
      end

      it "doesn't have changed fields after it is saved" do
        # making a change before saving
        agent.title = 'Foo'
        agent.changed?.should be_true
        agent.changed.should include 'title'
        agent.save.should be_true
        # after saved
        agent.changed?.should be_false
        agent.changed.should be_empty
      end
    end

    context "when the document is embedded" do

      let(:name) { agent.names.build }

      it "runs the before_create callback once" do
        Name.before_create :before_create_callback
        name.expects(:before_create_callback).once
        name.save
      end

      it "doesn't have changed fields after the parent is saved" do
        # making a change before saving
        name.last_name = 'Foo'
        name.changed?.should be_true
        name.changed.should include 'last_name'
        agent.save.should be_true
        # after saved
        name.changed?.should be_false
        name.changed.should be_empty
      end

    end

  end
end
