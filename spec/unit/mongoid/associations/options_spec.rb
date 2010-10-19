require "spec_helper"

describe Mongoid::Associations::Options do

  describe "#dependent" do

    context "when dependent option exists" do

      before do
        @attributes = { :dependent => :destroy }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the option" do
        @options.dependent.should == :destroy
      end
    end
  end

  describe "#extend" do

    context "when extension exists" do

      before do
        @attributes = { :extend => lambda { "Test" } }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the proc" do
        @options.extension.should == @attributes[:extend]
      end
    end

    context "when extension doesnt exist" do

      before do
        @options = Mongoid::Associations::Options.new({})
      end

      it "returns nil" do
        @options.extension.should be_nil
      end
    end
  end

  describe "extension?" do

    context "when extension exists" do

      before do
        @attributes = { :extend => lambda { "Test" } }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns true" do
        @options.extension?.should be_true
      end
    end

    context "when extension doesnt exist" do

      before do
        @options = Mongoid::Associations::Options.new({})
      end

      it "returns false" do
        @options.extension?.should be_false
      end
    end
  end

  describe "#foreign_key" do

    context "when no custom key defined" do

      before do
        @attributes = { :name => :posts }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the association foreign_key" do
        @options.foreign_key.should == "post_id"
      end
    end

    context "when a custom key is defined" do

      before do
        @attributes = { :name => :posts, :foreign_key => "blog_post_id" }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the custom foreign_key" do
        @options.foreign_key.should == "blog_post_id"
      end
    end
  end

  describe "#default_order" do

    context "when no default_order defined" do

      before do
        @attributes = { :name => :posts }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns nil" do
        @options.default_order.should be_nil
      end
    end

    context "when an default_order is defined" do
      before do
        @attributes = { :name => :posts, :default_order => :blog_post_id.asc }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the custom default_order criteria object" do
        @options.default_order.key.should == :blog_post_id.asc.key
        @options.default_order.operator.should == :blog_post_id.asc.operator
      end
    end
  end

  describe "#index" do

    context "when not defined" do

      before do
        @attributes = { :name => :posts }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "defaults to false" do
        @options.index.should == false
      end
    end

    context "when defined" do

      before do
        @attributes = { :name => :posts, :index => true }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "returns the defined value" do
        @options.index.should == true
      end
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

  describe "#class_name" do

    context "when class_name provided" do

      before do
        @attributes = { :class_name => "Person" }
        @options = Mongoid::Associations::Options.new(@attributes)
      end

      it "constantizes the class name" do
        @options.class_name.should == "Person"
      end
    end

    context "when no class_name provided" do

      context "when association name is singular" do

        before do
          @attributes = { :name => :person }
          @options = Mongoid::Associations::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.class_name.should == "Person"
        end
      end

      context "when association name is plural" do

        before do
          @attributes = { :name => :people }
          @options = Mongoid::Associations::Options.new(@attributes)
        end

        it "classifies and constantizes the association name" do
          @options.class_name.should == "Person"
        end
      end
    end
  end

  describe "#klass" do
    before do
      @options = Mongoid::Associations::Options.new(:name => :person)
    end

    it "constantizes the class_name" do
      @options.klass.should == Person
    end
  end

  describe "#name" do

    before do
      @attributes = { :name => :addresses }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the association name" do
      @options.name.should == "addresses"
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

  describe "#stored_as" do

    before do
      @attributes = { :stored_as => :array }
      @options = Mongoid::Associations::Options.new(@attributes)
    end

    it "returns the association storage" do
      @options.stored_as.should == :array
    end
  end
end
