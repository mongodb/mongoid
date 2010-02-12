require "spec_helper"

describe Mongoid::Scope do

  before do
    Person.delete_all
  end

  describe "#==" do

    before do
      @scope = Mongoid::Scope.new(Person, {})
    end

    context "when other is a scope" do

      context "when the parent and conditions match" do

        before do
          @other = Mongoid::Scope.new(Person, {})
        end

        it "returns true" do
          @scope.should == @other
        end

      end

      context "when the conditions do not match" do

        before do
          @other = Mongoid::Scope.new(Person, { :where => { :field => "value" } })
        end

        it "returns false" do
          @scope.should_not == @other
        end
      end

    end

    context "when other is an enumerable" do

      context "when the array contents are equal" do

        before do
          @other = []
        end

        it "returns true" do
          @scope.should == @other
        end

      end

      context "when the array contents are not equal" do

        before do
          @other = [ stub ]
        end

        it "returns false" do
          @scope.should_not == @other
        end

      end
    end

    context "when other is an invalid type" do

      it "returns false" do
        Mongoid::Scope.new(Person, {}).should_not == stub
      end

    end

  end

  describe ".initialize" do

    before do
      @parent = Mongoid::Scope.new(Person, {})
    end

    context "when parent is another scope" do

      before do
        @scope = Mongoid::Scope.new(@parent, {})
      end

      it "does not set the class" do
        @scope.klass.should be_nil
      end

    end

    context "when parent is a class" do

      before do
        @scope = Mongoid::Scope.new(Person, {})
      end

      it "returns the parent class" do
        @scope.klass.should == Person
      end

    end

    context "when a block is passed in" do

      before do
        @scope = Mongoid::Scope.new(Person, {}) do
          def extended
            "extended"
          end
        end
      end

      it "extends the block" do
        @scope.extended.should == "extended"
      end

    end

  end

  describe "#method_missing" do

    context "when a scope has been defined for the name" do

      before do
        @defined = mock
        @class = mock
        @class.expects(:scopes).twice.returns({ :testing => @defined })
        @scope = Mongoid::Scope.new(@class, {})
      end

      it "calls the matching scope" do
        @defined.expects(:call).with(@scope, "Testing").returns(true)
        @scope.testing("Testing").should be_true
      end

    end

    context "when a scope is not defined for the name" do

      context "when the scope is the parent" do

        before do
          @target = mock
          @scope = Mongoid::Scope.new(Person, {})
          @scope.instance_variable_set("@target", @target)
        end

        it "sends the call to the target" do
          @target.expects(:testing).with("Testing").returns(true)
          @scope.testing("Testing").should be_true
        end

      end

      context "when the scope is not the parent" do

        before do
          @parent = mock
          @criteria = mock
          @parent.expects(:scopes).returns({})
          @parent.expects(:is_a?).with(Mongoid::Scope).returns(true)
          @parent.expects(:fuse)
          @scope = Mongoid::Scope.new(@parent, {})
        end

        it "creates a criteria from the parent scope" do
          @parent.expects(:testing).returns(true)
          @scope.testing.should be_true
        end

      end

    end

  end

  describe "#respond_to?" do

    context "when parent is a class" do

      before do
        @scope = Mongoid::Scope.new(Person, {})
      end

      it "delegates to the target" do
        @scope.respond_to?(:only).should be_true
      end

    end

    context "when parent is a scope" do

      before do
        @parent = Mongoid::Scope.new(Person, {})
        @scope = Mongoid::Scope.new(@parent, {})
      end

      it "delegates to the parent" do
        @scope.respond_to?(:only).should be_true
      end

    end

  end

  describe "#scopes" do

    before do
      @parent = mock
      @scope = Mongoid::Scope.new(@parent, {})
    end

    it "delegates to the parent" do
      @parent.expects(:scopes).returns({})
      @scope.scopes.should == {}
    end

  end

  describe "#target" do

    before do
      @scope = Mongoid::Scope.new(Person, { :where => { :title => "Sir" } })
    end

    it "returns the conditions criteria" do
      @scope.target.selector.should ==
        { :title => "Sir" }
    end

  end

end
