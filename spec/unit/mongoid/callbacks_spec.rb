require "spec_helper"

describe Mongoid::Callbacks do

  describe ".included" do

    before do
      @class = Class.new do
        include Mongoid::Callbacks
      end
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

  end

end
