require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Associations::Accessor do

  describe "#get" do

    before do
      @document = Person.new
      @object = stub
    end

    context "when type is has_many" do

      it "returns a HasMany" do
        @options = Mongoid::Associations::Options.new(:name => :addresses)
        association = Mongoid::Associations::Accessor.get(
          Mongoid::Associations::HasMany,
          @document,
          @options
        )
        association.should be_a_kind_of(Mongoid::Associations::HasMany)
      end

    end

    context "when type is has_one" do

      context "when document is not nil" do

        it "returns a HasOne" do
          @options = Mongoid::Associations::Options.new(:name => :name)
          association = Mongoid::Associations::Accessor.get(
            Mongoid::Associations::HasOne,
            @document,
            @options
          )
          association.should be_a_kind_of(Name)
        end

      end

      context "when document is nil" do

        it "returns nil" do
          @options = Mongoid::Associations::Options.new(:name => :name)
          association = Mongoid::Associations::Accessor.get(
            Mongoid::Associations::HasOne,
            nil,
            @options
          )
          association.should be_nil
        end

      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        @options = Mongoid::Associations::Options.new(:name => :person)
        association = Mongoid::Associations::Accessor.get(
          Mongoid::Associations::BelongsTo,
          stub(:parent => @document),
          @options
        )
        association.should be_a_kind_of(Person)
      end

    end

  end

  describe "#set" do

    context "when type is has_many" do

      it "returns a HasMany" do
        @options = Mongoid::Associations::Options.new(:name => :addresses)
        Mongoid::Associations::HasMany.expects(:update).with(@document, @object, @options)
        Mongoid::Associations::Accessor.set(
          Mongoid::Associations::HasMany,
          @document,
          @object,
          @options
        )
      end

    end

    context "when type is has_one" do

      it "returns a HasOne" do
        @options = Mongoid::Associations::Options.new(:name => :name)
        Mongoid::Associations::HasOne.expects(:update).with(@document, @object, @options)
        Mongoid::Associations::Accessor.set(
          Mongoid::Associations::HasOne,
          @document,
          @object,
          @options
        )
      end

    end

    context "when type is belongs_to" do

      it "returns a BelongsTo" do
        @options = Mongoid::Associations::Options.new(:name => :person)
        Mongoid::Associations::BelongsTo.expects(:update).with(@object, @document, @options)
        Mongoid::Associations::Accessor.set(
          Mongoid::Associations::BelongsTo,
          @document,
          @object,
          @options
        )
      end

    end

  end

end
