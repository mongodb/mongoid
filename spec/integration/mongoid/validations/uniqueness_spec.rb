require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  before do
    UserAccount.delete_all
    Login.delete_all
  end

  after do
    UserAccount.delete_all
    Login.delete_all
  end

  context "when the document has no composite keys defined" do

    context "when no record in the database" do

      let(:account) do
        UserAccount.new(:username => "rdawkins")
      end

      it "passes validation" do
        account.should be_valid
      end
    end

    context "with a record in the database" do

      before do
        UserAccount.create(:username => "chitchins")
        UserAccount.create(:username => "rdawkins")
      end

      context "when document is not new" do

        let(:account) do
          UserAccount.where(:username => "rdawkins").first
        end

        it "passes validation" do
          account.should be_valid
        end

        it "fails validation when another document has the same unique field" do
          account.username = "chitchins"
          account.should_not be_valid
        end
      end

      context "when document is new" do

        let(:account) do
          UserAccount.new(:username => "rdawkins")
        end

        it "fails validation" do
          account.should_not be_valid
        end

        it "contains uniqueness errors" do
          account.valid?
          account.errors[:username].should == ["is already taken"]
        end
      end
    end
  end

  context "when the document has keys defined" do

    context "when no record in the database" do

      let(:login) do
        Login.new(:username => "rdawkins")
      end

      it "passes validation" do
        login.should be_valid
      end
    end

    context "with a record in the database" do

      before do
        Login.create(:username => "rdawkins")
      end

      context "when the document is new" do

        let(:login) do
          Login.new(:username => "rdawkins")
        end

        it "fails validation" do
          login.should_not be_valid
        end

        it "contains uniqueness errors" do
          login.valid?
          login.errors[:username].should == ["is already taken"]
        end
      end

      context "when the document is not new" do

        before do
          Login.create(:username => "chitchins")
          Login.create(:username => "rdawkins")
        end

        context "when the key has changed" do

          let(:login) do
            Login.where(:username => "chitchins").first
          end

          before do
            login.username = "rdawkins"
          end

          it "fails validation" do
            login.should_not be_valid
          end
        end

        context "when the key has not changed" do

          let(:login) do
            Login.where(:username => "rdawkins").first
          end

          it "passes validation" do
            login.should be_valid
          end
        end

      end
    end
  end
end
