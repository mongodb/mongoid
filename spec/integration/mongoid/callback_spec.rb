require "spec_helper"

describe Mongoid::Callbacks do
  before do
    ValidationCallback.delete_all
  end

  context "callback on valid?" do
    it 'should go in all validation callback in good order' do
      shin = ValidationCallback.new
      shin.valid?
      shin.history.should == [:before_validation, :validate, :after_validation]
    end
  end
end
