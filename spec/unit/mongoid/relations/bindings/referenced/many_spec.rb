require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::Many do

  let(:person) do
    Person.new
  end

  let(:post) do
    Post.new
  end

  let(:target) do
    [ post ]
  end

  let(:metadata) do
    Person.relations["posts"]
  end

  describe "#bind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are bindable" do

      before do
        person.expects(:save).never
        post.expects(:save).never
        binding.bind(:continue => true)
      end

      it "sets the inverse relation" do
        post.person.should == person
      end

      it "sets the foreign key" do
        post.person_id.should == person.id
      end
    end

    context "when the documents are not bindable" do

      before do
        post.person = person
      end

      it "does nothing" do
        person.posts.expects(:<<).never
        binding.bind
      end
    end
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
        binding.bind_one(post_two, :continue => true)
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

  describe "#unbind" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind(:continue => true)
        person.expects(:delete).never
        post.expects(:delete).never
        binding.unbind(:continue => true)
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
        binding.unbind
      end
    end
  end

  describe "#unbind_one" do

    let(:binding) do
      described_class.new(person, target, metadata)
    end

    context "when the documents are unbindable" do

      before do
        binding.bind(:continue => true)
        person.expects(:delete).never
        post.expects(:delete).never
        binding.unbind_one(target.first, :continue => true)
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
