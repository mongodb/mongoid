require 'spec_helper'

describe Mongoid::Errors::MongoidError do

  let(:error) { described_class.new }
  let(:key) { :callbacks }
  let(:options) { {} }

  before do
    {"message_title" => "message", "summary_title" => "summary", "resolution_title" => "resolution"}.each do |key, name|
      expect(::I18n).to receive(:translate).with("mongoid.errors.messages.#{key}", {}).and_return(name)
    end

    ["message", "summary", "resolution"].each do |name|
      expect(::I18n).to receive(:translate).
        with("mongoid.errors.messages.#{key}.#{name}", {}).
      and_return(name)
    end

    error.compose_message(key, options)
  end

  describe "#compose_message" do

    it "sets ivar problem" do
      expect(error.problem).to be
    end

    it "sets ivar summary" do
      expect(error.summary).to be
    end

    it "sets ivar resolution" do
      expect(error.resolution).to be
    end

    it "sets ivar problem_title" do
      expect(error.instance_variable_get(:@problem_title)).to be
    end

    it "sets ivar summary_title" do
      expect(error.instance_variable_get(:@summary_title)).to be
    end

    it "sets ivar resolution_title" do
      expect(error.instance_variable_get(:@resolution_title)).to be
    end
  end

  describe "#to_json" do

    it "has problem" do
      expect(error.to_json).to include('"problem":"message"')
    end

    it "has summary" do
      expect(error.to_json).to include('"summary":"summary"')
    end

    it "has resolution" do
      expect(error.to_json).to include('"resolution":"resolution"')
    end
  end
end
