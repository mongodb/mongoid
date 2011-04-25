require "spec_helper"

describe Mongoid::Callbacks do

  class TestClass
    include Mongoid::Callbacks
  end

  it "CALLBACKS includes all callbacks" do
    Mongoid::Callbacks::CALLBACKS.should =~ TestClass.methods.map(&:to_s).grep(/^(before|after|around)_/).map(&:to_sym).reject do |method|
      # deprecated callbacks
      [:after_validation_on_create, :after_validation_on_update, :before_validation_on_create, :before_validation_on_update].include? method
    end
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
  
  describe ".before_save" do

    before do
      @artist = Artist.create(:name => "Depeche Mode")
      @artist.name = "The Mountain Goats"
    end
    
    after do
      @artist.delete
    end

    context "callback returns true" do
      before do
        @artist.expects(:before_save_stub).returns(true)
      end

      it "should return true" do
        @artist.save.should == true
      end
    end

    context "callback returns false" do
      before do
        @artist.expects(:before_save_stub).returns(false)
      end

      it "should return false" do
        @artist.save.should == false
      end
    end
  end
  
  describe ".before_destroy" do
  
    before do
      @artist = Artist.create(:name => "Depeche Mode")
      @artist.name = "The Mountain Goats"
    end

    after do
      @artist.delete
    end

    context "callback returns true" do
      before do
        @artist.expects(:before_destroy_stub).returns(true)
      end

      it "should return true" do
        @artist.destroy.should == true
      end
    end

    context "callback returns false" do
      before do
        @artist.expects(:before_destroy_stub).returns(false)
      end

      it "should return false" do
        @artist.destroy.should == false
      end
    end
  end
  
end
