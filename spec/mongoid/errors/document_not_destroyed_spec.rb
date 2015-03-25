require "spec_helper"

describe Mongoid::Errors::DocumentNotDestroyed do

  describe "#message" do

    let(:post) do
      Post.new
    end

    let(:error) do
      described_class.new(post.id, Post)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Post with id #{post.id.inspect} was not destroyed"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When calling Post#destroy! and a callback halts the destroy callback"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Check the before/after destroy callbacks to ensure"
      )
    end
  end
end
