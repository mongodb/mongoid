require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Associations::Accessor do

  describe "#get" do

    before do
      @document = Person.new
      @object = stub
    end

    context "when type is has_many" do

      it "returns a HasMany" do
        association = Mongoid::Associations::Accessor.get(Mongoid::Associations::HasMany, :addresses, @document)
        association.should be_a_kind_of(Mongoid::Associations::HasMany)
      end

    end

    context "when type is has_one" do

      context "when document is not nil" do

        it "returns a HasOne" do
          association = Mongoid::Associations::Accessor.get(Mongoid::Associations::HasOne, :name, @document)
          association.should be_a_kind_of(Name)
        end

      end

      context "when document is nil" do

        it "returns nil" do
          association = Mongoid::Associations::Accessor.get(Mongoid::Associations::HasOne, :name, nil)
          association.should be_nil
        end

      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        association = Mongoid::Associations::Accessor.get(Mongoid::Associations::BelongsTo, :person, stub(:parent => @document))
        association.should be_a_kind_of(Person)
      end

    end

  end

  describe "#set" do

    context "when type is has_many" do

      it "returns a HasMany" do
        Mongoid::Associations::HasMany.expects(:update).with(@document, @object, :addresses)
        Mongoid::Associations::Accessor.set(Mongoid::Associations::HasMany, :addresses, @document, @object)
      end

    end

    context "when type is has_one" do

      it "returns a HasOne" do
        Mongoid::Associations::HasOne.expects(:update).with(@document, @object, :name)
        Mongoid::Associations::Accessor.set(Mongoid::Associations::HasOne, :name, @document, @object)
      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        Mongoid::Associations::BelongsTo.expects(:update).with(@object, @document, :person)
        Mongoid::Associations::Accessor.set(Mongoid::Associations::BelongsTo, :person, @document, @object)
      end

    end

  end

end
