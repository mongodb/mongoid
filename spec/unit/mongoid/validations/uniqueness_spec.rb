require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  describe "#validate_each" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:empty? => false)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        @document.errors[:title][0].should == "is already taken"
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @criteria = stub(:empty? => true)
        Person.expects(:where).with(:title => "Sir").returns(@criteria)
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
            Login.expects(:where).with(:username => "chitchins").returns([ login ])
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
              Login.expects(:where).with(:username => "chitchins").returns([ login ])
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should be_empty
            end
          end

          context "when the has changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "rdawkins")
              login.instance_variable_set(:@new_record, false)
              login.username = "chitchins"
              login
            end

            before do
              Login.expects(:where).with(:username => "chitchins").returns([ login ])
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
end
