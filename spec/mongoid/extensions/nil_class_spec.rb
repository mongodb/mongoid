# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Extensions::NilClass do

  describe "#collectionize" do

    it "returns ''" do
      expect(nil.collectionize).to be_empty
    end
  end
end
