# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::BelongsTo::Binding do

  let(:person) do
    Person.new
  end

  let(:game) do
    Game.new
  end

  let(:post) do
    Post.new
  end

  let(:game_association) do
    Game.relations["person"]
  end

  let(:post_association) do
    Post.relations["person"]
  end

  describe "#bind_one" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_association)
      end

      context "when the document is bindable with default pk" do

        before do
          expect(person).to receive(:save).never
          expect(game).to receive(:save).never
          binding.bind_one
        end

        it "sets the inverse relation" do
          expect(person.game).to eq(game)
        end

        it "sets the foreign key" do
          expect(game.person_id).to eq(person.id)
        end
      end

      context "when the document is bindable with username as pk" do

        before do
          Game.belongs_to :person, index: true, validate: true, primary_key: :username

          expect(person).to receive(:save).never
          expect(game).to receive(:save).never
          binding.bind_one
        end

        after do
          Game.belongs_to :person, index: true, validate: true
        end

        it "sets the inverse relation" do
          expect(person.game).to eq(game)
        end

        let(:person) do
          Person.new(username: 'arthurnn')
        end

        it "sets the fk with username field" do
          expect(game.person_id).to eq(person.username)
        end
      end

      context "when the document is not bindable" do

        before do
          person.game = game
        end

        it "does nothing" do
          expect(game).to receive(:person=).with(person).never
          expect(game).to receive(:person=).with(nil).once
          binding.bind_one
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_association)
      end

      context "when the document is bindable" do

        before do
          expect(person).to receive(:save).never
          expect(post).to receive(:save).never
          binding.bind_one
        end

        it "sets the inverse relation" do
          expect(person.posts).to include(post)
        end

        it "sets the foreign key" do
          expect(post.person_id).to eq(person.id)
        end
      end

      context "when the document is not bindable" do

        before do
          person.posts = [ post ]
        end

        it "does nothing" do
          expect(post).to receive(:person=).never
          binding.bind_one
        end
      end
    end
  end

  describe "#unbind_one" do

    context "when the child of an references one" do

      let(:binding) do
        described_class.new(game, person, game_association)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          expect(person).to receive(:delete).never
          expect(game).to receive(:delete).never
          binding.unbind_one
        end

        it "removes the inverse relation" do
          expect(person.game).to be_nil
        end

        it "removed the foreign key" do
          expect(game.person_id).to be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          expect(game).to receive(:person=).never
          binding.unbind_one
        end
      end
    end

    context "when the child of an references many" do

      let(:binding) do
        described_class.new(post, person, post_association)
      end

      context "when the document is unbindable" do

        before do
          binding.bind_one
          expect(person).to receive(:delete).never
          expect(post).to receive(:delete).never
          binding.unbind_one
        end

        it "removes the inverse relation" do
          expect(person.posts).to be_empty
        end

        it "removes the foreign key" do
          expect(post.person_id).to be_nil
        end
      end

      context "when the document is not unbindable" do

        it "does nothing" do
          expect(post).to receive(:person=).never
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
        expect(game.person_id).to be_nil
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
        expect(game.person_id).to eq(person.id)
      end
    end
  end
end
