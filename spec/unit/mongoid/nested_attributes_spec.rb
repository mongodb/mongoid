require "spec_helper"

describe Mongoid::NestedAttributes do

  let(:person) do
    Person.new
  end

  describe ".accepts_nested_attributes_for" do

    before do
      Person.accepts_nested_attributes_for :favorites
    end

    after do
      Person.send(:undef_method, :favorites_attributes=)
    end

    it "adds a method for handling the attributes" do
      person.should respond_to(:favorites_attributes=)
    end
  end
end
