require "spec_helper"

describe Mongoid::Versioning do

  describe "#version" do

    before do
      @post = Post.new
    end

    it "defaults to 1" do
      @post.version.should == 1
    end

    context "when document is saved" do

      before do
        @post.title = "New"
        @version = Post.new(:title => "Test")
        Post.expects(:first).at_least(1).with(:conditions => { :_id => @post.id, :version => 1 }).returns(@version)
        @post.revise
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

      context "when a max_versions limit has been set" do

        before do
          Post.max_versions 1
        end

        it "adds a snapshot of the document to the versions if it hasn't been exceeded" do
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
          @post.revise
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

end
