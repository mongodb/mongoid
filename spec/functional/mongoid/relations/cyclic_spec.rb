require "spec_helper"

describe Mongoid::Relations::Cyclic do

  context "when building a namespaced hierarchy" do

    let(:root) do
      Trees::Node.new(:name => "root")
    end

    let!(:child_one) do
      root.child_nodes.build(:name => "first_child")
    end

    let!(:child_two) do
      root.child_nodes.build(:name => "second_child")
    end

    it "sets the parent node" do
      child_one.parent_node.should eq(root)
    end
  end
end
