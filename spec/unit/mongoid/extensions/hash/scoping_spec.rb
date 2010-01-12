require "spec_helper"

describe Mongoid::Extensions::Hash::Scoping do

  describe "#scoped" do

    it "returns self" do
      { :where => { :active => true } }.scoped.should ==
        { :where => { :active => true } }
    end

  end

end
