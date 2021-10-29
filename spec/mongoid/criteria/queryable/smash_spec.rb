# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Smash do

  let(:smash) do
    described_class.new(ns: :namespace)
  end

  describe "#[]" do

    before do
      smash.store(:namespace, :default)
      smash.store(:some_field, 42)
    end

    context "when accessing aliased field" do

      it "returns value for original field" do
        expect(smash[:ns]).to eq(:default)
      end
    end

    context "when accessing non-aliased field" do

      it "returns value for the field" do
        expect(smash[:some_field]).to eq(42)
      end
    end
  end
end
