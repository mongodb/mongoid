require "spec_helper"

describe Mongoid::Associations::Options do

  describe "#name" do

    before do
      @attributes = { :name => :addresses }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the association name" do
      @options.name.should == :addresses
    end

  end

  describe "#foreign_key" do

    before do
      @attributes = { :name => :game }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the association foreign_key" do
      @options.foreign_key.should == "game_id"
    end

  end

  describe "#inverse_of" do

    before do
      @attributes = { :inverse_of => :addresses }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the inverse_of value" do
      @options.inverse_of.should == :addresses
    end

  end

  describe "#klass" do

    context "when class_name provided" do

      before do
        @attributes = { :class_name => "Person" }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "constantizes the class name" do
        @options.klass.should == Person
      end

    end

    context "when no class_name provided" do

      context "when association name is singular" do

        before do
          @attributes = { :name => :person }
          @options = Mongoid::Associations::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.klass.should == Person
        end

      end

      context "when association name is plural" do

        before do
          @attributes = { :name => :people }
          @options = Mongoid::Associations::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.klass.should == Person
        end

      end

    end

  end

  describe "#parent_key" do

    before do
      @attributes = { :parent_key => :person_id }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the parent's foreign key value" do
      @options.parent_key.should == :person_id
    end

  end

  describe "#polymorphic" do

    context "when attribute provided" do

      before do
        @attributes = { :polymorphic => true }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the attribute" do
        @options.polymorphic.should be_true
      end

    end

    context "when attribute not provided" do

      before do
        @options = Mongoid::Associations::Options.new
      end

      it "returns false" do
        @options.polymorphic.should be_false
      end

    end

  end

end
