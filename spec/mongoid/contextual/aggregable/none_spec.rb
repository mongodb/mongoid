# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Aggregable::None do

  before do
    Band.create!(name: "Depeche Mode")
  end

  let(:context) do
    Mongoid::Contextual::None.new(Band.where(name: "Depeche Mode"))
  end

  describe "#aggregates" do
    it "returns fixed values" do
      expect(context.aggregates(:likes)).to eq("count" => 0, "avg" => nil, "max" => nil, "min" => nil, "sum" => 0)
    end
  end

  describe "#sum" do
    it "returns zero" do
      expect(context.sum).to eq(0)
    end

    context "when return_zero_on_sum_none feature flag is set" do

      around do |example|
        saved_flag = Mongoid::return_zero_on_sum_none
        Mongoid::return_zero_on_sum_none = true
        begin
          example.run
        ensure
          Mongoid::return_zero_on_sum_none = saved_flag
        end
      end

      it "returns zero when arg given" do
        expect(context.sum(:likes)).to eq(0)
      end
    end

    context "when return_zero_on_sum_none feature flag is not set" do

      around do |example|
        saved_flag = Mongoid::return_zero_on_sum_none
        Mongoid::return_zero_on_sum_none = false
        begin
          example.run
        ensure
          Mongoid::return_zero_on_sum_none = saved_flag
        end
      end

      it "returns the input when arg given" do
        expect(context.sum(:likes)).to eq(:likes)
      end
    end
  end

  describe "#avg" do
    it "returns nil" do
      expect(context.avg(:likes)).to eq(nil)
    end
  end

  describe "#min and #max" do
    it "returns nil" do
      expect(context.min).to eq(nil)
      expect(context.max).to eq(nil)
    end

    it "returns nil when arg given" do
      expect(context.min(:likes)).to eq(nil)
      expect(context.max(:likes)).to eq(nil)
    end
  end
end
