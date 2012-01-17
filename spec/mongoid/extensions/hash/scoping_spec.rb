require "spec_helper"

describe Mongoid::Extensions::Hash::Scoping do

  describe "#as_conditions" do

    let(:hash) do
      { :where => { :active => true }}
    end

    it "returns self" do
      hash.as_conditions.should eq(hash)
    end
  end
end
