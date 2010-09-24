require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  describe "#validate_each" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        @document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => false)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds no errors" do
        @document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @criteria = stub(:exists? => true)
            Login.expects(:where).with(:username => "chitchins").returns(@criteria)
            validator.setup(Login)
            validator.validate_each(login, :username, "chitchins")
          end

          it "checks the value of the key field" do
            login.errors[:username].should_not be_empty
          end
        end

        context "when the document being validated is not new" do

          context "when the id has not changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "chitchins")
              login.instance_variable_set(:@new_record, false)
              login
            end

            before do
              @criteria = stub(:exists? => false)
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'chitchins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should be_empty
            end
          end

          context "when the id has changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "rdawkins")
              login.instance_variable_set(:@new_record, false)
              login.username = "chitchins"
              login
            end

            before do
              @criteria = stub(:exists? => true)
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'rdawkins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should_not be_empty
            end
          end
        end
      end
    end
  end

  describe "#validate_each with embedded document" do

    context "embeds_many" do
      let(:person) { Person.new }
      let(:favorite) { person.favorites.build(:title => "pizza") }
      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => favorite.attributes) }
      let(:criteria) { stub(:exists? => false) }

      it "excludes by attribute and id" do
        person.favorites.expects(:where).with(:title => "pizza", :_id => {'$ne' => favorite.id}).returns(criteria)
        validator.setup(Favorite)
        validator.validate_each(favorite, :title, "pizza")
      end
    end
    context "embeds_one" do
      let(:person) { Patient.new }
      let(:email) { Email.new(:address => "joe@example.com", :person => person) }
      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => email.attributes) }

      it "no validations are run" do
        email.expects(:where).never
        validator.setup(Email)
        validator.validate_each(email, :address, "joe@example.com")
      end

      context "when document has no parent" do
        let(:person) { stub.quacks_like(nil) }
        it "no validations are run" do
          person.expects(:address).never
          validator.setup(Email)
          validator.validate_each(email, :address, "joe@example.com")
        end
      end
    end
  end

  describe "#validate_each with :scope option given" do

    before do
      @document = Person.new(:employer_id => 3, :terms => true, :title => "")
      @criteria = stub(:exists? => false)
    end

    describe "as a symbol" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes,
                                                                      :scope => :employer_id) }

      it "should query only scoped documents" do
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => @document.attributes[:employer_id]).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

    end

    describe "as an array" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes,
                                                                      :scope => [:employer_id, :terms]) }
      it "should query only scoped documents" do
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => @document.attributes[:employer_id]).returns(@criteria)
        @criteria.expects(:where).with(:terms => true).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

    end
  end
  
  describe "#validate_each with case sensitive true" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes, :case_sensitive => true) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        @document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => false)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds no errors" do
        @document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @criteria = stub(:exists? => true)
            Login.expects(:where).with(:username => "chitchins").returns(@criteria)
            validator.setup(Login)
            validator.validate_each(login, :username, "chitchins")
          end

          it "checks the value of the key field" do
            login.errors[:username].should_not be_empty
          end
        end

        context "when the document being validated is not new" do

          context "when the id has not changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "chitchins")
              login.instance_variable_set(:@new_record, false)
              login
            end

            before do
              @criteria = stub(:exists? => false)
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'chitchins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should be_empty
            end
          end

          context "when the id has changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "rdawkins")
              login.instance_variable_set(:@new_record, false)
              login.username = "chitchins"
              login
            end

            before do
              @criteria = stub(:exists? => true)
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'rdawkins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should_not be_empty
            end
          end
        end
      end
    end
  end

  describe "#validate_each with case sensitive false" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes, :case_sensitive => false) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        @document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @criteria = stub(:exists? => true)
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @criteria = stub(:exists? => false)
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds no errors" do
        @document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @criteria = stub(:exists? => true)
            Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
            validator.setup(Login)
            validator.validate_each(login, :username, "chitchins")
          end

          it "checks the value of the key field" do
            login.errors[:username].should_not be_empty
          end
        end

        context "when the document being validated is not new" do

          context "when the id has not changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "chitchins")
              login.instance_variable_set(:@new_record, false)
              login
            end

            before do
              @criteria = stub(:exists? => false)
              Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'chitchins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should be_empty
            end
          end

          context "when the id has changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "rdawkins")
              login.instance_variable_set(:@new_record, false)
              login.username = "chitchins"
              login
            end

            before do
              @criteria = stub(:exists? => true)
              Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
              @criteria.expects(:where).with(:_id => {'$ne' => 'rdawkins'}).returns(@criteria)
              validator.setup(Login)
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should_not be_empty
            end
          end
        end
      end
    end
  end

  describe "#validate_each with embedded document" do

    context "embeds_many" do
      let(:person) { Person.new }
      let(:favorite) { person.favorites.build(:title => "pizza") }
      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => favorite.attributes, :case_sensitive => true) }
      let(:criteria) { stub(:exists? => false) }

      it "excludes by attribute and id" do
        person.favorites.expects(:where).with(:title => "pizza", :_id => {'$ne' => favorite.id}).returns(criteria)
        validator.setup(Favorite)
        validator.validate_each(favorite, :title, "pizza")
      end
    end
    context "embeds_one" do
      let(:person) { Patient.new }
      let(:email) { Email.new(:address => "joe@example.com", :person => person) }
      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => email.attributes, :case_sensitive => true) }

      it "no validations are run" do
        email.expects(:where).never
        validator.setup(Email)
        validator.validate_each(email, :address, "joe@example.com")
      end

      context "when document has no parent" do
        let(:person) { stub.quacks_like(nil) }
        it "no validations are run" do
          person.expects(:address).never
          validator.setup(Email)
          validator.validate_each(email, :address, "joe@example.com")
        end
      end
    end
  end

  describe "#validate_each with :scope option given" do

    before do
      @document = Person.new(:employer_id => 3, :terms => true, :title => "")
      @criteria = stub(:exists? => false)
    end

    describe "as a symbol" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes,
                                                                      :scope => :employer_id, :case_sensitive => true) }

      it "should query only scoped documents" do
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => @document.attributes[:employer_id]).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

    end

    describe "as an array" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes,
                                                                      :scope => [:employer_id, :terms], :case_sensitive => true) }
      it "should query only scoped documents" do
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => @document.attributes[:employer_id]).returns(@criteria)
        @criteria.expects(:where).with(:terms => true).returns(@criteria)
        validator.setup(Person)
        validator.validate_each(@document, :title, "Sir")
      end

    end
  end
end
