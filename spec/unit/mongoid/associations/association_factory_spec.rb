require File.join(File.dirname(__FILE__), "/../../../spec_helper.rb")

describe Mongoid::Associations::AssociationFactory do

  describe "#create" do

    before do
      @document = Person.new
    end

    context "when type is has_many" do

      it "returns a HasManyAssociationProxy" do
        association = Mongoid::Associations::AssociationFactory.create(:has_many, :addresses, @document)
        association.should be_a_kind_of(Mongoid::Associations::HasManyAssociation)
      end

    end

    context "when type is has_one" do

      it "returns a HashOneAssociationProxy" do
        association = Mongoid::Associations::AssociationFactory.create(:has_one, :name, @document)
        association.should be_a_kind_of(Mongoid::Associations::HasOneAssociation)
      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsToAssociationProxy" do
        association = Mongoid::Associations::AssociationFactory.create(:belongs_to, :person, @document)
        association.should be_a_kind_of(Mongoid::Associations::BelongsToAssociation)
      end

    end

    context "when type is invalid" do

      it "raises an InvalidAssociationError" do
        lambda { Mongoid::Associations::AssociationFactory.create(:something, :person, @document) }.should raise_error
      end

    end

  end

end
