require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

class Person < Mongoid::Document
  field :title
  has_many :addresses
  has_one :name
end

class Address < Mongoid::Document
  field :street
  key :street
  belongs_to :person
end

class Name < Mongoid::Document
  field :first_name
  field :last_name
  key :first_name, :last_name
  belongs_to :person
end

describe Mongoid::Associations::Accessor do

  describe "#get" do

    before do
      @document = Person.new
      @object = stub
    end

    context "when type is has_many" do

      it "returns a HasMany" do
        association = Mongoid::Associations::Accessor.get(:has_many, :addresses, @document)
        association.should be_a_kind_of(Mongoid::Associations::HasMany)
      end

    end

    context "when type is has_one" do

      it "returns a HasOne" do
        association = Mongoid::Associations::Accessor.get(:has_one, :name, @document)
        association.should be_a_kind_of(Mongoid::Associations::HasOne)
      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        association = Mongoid::Associations::Accessor.get(:belongs_to, :person, @document)
        association.should be_a_kind_of(Mongoid::Associations::BelongsTo)
      end

    end

    context "when type is invalid" do

      it "raises an InvalidAssociationError" do
        lambda { Mongoid::Associations::Accessor.get(:something, :person, @document) }.should raise_error
      end

    end

  end

  describe "#set" do

    context "when type is has_many" do

      it "returns a HasMany" do
        Mongoid::Associations::HasMany.expects(:update).with(@document, @object, :addresses)
        Mongoid::Associations::Accessor.set(:has_many, :addresses, @document, @object)
      end

    end

    context "when type is has_one" do

      it "returns a HasOne" do
        Mongoid::Associations::HasOne.expects(:update).with(@document, @object, :name)
        Mongoid::Associations::Accessor.set(:has_one, :name, @document, @object)
      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        Mongoid::Associations::BelongsTo.expects(:update).with(@document, @object)
        Mongoid::Associations::Accessor.set(:belongs_to, :person, @document, @object)
      end

    end

    context "when type is invalid" do

      it "raises an InvalidAssociationError" do
        lambda {
          Mongoid::Associations::Accessor.set(:something, :person, @document, @object)
        }.should raise_error
      end

    end
  end

end
