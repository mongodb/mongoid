require "spec_helper"

describe Mongoid::Criteria::Permission do

  describe "#should_permit?" do

    context "with untrusted params" do
      let(:untrusted_param) do
        hash = Class.new(Hash){ def permitted?; false; end }.new
        hash["$size"] = 1
        hash
      end

      it "should raise errors" do
        expect{
          Person.where(email: untrusted_param)
        }.to raise_error(Mongoid::Errors::CriteriaNotPermitted)
      end
    end

    context "with trusted params" do
      let(:trusted_param) do
        hash = Class.new(Hash){ def permitted?; true; end }.new
        hash["$size"] = 1
        hash
      end

      it "should work like a hash" do
        expect(Person.where(email: trusted_param)).to eq(Person.where(email: {"$size" => 1}))
      end
    end

  end
end
