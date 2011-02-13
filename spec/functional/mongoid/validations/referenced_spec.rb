require "spec_helper"

describe Mongoid::Validations::ReferencedValidator do

  describe "#valid?" do

    let(:person) do
      Person.create
    end

    context "references many" do

      let(:post) do
        Post.new :title => '$$$'
      end

      before do
        person.posts << post
      end

      it "never loads the relation" do
        Post.expects(:find).never
        person.reload.valid?
      end

      it "should not be valid" do
        person.should_not be_valid
      end
    end

    context "references one" do

      let(:game) do
        Game.new(:name => '$$$')
      end

      before do
        person.game = game
      end

      it "never loads the relation" do
        Game.expects(:find).never
        person.reload.valid?
      end

      it "should not be valid" do
        person.should_not be_valid
      end
    end

    context "referenced in" do

      let(:post) do
        Post.create
      end

      let(:person) do
        Person.new(:ssn => '$$$')
      end

      before do
        post.person = person
      end

      it "never loads the relation" do
        Person.expects(:find).never
        post.reload.valid?
      end

      it "should not be valid" do
        person.should_not be_valid
        post.should_not be_valid
      end
    end

    context "references many to many" do

      let(:preference) do
        Preference.new(:name => '$')
      end

      before do
        person.preferences << preference
      end

      it "never loads the relation" do
        Preference.expects(:find).never
        person.reload.valid?
      end

      it "should not be valid" do
        person.should_not be_valid
      end
    end
  end
end
