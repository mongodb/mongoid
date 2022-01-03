# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Validatable do

  let(:account) do
    Account.new(name: "Testing a really long name.")
  end

  describe "#read_attribute_for_validation" do

    let(:person) do
      Person.new(title: "Mr")
    end

    let!(:address) do
      person.addresses.build(street: "Wienerstr")
    end

    context "when reading a field" do

      let(:value) do
        person.read_attribute_for_validation(:title)
      end

      it "returns the value" do
        expect(value).to eq("Mr")
      end
    end

    context "when reading a relation" do

      let(:value) do
        person.read_attribute_for_validation(:addresses)
      end

      let(:documents) do
        Mongoid::Association::Referenced::HasMany::Enumerable.new([ address ])
      end

      before do
        person.instance_variable_set(:@addresses, documents)
      end

      it "returns the value" do
        expect(value).to eq([ address ])
      end
    end

    context "when validating a non field" do

      let(:princess) do
        Princess.new
      end

      let(:value) do
        princess.read_attribute_for_validation(:color)
      end

      it "does not error on the read" do
        expect(value).to be_empty
      end
    end
  end

  describe "#valid?" do

    context "when provided a context" do

      it "uses the provided context" do
        expect(account).to be_valid(:update)
      end

      context 'when multiple contexts are provided' do

        let(:princess) do
          Princess.new
        end

        let(:validation) do
          princess.valid?([:create, :update])
        end

        it 'validates using each context' do
          expect(validation).to be(false)
          expect(princess.errors.messages.keys).to eq([:color, :name])
        end
      end
    end

    context "when not provided a context" do

      context "when the document is new" do

        it "defaults the context to :create" do
          expect(account).to_not be_valid
        end
      end

      context "when the document is persisted" do

        before do
          account.name = "Testing"
          account.save!
          account.name = "Testing a really long name."
        end

        it "defaults the context to :update" do
          expect(account).to be_valid
        end
      end
    end

    context "when the document is fresh from the database" do

      let!(:pizza) do
        Pizza.new(name: "chicago")
      end

      before do
        pizza.build_topping(name: "cheese")
        pizza.save!
      end

      let(:from_db) do
        Pizza.first
      end

      it "loads the required association from the db" do
        expect(from_db).to be_valid
      end
    end

    context "when validating associated" do

      context "when the child validates the parent" do

        let(:movie) do
          Movie.new
        end

        context "when the child is invalid" do

          let(:rating) do
            Rating.new(value: 1000)
          end

          before do
            movie.ratings << rating
          end

          context "when validating once" do

            it "returns false" do
              expect(movie).to_not be_valid
            end

            it "adds the errors to the document" do
              movie.valid?
              expect(movie.errors[:ratings]).to eq([ "is invalid" ])
            end
          end

          context "when validating multiple times" do

            it "returns false every time" do
              expect(movie).to_not be_valid
              expect(movie).to_not be_valid
            end
          end
        end
      end

      context "when the child does not validate the parent" do

        before(:all) do
          Person.validates_associated(:services)
        end

        after(:all) do
          Person.reset_callbacks(:validate)
        end

        let(:person) do
          Person.new
        end

        context "when the child is invalid" do

          let(:service) do
            Service.new(sid: "invalid")
          end

          before do
            person.services << service
          end

          context "when validating once" do

            it "returns false" do
              expect(person).to_not be_valid
            end

            it "adds the errors to the document" do
              person.valid?
              expect(person.errors[:services]).to eq([ "is invalid" ])
            end
          end

          context "when validating multiple times" do

            it "returns false every time" do
              expect(person).to_not be_valid
              expect(person).to_not be_valid
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
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::AssociatedValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, associated: true)
      end

      it "adds the validator" do
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::AssociatedValidator
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
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::UniquenessValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, uniqueness: true)
      end

      it "adds the validator" do
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::UniquenessValidator
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
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::PresenceValidator
        )
      end
    end

    context "when adding via the new syntax" do

      before do
        klass.validates(:name, presence: true)
      end

      it "adds the validator" do
        expect(klass.validators.first).to be_a(
          Mongoid::Validatable::PresenceValidator
        )
      end
    end
  end
end
