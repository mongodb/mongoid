require "spec_helper"

class WikiPage
  include Mongoid::Document
  include Mongoid::Versioning

  max_versions 5

  field :title, :type => String
end

describe Mongoid::Versioning do
  before do
    @page = WikiPage.new :title => "1st Title"
    @page.save
  end

  describe "#version" do
    it "defaults to 1" do
      @page.version.should == 1
    end

    context "document changes once" do
      before do
        @page.title = "2nd Title"
        @page.save
      end

      it "should be on its second version " do
        @page.version.should == 2
      end
    end
  end

  context "when hitting version_max" do
    before do
      @page.update_attributes(:title => "2nd Title")
      @page.update_attributes(:title => "3rd Title")
      @page.update_attributes(:title => "4th Title")
      @page.update_attributes(:title => "5th Title")
      @page.update_attributes(:title => "6th Title")
    end

    it "should be on its 6th version" do
      @page.version.should == 6
    end

    it "should store all 5 of its old copies" do
      @page.versions.map(&:title).should == [
        "1st Title",
        "2nd Title",
        "3rd Title",
        "4th Title",
        "5th Title"
      ]
    end

    context "when exceeding version_max" do
      before do
        @page.update_attributes(:title => "7th Title")
      end

      it "be on its 7th version" do
        @page.version.should == 7
      end

      it "should only store 5 of its old copies" do
        @page.versions.map(&:title).should == [
          "2nd Title",
          "3rd Title",
          "4th Title",
          "5th Title",
          "6th Title"
        ]
      end
    end

  end
end