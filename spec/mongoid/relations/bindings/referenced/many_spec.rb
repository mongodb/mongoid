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
        expect(post_two.person).to eq(person)
      end

      it "sets the foreign key" do
        expect(post_two.person_id).to eq(person.id)
      end
    end

    context "when the document is not bindable" do

      it "does nothing" do
        expect(person.posts).to receive(:<<).never
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
        expect(person).to receive(:delete).never
        expect(post).to receive(:delete).never
        binding.unbind_one(target.first)
      end

      it "removes the inverse relation" do
        expect(post.person).to be_nil
      end

      it "removes the foreign keys" do
        expect(post.person_id).to be_nil
      end
    end

    context "when the documents are not unbindable" do

      it "does nothing" do
        expect(person).to receive(:posts=).never
        binding.unbind_one(target.first)
      end
    end
  end

  context "when binding frozen documents" do

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
        expect(post.person_id).to be_nil
      end
    end
  end

  context "when unbinding frozen documents" do

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
        expect(post.person_id).to eq(person.id)
      end
    end
  end

  context "when the inverse relation can not be determined" do

    let(:person) do
      Person.new
    end

    let(:band) do
      Band.new
    end

    context "when adding the document" do

      it "raises an error" do
        expect {
          person.posts << band
        }.to raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end
end
