require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::In do

  let(:klass) do
    Mongoid::Relations::Bindings::Referenced::In
  end

  let(:user) do
    User.new
  end

  let(:description) do
    Description.new
  end

  let(:account) do
    Account.new
  end

  let(:description_metadata) do
    Description.relations["user"]
  end

  let(:account_metadata) do
    Account.relations["creator"]
  end

  describe "#bind" do

    context "when the child of references one" do

      let(:binding) do
        klass.new(account, user, account_metadata)
      end

      context "when the document is bindable" do

        before do
          binding.bind
        end

        it "sets the foreign key" do
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
          account.expects(:creator_id=).never
          binding.bind
        end
      end
    end

    context "when the child of references many" do

      let(:binding) do
        klass.new(description, user, description_metadata)
      end

      context "when the document is bindable" do

        before do
          binding.bind
        end

        it "sets the foreign key" do
          description.user_id.should == user.id
        end

        it "sets the inverse relation" do
          user.descriptions.should include(description)
        end
      end

      context "when the document is not bindable" do

        before do
          user.descriptions = [ description ]
        end

        it "does nothing" do
          description.expects(:user_id=).never
          binding.bind
        end
      end
    end
  end

  describe "#unbind" do

    context "when the child of references one" do

      let(:binding) do
        klass.new(account, user, account_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          binding.unbind
        end

        it "removes the inverse relation" do
          user.account.should == nil
        end

        it "removes the foreign key" do
          account.creator_id.should == nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          account.expects(:creator_id=).never
          binding.unbind
        end
      end
    end

    context "when the child of references many" do

      let(:binding) do
        klass.new(description, user, description_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          binding.unbind
        end

        it "removes the inverse relation" do
          user.descriptions.should_not include(description)
        end

        it "removes the foreign key" do
          description.user_id.should == nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          description.expects(:user_id=).never
          binding.unbind
        end
      end
    end
  end
end
