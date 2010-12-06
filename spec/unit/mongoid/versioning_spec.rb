require "spec_helper"

describe Mongoid::Versioning do

  describe "#version" do

    def first_update_post
      @post.title = "New"
      @version = Post.new(:title => "Test")
      Post.expects(:first).at_least(1).with(:conditions => { :_id => @post.id, :version => 1 }).returns(@version)
      @post.save
      @post.reload
    end

    before do
      @post = Post.new
    end

    it "defaults to 1" do
      @post.version.should == 1
    end

    context "when document is saved" do

      before do
        first_update_post
      end

      it "increments the version" do
        @post.version.should == 2
      end

      it "adds a snapshot of the document to the versions" do
        @post.title.should == "New"
        @post.version.should == 2
        @post.versions.size.should == 1
        version = @post.versions.first
        version.title.should == "Test"
        version.version.should == 1
      end
      
    end
    
    context "when a max_versions limit has been set to 0" do

      before do
        Post.max_versions 0
        first_update_post
      end

      it "update version number without actually saving old versions" do
        @post.title.should == "New"
        @post.version.should == 2
        @post.versions.size.should == 0
      end

    end
    
    context "when a max_versions limit has been set to > 0" do

      before do
        Post.max_versions 1
        first_update_post
      end

      it "update version number and save old versions" do
        @post.title.should == "New"
        @post.version.should == 2
        @post.versions.size.should == 1
        version = @post.versions.first
        version.title.should == "Test"
        version.version.should == 1
      end

      it "discards the oldest version if it's been exceeded" do
        @previous_version = @post.clone
        @post.title = "Another change"
        Post.expects(:first).at_least(1).with(:conditions => { :_id => @post.id, :version => 2 }).returns(@previous_version)
        @post.save
        @post.reload
        @post.title.should == "Another change"
        @post.version.should == 3
        @post.versions.size.should == 1
        latest_version = @post.versions.first
        latest_version.title.should == "New"
        latest_version.version.should == 2
      end

    end

  end

end
