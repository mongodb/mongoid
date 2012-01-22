require "spec_helper"

describe Mongoid::Validations do

  let(:account) do
    Account.new(:name => "Testing a really long name.")
  end

  describe "#read_attribute_for_validation" do

    let(:person) do
      Person.new(:title => "Mr")
    end

    let!(:address) do
      person.addresses.build(:street => "Wienerstr")
    end

    context "when reading a field" do

      let(:value) do
        person.read_attribute_for_validation(:title)
      end

      it "returns the value" do
        value.should eq("Mr")
      end
    end

    context "when reading a relation" do

      let(:value) do
        person.read_attribute_for_validation(:addresses)
      end

      let(:documents) do
        Mongoid::Relations::Targets::Enumerable.new([ address ])
      end

      before do
        person.instance_variable_set(:@addresses, documents)
      end

      it "returns the value" do
        value.should eq([ address ])
      end
    end
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
              movie.errors[:ratings].should eq([ "is invalid" ])
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
              person.errors[:services].should eq([ "is invalid" ])
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

  describe ".validates_associated" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when adding via the traditional macro" do

      before do
        klass.validates_associated(:name)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::AssociatedValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, :associated => true)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::AssociatedValidator
        )
      end
    end
  end

  describe ".validates_uniqueness_of" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when adding via the traditional macro" do

      before do
        klass.validates_uniqueness_of(:name)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::UniquenessValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, :uniqueness => true)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::UniquenessValidator
        )
      end
    end
  end

  describe ".validates_presence_of" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when adding via the traditional macro" do

      before do
        klass.validates_presence_of(:name)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::PresenceValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, :presence => true)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::PresenceValidator
        )
      end
    end
  end
  
  describe ".validates_format_of" do

    let(:klass) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when adding via the traditional macro" do

      before do
        klass.validates_format_of(:website, :with => URI.regexp)
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::FormatValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:website, :format => { :with => URI.regexp })
      end

      it "adds the validator" do
        klass.validators.first.should be_a(
          Mongoid::Validations::FormatValidator
        )
      end
    end
  end
end
