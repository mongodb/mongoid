require 'spec_helper'

describe Mongoid::Errors::MongoidError do

  let(:error) { described_class.new }
  let(:key) { :callbacks }
  let(:options) { {} }

  before do
    ["message", "summary", "resolution"].each do |name|
      ::I18n.should_receive(:translate).
        with("mongoid.errors.messages.#{key}.#{name}", { locale: :en }).
      and_return(name)
    end

    error.compose_message(key, options)
  end

  describe "#compose_message" do

    it "sets ivar problem" do
      error.instance_variable_get(:@problem).should be
    end

    it "sets ivar summary" do
      error.instance_variable_get(:@summary).should be
    end

    it "sets ivar resolution" do
      error.instance_variable_get(:@resolution).should be
    end
  end

  describe "#to_json" do

    it "has problem" do
      error.to_json.should include('"problem":"message"')
    end

    it "has summary" do
      error.to_json.should include('"summary":"summary"')
    end

    it "has resolution" do
      error.to_json.should include('"resolution":"resolution"')
    end
  end
end
