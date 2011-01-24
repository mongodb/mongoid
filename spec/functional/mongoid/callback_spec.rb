require "spec_helper"

describe Mongoid::Callbacks do

  before do
    ValidationCallback.delete_all
    ParentDoc.delete_all
  end

  context "callback on valid?" do
    it 'should go in all validation callback in good order' do
      shin = ValidationCallback.new
      shin.valid?
      shin.history.should == [:before_validation, :validate, :after_validation]
    end
  end

  context "when creating child documents in callbacks" do

    let(:parent) do
      ParentDoc.new
    end

    before do
      parent.save
    end

    it "does not duplicate the child documents" do
      parent.child_docs.create(:position => 1)
      ParentDoc.find(parent.id).child_docs.size.should == 1
    end
  end
end
