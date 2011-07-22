require "spec_helper"

describe "Rails::Mongoid" do

  before(:all) do
    require "rails/mongoid"
  end

  describe ".index_children" do

    let(:child) do
      stub(:to_s => "Model")
    end

    it "creates the indexes for the child model" do
      child.expects(:create_indexes)
      child.expects(:descendants).returns([])
      Rails::Mongoid.index_children([ child ])
    end
  end
end
