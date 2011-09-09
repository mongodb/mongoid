require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::Many do

  describe "#bind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:post) do
        Post.new.freeze
      end

      before do
        person.posts << post
      end

      it "does not set the foreign key" do
        post.person_id.should be_nil
      end
    end
  end

  describe "#unbind" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:post) do
        Post.new
      end

      before do
        person.posts << post
        post.freeze
        person.posts.delete(post)
      end

      it "does not unset the foreign key" do
        post.person_id.should eq(person.id)
      end
    end
  end
end
