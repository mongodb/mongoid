require "spec_helper"

describe Mongoid::Persistence do

  describe "#fail_due_to_valiation!" do

    let(:document) do
      Band.new
    end

    it "raises the validation error" do
      expect {
        document.fail_due_to_validation!
      }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  describe "#fail_due_to_callback!" do

    let(:document) do
      Band.new
    end

    it "raises the callback error" do
      expect {
        document.fail_due_to_callback!(:save!)
      }.to raise_error(Mongoid::Errors::Callback)
    end
  end
end
