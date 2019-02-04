# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidRelation do

  describe "#message" do

    module MyModule
      def crazy_method; self; end
    end

    before do
      Object.send(:include, MyModule)
    end

    let(:error) do
      described_class.new(Person, :crazy_method)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
                                   "Defining an association named 'crazy_method' is not allowed."
                               )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
                                   "Defining this association would override the method 'crazy_method'"
                               )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
                                   "Use Mongoid.destructive_fields to see what names are not allowed"
                               )
    end
  end
end
