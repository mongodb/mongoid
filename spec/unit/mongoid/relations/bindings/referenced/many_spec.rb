require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::Many do

  let(:person) do
    Person.new
  end

  let(:post) do
    Post.new
  end

  let(:target) do
    Mongoid::Relations::Targets::Enumerable.new([ post ])
  end

  let(:metadata) do
    Person.relations["posts"]
  end

  describe "#bind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the document is bindable" do

      let(:post_two) do
        Post.new
      end

      before do
        binding.bind_one(post_two)
      end

      it "sets the inverse relation" do
        post_two.person.should == person
      end

      it "sets the foreign key" do
        post_two.person_id.should == person.id
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        person.posts.expects(:<<).never
        binding.bind_one(post)
      end
    end
  end

  describe "#unbind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind_one(target.first)
        person.expects(:delete).never
        post.expects(:delete).never
        binding.unbind_one(target.first)
      end

      it "removes the inverse relation" do
        post.person.should be_nil
      end

      it "removes the foreign keys" do
        post.person_id.should be_nil
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        person.expects(:posts=).never
        binding.unbind_one(target.first)
      end
    end
  end
end
