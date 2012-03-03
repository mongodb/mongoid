require "spec_helper"

describe Mongoid::Contexts do

  context ".context_for" do

    let(:criteria) do
      stub(klass: Person)
    end

    context "when criteria is for a top-level document" do

      let(:context) do
        described_class.context_for(criteria)
      end

      it "creates a Mongo context" do
        context.should be_a(Mongoid::Contexts::Mongo)
      end
    end

    context "when criteria is for an embedded document" do

      let(:context) do
        described_class.context_for(criteria, true)
      end

      it "creates an Enumerable context" do
        context.should be_a(Mongoid::Contexts::Enumerable)
      end
    end
  end
end
