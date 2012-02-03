require "spec_helper"

describe Mongoid::Relations::Builders do

  describe "#build_#\{name}" do

    let(:person) do
      Person.new
    end

    context "when providing no attributes" do

      context "when the relation is an embeds one" do

        let(:name) do
          person.build_name
        end

        it "does not set a binding attribute" do
          name[:binding].should be_nil
        end
      end

      context "when the relation is a references one" do

        let(:game) do
          person.build_game
        end

        it "does not set a binding attribute" do
          game[:binding].should be_nil
        end
      end

      context "when the relation is a belongs to" do

        context "when the inverse is a has many" do

          let(:post) do
            Post.new
          end

          let!(:person) do
            post.build_person
          end

          it "builds the document" do
            post.person.should eq(person)
          end

          it "sets the inverse" do
            person.posts.should eq([ post ])
          end

          it "does not save the document" do
            person.should_not be_persisted
          end
        end

        context "when the inverse is a has one" do

          let(:game) do
            Game.new
          end

          let!(:person) do
            game.build_person
          end

          it "builds the document" do
            game.person.should eq(person)
          end

          it "sets the inverse" do
            person.game.should eq(game)
          end

          it "does not save the document" do
            person.should_not be_persisted
          end
        end
      end
    end
  end

  describe "#create_#\{name}" do

    let(:person) do
      Person.new
    end

    context "when providing no attributes" do

      context "when the relation is an embeds one" do

        let(:name) do
          person.create_name
        end

        it "does not set a binding attribute" do
          name[:binding].should be_nil
        end
      end

      context "when the relation is a references one" do

        let(:game) do
          person.create_game
        end

        it "does not set a binding attribute" do
          game[:binding].should be_nil
        end
      end

      context "when the relation is a belongs to" do

        context "when the inverse is a has many" do

          let(:post) do
            Post.new
          end

          let!(:person) do
            post.create_person
          end

          it "builds the document" do
            post.person.should eq(person)
          end

          it "sets the inverse" do
            person.posts.should eq([ post ])
          end

          it "saves the document" do
            person.should be_persisted
          end

          it "saves the child" do
            post.should be_persisted
          end
        end

        context "when the inverse is a has one" do

          let(:game) do
            Game.new
          end

          let!(:person) do
            game.create_person
          end

          it "builds the document" do
            game.person.should eq(person)
          end

          it "sets the inverse" do
            person.game.should eq(game)
          end

          it "saves the document" do
            person.should be_persisted
          end

          it "saves the child" do
            game.should be_persisted
          end
        end
      end
    end

    context "when the parent is persisted" do

      let(:person) do
        Person.create
      end

      context "when the relation is a has one" do

        let!(:game_one) do
          person.create_game(name: "Starcraft")
        end

        context "when a document already exists" do

          let!(:game_two) do
            person.create_game(name: "Skyrim")
          end

          it "replaces the existing document" do
            person.game.should eq(game_two)
          end

          it "persists the change" do
            person.game(true).should eq(game_two)
          end

          it "removes the old document from the database" do
            Game.collection.find.count.should eq(1)
          end
        end
      end
    end
  end

  describe "#build" do

    context "with criteria applied" do

      let(:person) do
        Person.new
      end

      let(:services) do
        person.services.asc(:sid)
      end

      subject { services.build }

      it { should be_a_kind_of(Service) }
      it { should_not be_persisted }
    end
  end
end
