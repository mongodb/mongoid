require "spec_helper"

describe Mongoid::Callbacks do

  class TestClass
    include Mongoid::Callbacks
  end

  describe ".included" do

    before do
      @class = TestClass
    end

    it "includes the before_create callback" do
      @class.should respond_to(:before_create)
    end

    it "includes the after_create callback" do
      @class.should respond_to(:after_create)
    end

    it "includes the before_destroy callback" do
      @class.should respond_to(:before_destroy)
    end

    it "includes the after_destroy callback" do
      @class.should respond_to(:after_destroy)
    end

    it "includes the before_save callback" do
      @class.should respond_to(:before_save)
    end

    it "includes the after_save callback" do
      @class.should respond_to(:after_save)
    end

    it "includes the before_update callback" do
      @class.should respond_to(:before_update)
    end

    it "includes the after_update callback" do
      @class.should respond_to(:after_update)
    end

    it "includes the before_validation callback" do
      @class.should respond_to(:before_validation)
    end

    it "includes the after_validation callback" do
      @class.should respond_to(:after_validation)
    end

    it "includes the after_initialize callback" do
      @class.should respond_to(:after_initialize)
    end
  end

  describe ".after_initialize" do

    let(:game) do
      Game.new
    end

    it "runs after document instantiation" do
      game.name.should == "Testing"
    end
  end

  describe ".before_create" do

    before do
      @artist = Artist.new(:name => "Depeche Mode")
    end

    context "callback returns true" do
      before do
        @artist.expects(:before_create_stub).returns(true)
      end

      it "should get saved" do
        @artist.save.should == true
        @artist.persisted?.should == true
      end
    end

    context "callback returns false" do
      before do
        @artist.expects(:before_create_stub).returns(false)
      end

      it "should not get saved" do
        @artist.save.should == false
        @artist.persisted?.should == false
      end
    end
  end
end
