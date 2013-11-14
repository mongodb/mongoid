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
    expect(Person.new).to respond_to(:_destroy)
  end

  describe "#_destroy" do

    it "always returns false" do
      expect(Person.new._destroy).to be false
    end
  end
end
