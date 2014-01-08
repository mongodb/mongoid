require 'spec_helper'

describe Mongoid::Errors::MongoidError do

  let(:error) { described_class.new }
  let(:key) { :callbacks }
  let(:options) { {} }

  before do
    ["message", "summary", "resolution"].each do |name|
      expect(::I18n).to receive(:translate).
        with("mongoid.errors.messages.#{key}.#{name}", {}).
      and_return(name)
    end

    error.compose_message(key, options)
  end

  describe "#compose_message" do

    it "sets ivar problem" do
      expect(error.instance_variable_get(:@problem)).to be
    end

    it "sets ivar summary" do
      expect(error.instance_variable_get(:@summary)).to be
    end

    it "sets ivar resolution" do
      expect(error.instance_variable_get(:@resolution)).to be
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
