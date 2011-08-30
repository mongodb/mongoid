require "spec_helper"

describe Mongoid::Paranoia do

  let(:collection) do
    stub
  end

  let(:command) do
    stub
  end

  let(:remove_klass) do
    Mongoid::Persistence::Operations::Remove
  end

  describe "#delete!" do

    let(:post) do
      ParanoidPost.new
    end

    it "removes the document from the database" do
      remove_klass.expects(:new).with(post, {}).returns(command)
      command.expects(:persist).returns(true)
      post.delete!
    end

    it "sets destroyed to true" do
      remove_klass.expects(:new).with(post, {}).returns(command)
      command.expects(:persist).returns(true)
      post.delete!
      post.should be_destroyed
    end
  end

  describe "#destroyed?" do

    context "when the document was marked as deleted" do

      let(:post) do
        ParanoidPost.new(:deleted_at => Time.now)
      end

      it "returns true" do
        post.should be_destroyed
      end
    end

    context "when the document was not marked as deleted" do

      let(:post) do
        ParanoidPost.new
      end

      it "returns false" do
        post.should_not be_destroyed
      end
    end
  end

  describe "#destroy" do

    let(:post) do
      ParanoidPost.new
    end

    let!(:time) do
      Time.now
    end

    before do
      post.expects(:collection).returns(collection)
      Time.stubs(:now).returns(time)
    end

    it "updates the document in the datadase" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$set" => { :deleted_at => time } }
      ).returns(true)
      post.destroy
    end

    it "sets the deleted flag" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$set" => { :deleted_at => time } }
      ).returns(true)
      post.destroy
      post.should be_destroyed
    end
  end

  describe "#remove" do

    let(:post) do
      ParanoidPost.new
    end

    let!(:time) do
      Time.now
    end

    before do
      post.expects(:collection).returns(collection)
      Time.stubs(:now).returns(time)
    end

    it "sets the deleted_at flag in the database" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$set" => { :deleted_at => time } }
      ).returns(true)
      post.remove
    end

    it "sets the deleted flag" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$set" => { :deleted_at => time } }
      ).returns(true)
      post.remove
      post.should be_destroyed
    end
  end

  describe "#restore" do

    let(:post) do
      ParanoidPost.new
    end

    let!(:time) do
      Time.now
    end

    before do
      post.expects(:collection).returns(collection)
      Time.stubs(:now).returns(time)
    end

    it "removes the deleted_at flag from the database" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$unset" => { :deleted_at => true } }
      ).returns(true)
      post.restore
    end

    it "removes the deleted flag" do
      collection.expects(:update).with(
        { :_id => post.id }, { "$unset" => { :deleted_at => true } }
      ).returns(true)
      post.restore
      post.should_not be_destroyed
    end
  end

  describe ".criteria" do

    context "when setting embedded to true" do

      let(:criteria) do
        ParanoidPost.criteria(true, true)
      end

      it "returns an embedded criteria" do
        criteria.embedded.should be_true
      end
    end

    context "when setting embedded to false" do

      let(:criteria) do
        ParanoidPost.criteria(false, true)
      end

      it "returns an root criteria" do
        criteria.embedded.should be_false
      end
    end

    context "when setting scoped to true" do

      let(:criteria) do
        ParanoidPost.criteria(false, true)
      end

      it "returns a scoped criteria" do
        criteria.selector.should eq({ :deleted_at => nil })
      end
    end

    context "when setting scoped to false" do

      let(:criteria) do
        ParanoidPost.criteria(false, false)
      end

      it "returns an scoped criteria" do
        criteria.selector.should eq({})
      end
    end
  end

  describe ".scoped" do

    let(:scoped) do
      ParanoidPost.scoped
    end

    it "returns a scoped criteria" do
      scoped.selector.should eq({ :deleted_at => nil })
    end
  end

  describe ".unscoped" do

    let(:unscoped) do
      ParanoidPost.unscoped
    end

    it "returns an unscoped criteria" do
      unscoped.selector.should eq({})
    end
  end
end
