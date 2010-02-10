require "spec_helper"

describe Mongoid::Contexts do

  context ".context_for" do
    let(:klass) { stub('klass', :embedded => false) }
    let(:criteria) { stub('criteria', :klass => klass) }

    context "when criteria is for a top-level Mongoid::Document" do
      it "creates a Mongo context" do
        Mongoid::Contexts::Mongo.expects(:new).with(criteria)
        Mongoid::Contexts.context_for(criteria)
      end
    end

    context "when criteria is for an embedded Mongoid::Document" do
      it "creates a Mongo context" do
        klass.stubs(:embedded).returns(true)
        Mongoid::Contexts::Enumerable.expects(:new).with(criteria)
        Mongoid::Contexts.context_for(criteria)
      end
    end
  end

end
