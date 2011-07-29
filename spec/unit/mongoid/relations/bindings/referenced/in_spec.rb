require "spec_helper"

describe Mongoid::Relations::Bindings::Referenced::In do

  let(:person) do
    Person.new
  end

  let(:game) do
    Game.new
  end

  let(:post) do
    Post.new
  end

  let(:game_metadata) do
    Game.relations["person"]
  end

  let(:post_metadata) do
    Post.relations["person"]
  end

  describe "#bind" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_metadata)
      end

      context "when the document is bindable" do

        before do
          person.expects(:save).never
          game.expects(:save).never
          binding.bind
        end

        it "sets the inverse relation" do
          person.game.should == game
        end

        it "sets the foreign key" do
          game.person_id.should == person.id
        end
      end

      context "when the document is not bindable" do

        before do
          person.game = game
        end

        it "does nothing" do
          game.expects(:person=).never
          binding.bind
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_metadata)
      end

      context "when the document is bindable" do

        before do
          person.expects(:save).never
          post.expects(:save).never
          binding.bind
        end

        it "sets the inverse relation" do
          person.posts.should include(post)
        end

        it "sets the foreign key" do
          post.person_id.should == person.id
        end
      end

      context "when the document is not bindable" do

        before do
          person.posts = [ post ]
        end

        it "does nothing" do
          post.expects(:person=).never
          binding.bind
        end
      end
    end
  end

  describe "#unbind" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          person.expects(:delete).never
          game.expects(:delete).never
          binding.unbind
        end

        it "removes the inverse relation" do
          person.game.should be_nil
        end

        it "removed the foreign key" do
          game.person_id.should be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          game.expects(:person=).never
          binding.unbind
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind
          person.expects(:delete).never
          post.expects(:delete).never
          binding.unbind
        end

        it "removes the inverse relation" do
          person.posts.should be_empty
        end

        it "removes the foreign key" do
          post.person_id.should be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          post.expects(:person=).never
          binding.unbind
        end
      end
    end
  end
end
