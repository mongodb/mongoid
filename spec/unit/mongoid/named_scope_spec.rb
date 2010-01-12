require "spec_helper"

describe Mongoid::NamedScope do

  class Player
    include Mongoid::Document
    field :active, :type => Boolean
    field :frags, :type => Integer
    field :deaths, :type => Integer
    field :status

    named_scope :active, criteria.where(:active => true) do
      def extension
        "extension"
      end
    end
    named_scope :inactive, :where => { :active => false }
    named_scope :frags_over, lambda { |count| { :where => { :frags.gt => count } } }
    named_scope :deaths_under, lambda { |count| criteria.where(:deaths.lt => count) }

    class << self
      def alive
        criteria.where(:status => "Alive")
      end
    end
  end

  describe ".named_scope" do

    it "adds a class method for the scope" do
      Player.should respond_to(:active)
    end

    it "adds the scope to the scopes" do
      Player.scopes.should include(:active)
    end

    context "when options are a hash" do

      it "adds the selector to the scope" do
        Player.inactive.selector[:active].should be_false
      end

    end

    context "when options are a criteria" do

      it "adds the selector to the scope" do
        Player.active.selector[:active].should be_true
      end

    end

    context "when options are a proc" do

      context "when the proc delegates to a hash" do

        it "adds the selector to the scope" do
          Player.frags_over(50).selector[:frags].should == { "$gt" => 50 }
        end

      end

      context "when the proc delegates to a criteria" do

        it "adds the selector to the scope" do
          Player.deaths_under(40).selector[:deaths].should == { "$lt" => 40 }
        end

      end

    end

    context "when a block is supplied" do

      it "adds the block as an extension" do
        Player.active.extension.should == "extension"
      end

    end

  end

  context "chained scopes" do

    context "when chaining two named scopes" do

      it "merges the criteria" do
        selector = Player.active.frags_over(10).selector
        selector[:active].should be_true
        selector[:frags].should == { "$gt" => 10 }
      end

    end

    context "when chaining named scoped with criteria class methods" do

      it "merges the criteria" do
        selector = Player.active.frags_over(10).alive.selector
        selector[:active].should be_true
        selector[:frags].should == { "$gt" => 10 }
        selector[:status].should == "Alive"
      end

    end

  end

end

