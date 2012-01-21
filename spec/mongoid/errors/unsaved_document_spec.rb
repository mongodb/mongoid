require "spec_helper"

describe Mongoid::Errors::UnsavedDocument do

  let(:base) do
    Person.new
  end

  let(:document) do
    Post.new
  end

  let(:error) do
    described_class.new(base, document)
  end

  describe "#message" do

    it "returns that create can not be called" do
      error.message.should include(
        "You cannot call create or create! through a relation"
      )
    end
  end
end
