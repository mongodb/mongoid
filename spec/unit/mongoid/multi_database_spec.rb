require "spec_helper"

describe Mongoid::MultiDatabase do
  before do
    @klass = Class.new do
      include Mongoid::Document
    end
  end

  describe ".database" do
    before do
      @klass.set_database :secondary
    end

    it "sets the database key on the class" do
      @klass.database.should == "secondary"
    end
  end
end
