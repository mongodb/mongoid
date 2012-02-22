require 'spec_helper'

describe "A document loaded from rails" do
  before(:all) do
    require 'mongoid/railties/document'
  end

  after(:all) do
    Mongoid::Document.class_eval do
      undef _destroy
    end
  end

  it "defines a _destroy method" do
    Person.new.should respond_to(:_destroy)
  end

  describe "#_destroy" do

    it "always returns false" do
      Person.new._destroy.should be_false
    end
  end
end
