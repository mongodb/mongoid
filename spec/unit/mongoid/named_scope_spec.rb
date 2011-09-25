require "spec_helper"

describe Mongoid::NamedScope do

  describe ".scope" do

    it "adds a class method for the scope" do
      Player.should respond_to(:active)
    end

    it "adds the scope to the scopes" do
      Player.scopes.should include(:active)
    end

    it "aliases to named_scope" do
      Player.should respond_to(:deaths_over)
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

      it "adds a class method for the scope" do
        Player.should respond_to(:deaths_over)
      end

      it "adds the scope to the scopes" do
        Player.scopes.should include(:deaths_over)
      end
    end

    context "when overrides a class method" do

      let(:logger) { stub.quacks_like(Logger.allocate) }

      before do
        Mongoid.stubs(:logger => logger)
      end

      it "sends warning message to logger on public method" do
        logger.expects(:warn)
        Override.scope :public_method
      end

      it "sends warning message to logger on protected method" do
        logger.expects(:warn)
        Override.scope :protected_method
      end

      it "sends warning message to logger on private method" do
        logger.expects(:warn)
        Override.scope :private_method
      end
    end
  end

  context "when chaining scopes" do

    context "when chaining two named scopes" do

      let(:selector) do
        Player.active.frags_over(10).selector
      end

      it "retains the first criteria" do
        selector[:active].should be_true
      end

      it "retains the second criteria" do
        selector[:frags].should == { "$gt" => 10 }
      end

      context "when both scoped have in clauses" do

        let!(:chained) do
          Event.best.by_kind("party")
        end

        let(:initial) do
          Event.best
        end

        it "does not modify the initial scope" do
          initial.selector.should eq(
            { :kind => { "$in" => [ "party", "concert" ]}}
          )
        end
      end
    end

    context "when chaining named scoped with criteria class methods" do

      let(:selector) do
        Player.active.frags_over(10).alive.selector
      end

      it "retains the first criteria" do
        selector[:active].should be_true
      end

      it "retains the second criteria" do
        selector[:frags].should == { "$gt" => 10 }
      end

      it "retains the class method criteria" do
        selector[:status].should == "Alive"
      end
    end
  end

  describe ".scoped" do

    context "when a default scope is provided" do

      let(:criteria) do
        Acolyte.scoped
      end

      it "returns a criteria with default scoping options" do
        criteria.options.should == { :sort => [[ :name, :asc ]] }
      end
    end

    context "when no default scope is provided" do

      let(:criteria) do
        Person.scoped
      end

      it "returns a criteria with no default scoping" do
        criteria.selector.should == {}
      end

      it "returns a criteria with no default options" do
        criteria.options.should == {}
      end
    end
  end

  describe ".scope_stack" do

    context "when a scope is on the stack" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false)
      end

      before do
        Person.scope_stack << criteria
      end

      after do
        Person.scope_stack.clear
      end

      it "returns the scope stack for the class" do
        Person.scope_stack.should == [ criteria ]
      end
    end

    context "when no scope is on the stack" do

      it "returns an empty array" do
        Person.scope_stack.should == []
      end
    end
  end

  describe ".unscoped" do

    let(:criteria) do
      Acolyte.unscoped
    end

    it "returns a criteria with no selector" do
      criteria.selector.should == {}
    end

    it "returns a criteria with no options" do
      criteria.options.should == {}
    end
  end
end
