require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  before do
    UserAccount.delete_all
    Login.delete_all
    Person.delete_all
    Patient.delete_all
  end

  after do
    UserAccount.delete_all
    Login.delete_all
    Person.delete_all
    Patient.delete_all
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
        UserAccount.create(:username => "chitchins", :email => 'chitchins@test.com')
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

        it "passes validation when another document has a similar unique field" do
          account.username = "chitch"
          account.should be_valid
        end
        
        context "with case insensitive validation" do
          it "fails validation when another document has the same unique field with a different case" do
            account.email = "chiTchins@TEST.CoM"
            account.should_not be_valid
          end
          
          it "passes validation when using special chars in string that will be escaped in regexp" do
            account.email = "chiT.hins@T.ST.CoM"
            account.should be_valid
          end
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
          account.errors[:username].should == ["is not unique"]
        end
        
        context "with case insensitive validation" do
          it "fails validation when another document has the same unique field with a different case" do
            account.username = 'boblu'
            account.email = "chiTchins@TEST.CoM"
            account.should_not be_valid
          end
          
          it "passes validation when using special chars in string that will be escaped in regexp" do
            account.username = 'boblu'
            account.email = "chiT.hins@T.ST.CoM"
            account.should be_valid
          end
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

  context "when the parent document embeds_many" do
    let(:person) { Person.create }
    context "when no record in the database" do
      let(:favorite) { person.favorites.build(:title => "pizza") }

      it "passes validation" do
        favorite.should be_valid
      end
    end

    context "with a record in the database" do
      before do
        person.favorites.create(:title => "pizza")
        person.favorites.create(:title => "doritos")
      end

      context "when document is not new" do
        let(:favorite) { person.favorites.where(:title => "pizza").first }

        it "passes validation" do
          favorite.should be_valid
        end

        it "fails validation when another document has the same unique field" do
          favorite.title = "doritos"
          favorite.should_not be_valid
        end
        
        context "with case insensitive validation" do
          it "fails validation when another document has the same unique field with a different case" do
            favorite.title = "DoRiToS"
            favorite.should_not be_valid
          end
        end
      end

      context "when document is new" do
        let(:favorite) { person.favorites.build(:title => "pizza") }

        it "fails validation" do
          favorite.should_not be_valid
        end

        it "contains uniqueness errors" do
          favorite.valid?
          favorite.errors[:title].should == ["is already taken"]
        end
        
        context "with case insensitive validation" do
          it "fails validation when another document has the same unique field with a different case" do
            favorite.title = "PIZZA"
            favorite.should_not be_valid
          end
        end
      end
    end
  end

  context "when the parent document embeds_one" do
    let(:patient) { Patient.create }
    let(:email) { Email.new(:address => "joe@example.com", :patient => patient) }

    it "passes validation" do
      email.should be_valid
    end

    context "when replacing with a new record with the same value" do
      before do
        Email.create(:address => "joe@example.com", :patient => patient) 
      end
      it "passes validation" do
        email.should be_valid
      end
    end
  end
end
