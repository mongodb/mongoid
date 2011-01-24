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
    end

    context "when the document is embedded" do

      let(:name) { agent.names.build }

      it "runs the before_create callback once" do
        Name.before_create :before_create_callback
        name.expects(:before_create_callback).once
        name.save
      end
    end

  end
end
