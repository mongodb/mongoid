require "spec_helper"

describe Mongoid::Versioning do

  before(:all) do
    WikiPage.delete_all
  end

  describe "#version" do

    let(:page) do
      WikiPage.new(:title => "1")
    end

    context "when the document is new" do

      it "defaults to 1" do
        page.version.should == 1
      end
    end

    context "after the document's first save" do

      before do
        page.save
      end

      it "returns 1" do
        page.version.should == 1
      end
    end

    context "when saving multiple times" do

      it "increments the version by 1" do
        3.times do |n|
          page.update_attribute(:title, "#{n}")
          page.version.should == n + 1
        end
      end
    end

    context "when skipping versioning" do

      it "does not version" do
        3.times do |n|
          page.versionless do |doc|
            doc.update_attribute(:title, "#{n}")
          end
        end
        page.version.should == 1
      end
    end
  end

  describe "#versions" do

    let(:page) do
      WikiPage.create(:title => "1")
    end

    context "when version is less than the maximum" do

      before do
        4.times do |n|
          page.title = "#{n + 2}"
          page.save
        end
      end

      let(:expected) do
        [ "1", "2", "3", "4" ]
      end

      it "retains all versions" do
        page.versions.size.should == 4
      end

      it "retains the correct values" do
        page.versions.map(&:title).should == expected
      end
    end

    context "when version is over the maximum" do

      before do
        7.times do |n|
          page.title = "#{n + 2}"
          page.save
        end
      end

      let(:expected) do
        [ "3", "4", "5", "6", "7" ]
      end

      it "retains the set number of most recent versions" do
        page.versions.size.should == 5
      end

      it "retains the most recent values" do
        page.versions.map(&:title).should == expected
      end
    end

    it "should not version versions attributes" do
      3.times do |n|
        page.title = "#{n + 2}"
        page.save
      end

      page.versions[1].versions.should == []
      page.versions[2].versions.should == []
    end
  end
end
