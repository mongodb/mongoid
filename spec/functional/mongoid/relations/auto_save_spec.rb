require "spec_helper"

describe Mongoid::Relations::AutoSave do

  before do
    [ Person, Game, Account, Drug ].each(&:delete_all)
  end

  describe ".auto_save" do

    let(:person) do
      Person.new(:ssn => "222-22-2222")
    end

    context "when the option is not provided" do

      let(:game) do
        Game.new(:name => "Tekken")
      end

      before do
        person.game = game
      end

      context "when saving the parent document" do

        before do
          person.save
        end

        it "does not save the relation" do
          game.should_not be_persisted
        end
      end
    end

    context "when the option is true" do

      context "when the relation is a references many" do

        let(:drug) do
          Drug.new(:name => "Percocet")
        end

        context "when saving a new parent document" do

          before do
            person.drugs << drug
            person.save
          end

          it "saves the relation" do
            drug.should be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save
            person.drugs.build(:name => "Percocet")
            person.save
          end

          it "does not save the relation" do
            drug.should_not be_persisted
          end
        end
      end

      context "when the relation is a references one" do

        let(:account) do
          Account.new(:name => "Testing")
        end

        context "when saving a new parent document" do

          before do
            person.account = account
            person.save
          end

          it "saves the relation" do
            account.should be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save
            person.build_account(:name => "Test")
            person.save
          end

          it "does not save the relation" do
            account.should_not be_persisted
          end
        end
      end

      context "when the relation is a referenced in" do

        before do
          [ Ghost, Movie ].each(&:delete_all)
        end

        let(:ghost) do
          Ghost.new(:name => "Slimer")
        end

        let(:movie) do
          Movie.new(:title => "Ghostbusters")
        end

        context "when saving a new parent document" do

          before do
            ghost.movie = movie
            ghost.save
          end

          it "saves the relation" do
            movie.should be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            ghost.save
            ghost.movie = movie
            ghost.save
          end

          it "saves the relation" do
            movie.should be_persisted
          end
        end
      end
    end
  end
end
