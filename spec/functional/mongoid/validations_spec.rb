require "spec_helper"

describe Mongoid::Validations do

  before do
    [ Pizza, Topping ].each(&:delete_all)
  end

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

    context "when the document is fresh from the database" do

      let!(:pizza) do
        Pizza.new(:name => "chicago")
      end

      before do
        pizza.build_topping(:name => "cheese")
        pizza.save
      end

      let(:from_db) do
        Pizza.first
      end

      it "loads the required association from the db" do
        from_db.should be_valid
      end
    end

    context "when validating associated" do

      context "when the child validates the parent" do

        let(:movie) do
          Movie.new
        end

        context "when the child is invalid" do

          let(:rating) do
            Rating.new(:value => 1000)
          end

          before do
            movie.ratings << rating
          end

          context "when validating once" do

            it "returns false" do
              movie.should_not be_valid
            end

            it "adds the errors to the document" do
              movie.valid?
              movie.errors[:ratings].should == [ "is invalid" ]
            end
          end

          context "when validating multiple times" do

            it "returns false every time" do
              movie.should_not be_valid
              movie.should_not be_valid
            end
          end
        end
      end

      context "when the child does not validate the parent" do

        let(:person) do
          Person.new(:ssn => "123-45-4444")
        end

        context "when the child is invalid" do

          let(:service) do
            Service.new(:sid => "invalid")
          end

          before do
            person.services << service
          end

          context "when validating once" do

            it "returns false" do
              person.should_not be_valid
            end

            it "adds the errors to the document" do
              person.valid?
              person.errors[:services].should == [ "is invalid" ]
            end
          end

          context "when validating multiple times" do

            it "returns false every time" do
              person.should_not be_valid
              person.should_not be_valid
            end
          end
        end
      end
    end
  end
end
