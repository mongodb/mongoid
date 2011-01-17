require "spec_helper"

describe Mongoid::Validations do

  let(:account) do
    Account.new(:name => "Testing a really long name.")
  end

  describe "#valid?" do

    context "when provided a context" do

      it "uses the provided context" do
        account.should be_valid(:update)
      end
    end

    context "when not provided a context" do

      context "when the document is new" do

        it "defaults the context to :create" do
          account.should_not be_valid
        end
      end

      context "when the document is persisted" do

        before do
          account.name = "Testing"
          account.save
          account.name = "Testing a really long name."
        end

        it "defaults the context to :update" do
          account.should be_valid
        end
      end
    end
  end
end
