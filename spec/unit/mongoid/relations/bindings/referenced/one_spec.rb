require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::One do

  let(:klass) do
    Mongoid::Relations::Bindings::Referenced::One
  end

  let(:user) do
    User.new
  end

  let(:account) do
    Account.new
  end

  let(:target) do
    account
  end

  let(:metadata) do
    User.relations["account"]
  end

  describe "#bind" do

    let(:binding) do
      klass.new(user, target, metadata)
    end

    context "when the document is bindable" do

      before do
        binding.bind
      end

      it "sets the inverse foreign key" do
        account.creator_id.should == user.id
      end

      it "sets the inverse relation" do
        account.creator.should == user
      end
    end

    context "when the document is not bindable" do

      before do
        user.account = account
      end

      it "does nothing" do
        account.expects(:creator=).never
        binding.bind
      end
    end
  end

  describe "#unbind" do

    let(:binding) do
      klass.new(user, target, metadata)
    end

    context "when the document is bindable" do

      before do
        binding.bind
        binding.unbind
      end

      it "removes the inverse foreign key" do
        account.creator_id.should == nil
      end

      it "removes the inverse relation" do
        account.creator.should == nil
      end
    end

    context "when the document is not bindable" do

      before do
        user.account = account
      end

      it "does nothing" do
        account.expects(:creator=).never
        binding.bind
      end
    end
  end
end
