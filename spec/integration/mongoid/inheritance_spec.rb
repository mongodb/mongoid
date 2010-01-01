require "spec_helper"

describe Mongoid::Document do

  context "when document is a subclass of a root class" do

    before do
      Browser.delete_all
      @browser = Browser.create(:version => 3, :name => "Test")
    end

    it "saves in the same collection as the root" do
      collection = Mongoid.database.collection("canvases")
      attributes = collection.find({ :name => "Test"}, {}).first
      attributes["version"].should == 3
      attributes["name"].should == "Test"
      attributes["_type"].should == "Browser"
      attributes["_id"].should == @browser.id
    end

  end

  context "when document is a subclass of a subclass" do

    before do
      Firefox.delete_all
      @firefox = Firefox.create(:version => 2, :name => "Testy")
    end

    it "saves in the same collection as the root" do
      collection = Mongoid.database.collection("canvases")
      attributes = collection.find({ :name => "Testy"}, {}).first
      attributes["version"].should == 2
      attributes["name"].should == "Testy"
      attributes["_type"].should == "Firefox"
      attributes["_id"].should == @firefox.id
    end

  end

end
