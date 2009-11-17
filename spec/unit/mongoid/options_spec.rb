require File.expand_path(File.join(File.dirname(__FILE__), "/../../spec_helper.rb"))

describe Mongoid::Options do

  describe "#association_name" do

    before do
      @attributes = { :association_name => :addresses }
      @options = Mongoid::Options.new(@attributes)
    end

    it "returns the association name" do
      @options.association_name.should == :addresses
    end

  end

  describe "#klass" do

    context "when class_name provided" do

      before do
        @attributes = { :class_name => "Person" }
        @options = Mongoid::Options.new(@attributes)
      end

      it "constantizes the class name" do
        @options.klass.should == Person
      end

    end

    context "when no class_name provided" do

      context "when association name is singular" do

        before do
          @attributes = { :association_name => :person }
          @options = Mongoid::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.klass.should == Person
        end

      end

      context "when association name is plural" do

        before do
          @attributes = { :association_name => :people }
          @options = Mongoid::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.klass.should == Person
        end

      end


    end

  end

  describe "#polymorphic" do

    context "when attribute provided" do

      before do
        @attributes = { :polymorphic => true }
        @options = Mongoid::Options.new(@attributes)

      end

      it "returns the attribute" do
        @options.polymorphic.should be_true
      end

    end

    context "when attribute not provided" do

      before do
        @options = Mongoid::Options.new
      end

      it "returns false" do
        @options.polymorphic.should be_false
      end

    end

  end

end
