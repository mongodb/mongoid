require "spec_helper"

describe Mongoid::Relations::Cyclic do

  describe ".recursively_embeds_many" do

    let(:document) do
      Role.new
    end

    it "creates the parent relation" do
      document.should respond_to(:parent_role)
    end

    it "creates the child relation" do
      document.should respond_to(:child_roles)
    end
  end

  describe ".recursively_embeds_one" do

    let(:document) do
      Shelf.new
    end

    it "creates the parent relation" do
      document.should respond_to(:parent_shelf)
    end

    it "creates the child relation" do
      document.should respond_to(:child_shelf)
    end
  end
end
