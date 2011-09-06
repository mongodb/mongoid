require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  describe "#validate_each" do

    let(:document) do
      Person.new
    end

    let(:validator) do
      described_class.new(:attributes => document.attributes)
    end

    context "when a document exists with the attribute value" do

      before do
        @results = [ { '_id' => 'Sir' } ]
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds the errors to the document" do
        document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @results = [ { '_id' => 'Sir' } ]
        @drdocument = Doctor.new
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @results = Array.new
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds no errors" do
        document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @results = [ { '_id' => 'existing', 'username' => 'chitchins' } ]
            @criteria = stub
            Login.expects(:where).with(:username => "chitchins").returns(@criteria)
            @criteria.expects(:only).with(:_id).returns(@criteria)
            @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'chitchins' } ]
              @criteria = stub
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'chitchins' }, { '_id' => 'rdawkins' } ]
              @criteria = stub
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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

      let(:person) do
        Person.new
      end

      let(:favorite) do
        person.favorites.build(:title => "pizza")
      end

      let(:validator) do
        described_class.new(:attributes => favorite.attributes)
      end

      let(:criteria) do
        stub
      end

      it "excludes by attribute and id" do
        validator.setup(Favorite)
        validator.validate_each(favorite, :title, "pizza")
        favorite.errors.should be_empty
      end
    end

    context "embeds_one" do

      let!(:person) do
        Patient.new
      end

      let(:email) do
        Email.new(:address => "joe@example.com", :patient => person)
      end

      let(:validator) do
        described_class.new(:attributes => email.attributes)
      end

      it "no validations are run" do
        email.expects(:where).never
        validator.setup(Email)
        validator.validate_each(email, :address, "joe@example.com")
      end

      context "when document has no parent" do

        let(:email) do
          Email.new(:address => "joe@example.com")
        end

        it "no validations are run" do
          person.expects(:address).never
          validator.setup(Email)
          validator.validate_each(email, :address, "joe@example.com")
        end
      end
    end
  end

  describe "#validate_each with :scope option given" do

    let(:document) do
      Person.new(:employer_id => 3, :terms => true, :title => "")
    end

    before do
      @criteria = stub
    end

    describe "as a symbol" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => document.attributes,
                                                                      :scope => :employer_id) }

      it "should query only scoped documents" do
        @results = Array.new
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => document.attributes["employer_id"]).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

    end

    describe "as an array" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => document.attributes,
                                                                      :scope => [:employer_id, :terms]) }
      it "should query only scoped documents" do
        @results = Array.new
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => document.attributes["employer_id"]).returns(@criteria)
        @criteria.expects(:where).with(:terms => true).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

    end
  end

  describe "#validate_each with case sensitive true" do

    let(:document) do
      Person.new
    end

    let(:validator) do
      described_class.new(:attributes => document.attributes, :case_sensitive => true)
    end

    context "when a document exists with the attribute value" do

      before do
        @results = [ { '_id' => 'Sir' } ]
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds the errors to the document" do
        document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @results = [ { '_id' => 'Sir' } ]
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @results = [ ]
        @criteria = stub
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds no errors" do
        document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @results = [ { '_id' => 'existing' } ]
            @criteria = stub
            Login.expects(:where).with(:username => "chitchins").returns(@criteria)
            @criteria.expects(:only).with(:_id).returns(@criteria)
            @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'chitchins' } ]
              @criteria = stub
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'rdawkins' }, { '_id' => 'MatchingDocument' } ]
              @criteria = stub
              Login.expects(:where).with(:username => "chitchins").returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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

    let(:document) do
      Person.new
    end

    let(:validator) do
      described_class.new(:attributes => document.attributes, :case_sensitive => false)
    end

    context "when a document exists with the attribute value" do

      before do
        @results = [ { '_id' => 'MatchingDocument' } ]
        @criteria = stub
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds the errors to the document" do
        document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @criteria = stub
        @results = [ { '_id' => 'Doctor'} ]
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @results = Array.new
        @criteria = stub
        Person.expects(:where).with(:title => /^Sir$/i).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

      it "adds no errors" do
        document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do
      
      before do
        @criteria = stub
      end

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            @results = [ { '_id' => 'another_document' } ]
            Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
            @criteria.expects(:only).with(:_id).returns(@criteria)
            @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'chitchins' } ]
              Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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
              @results = [ { '_id' => 'rdawkins', '_id' => 'chitchins' } ]
              Login.expects(:where).with(:username => /^chitchins$/i).returns(@criteria)
              @criteria.expects(:only).with(:_id).returns(@criteria)
              @criteria.expects(:execute).returns(@results)
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

      let(:person) do
        Person.new
      end
      
      let(:criteria) do
        stub
      end
      
      context "for a new unique record" do

        let(:favorite) do
          person.favorites.build(:title => "pizza")
        end

        let(:validator) do
          described_class.new(:attributes => favorite.attributes, :case_sensitive => true)
        end

        it "excludes by attribute and id" do
          validator.setup(Favorite)
          validator.validate_each(favorite, :title, "pizza")
          favorite.errors.should be_empty
        end
        
      end
      
      
      context "for a new non-unique record" do
        
        before do
          person.favorites.create(:title => "pizza")
        end
        
        let(:favorite) do
          person.favorites.build(:title => "pizza")
        end
        
        let(:validator) do
          described_class.new(:attributes => favorite.attributes, :case_sensitive => true)
        end
        
        it "excludes by attribute and id" do
          validator.setup(Favorite)
          validator.validate_each(favorite, :title, "pizza")
          favorite.errors.should_not be_empty
        end
        
      end
    end

    context "embeds_one" do

      let(:person) do
        Patient.new
      end

      let(:email) do
        Email.new(:address => "joe@example.com", :person => person)
      end

      let(:validator) do
        described_class.new(:attributes => email.attributes, :case_sensitive => true)
      end

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

    let(:document) do
      Person.new(:employer_id => 3, :terms => true, :title => "")
    end

    before do
      @criteria = stub
    end

    describe "as a symbol" do

      let(:validator) do
        described_class.new(
          :attributes => document.attributes,
          :scope => :employer_id,
          :case_sensitive => true
        )
      end

      it "should query only scoped documents" do
        @results = Array.new
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => document.attributes["employer_id"]).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end

    end

    describe "as an array" do

      let(:validator) do
        described_class.new(
          :attributes => document.attributes,
          :scope => [:employer_id, :terms],
          :case_sensitive => true)
      end

      it "should query only scoped documents" do
        @results = Array.new
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        @criteria.expects(:where).with(:employer_id => document.attributes["employer_id"]).returns(@criteria)
        @criteria.expects(:where).with(:terms => true).returns(@criteria)
        @criteria.expects(:only).with(:_id).returns(@criteria)
        @criteria.expects(:execute).returns(@results)
        validator.setup(Person)
        validator.validate_each(document, :title, "Sir")
      end
    end
  end
end
