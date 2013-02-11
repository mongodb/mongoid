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

  describe "#bind_one" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_metadata)
      end

      context "when the document is bindable with default pk" do

        before do
          person.should_receive(:save).never
          game.should_receive(:save).never
          binding.bind_one
        end

        it "sets the inverse relation" do
          person.game.should eq(game)
        end

        it "sets the foreign key" do
          game.person_id.should eq(person.id)
        end
      end

      context "when the document is bindable with username as pk" do

        before do
          Game.belongs_to :person, index: true, validate: true, primary_key: :username

          person.should_receive(:save).never
          game.should_receive(:save).never
          binding.bind_one
        end

        after do
          Game.belongs_to :person, index: true, validate: true
        end

        it "sets the inverse relation" do
          person.game.should eq(game)
        end

        let(:person) do
          Person.new(username: 'arthurnn')
        end

        it "sets the fk with username field" do
          game.person_id.should eq(person.username)
        end
      end

      context "when the document is not bindable" do

        before do
          person.game = game
        end

        it "does nothing" do
          game.should_receive(:person=).never
          binding.bind_one
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_metadata)
      end

      context "when the document is bindable" do

        before do
          person.should_receive(:save).never
          post.should_receive(:save).never
          binding.bind_one
        end

        it "sets the inverse relation" do
          person.posts.should include(post)
        end

        it "sets the foreign key" do
          post.person_id.should eq(person.id)
        end
      end

      context "when the document is not bindable" do

        before do
          person.posts = [ post ]
        end

        it "does nothing" do
          post.should_receive(:person=).never
          binding.bind_one
        end
      end
    end
  end

  describe "#unbind_one" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          person.should_receive(:delete).never
          game.should_receive(:delete).never
          binding.unbind_one
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
          game.should_receive(:person=).never
          binding.unbind_one
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_metadata)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          person.should_receive(:delete).never
          post.should_receive(:delete).never
          binding.unbind_one
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
          post.should_receive(:person=).never
          binding.unbind_one
        end
      end
    end
  end

  context "when binding frozen documents" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:game) do
        Game.new.freeze
      end

      before do
        game.person = person
      end

      it "does not set the foreign key" do
        game.person_id.should be_nil
      end
    end
  end

  context "when unbinding frozen documents" do

    let(:person) do
      Person.new
    end

    context "when the child is frozen" do

      let(:game) do
        Game.new
      end

      before do
        game.person = person
        game.freeze
        game.person = nil
      end

      it "does not unset the foreign key" do
        game.person_id.should eq(person.id)
      end
    end
  end
end
