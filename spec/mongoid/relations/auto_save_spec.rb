require "spec_helper"

describe Mongoid::Relations::AutoSave do

  describe ".auto_save" do

    before(:all) do
      Person.autosave(Person.relations["account"].merge!(autosave: true))
    end

    after(:all) do
      Person.reset_callbacks(:save)
    end

    let(:person) do
      Person.new
    end

    context "when the option is not provided" do

      let(:game) do
        Game.new(name: "Tekken")
      end

      before do
        person.game = game
      end

      context "when saving the parent document" do

        before do
          person.save
        end

        it "does not save the relation" do
          expect(game).to_not be_persisted
        end
      end
    end

    context "when the option is true" do

      context "when the relation has already had the autosave callback added" do

        let(:metadata) do
          Person.relations["drugs"].merge!(autosave: true)
        end

        before do
          Person.autosave(metadata)
          Person.autosave(metadata)
        end

        let(:drug) do
          Drug.new(name: "Percocet")
        end

        it "does not add the autosave callback twice" do
          expect(drug).to receive(:save).once
          person.drugs.push(drug)
          person.save
        end
      end

      context "when the relation is a references many" do

        let(:drug) do
          Drug.new(name: "Percocet")
        end

        context "when saving a new parent document" do

          before do
            person.drugs << drug
            person.save
          end

          it "saves the relation" do
            expect(drug).to be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save
            person.drugs << drug
            person.save
          end

          it "saves the relation" do
            expect(drug).to be_persisted
          end
        end

        context "when not updating the document" do

          let(:from_db) do
            Person.find person.id
          end

          before do
            person.drugs << drug
            person.save
          end

          it 'does not load the association' do
            from_db.save
            expect(from_db.ivar(:drugs)).to be false
          end
        end
      end

      context "when the relation is a references one" do

        let(:account) do
          Account.new(name: "Testing")
        end

        context "when saving a new parent document" do

          before do
            person.account = account
            person.save
          end

          it "saves the relation" do
            expect(account).to be_persisted
          end

          it "persists on the database" do
            expect(account.reload).to_not be_nil
          end
        end

        context "when saving an existing parent document" do

          before do
            person.save
            person.account = account
            person.save
          end

          it "saves the relation" do
            expect(account).to be_persisted
          end

          it "persists on the database" do
            expect(account.reload).to_not be_nil
          end
        end

        pending "when updating the child" do

          before do
            person.account = account
            person.save
          end

          it "sends one insert" do
            account.name = "account"
            expect_query(1) do
              person.with(write: {w:0}).save
            end
          end
        end

        context "when not updating the document" do

          let(:from_db) do
            Person.find person.id
          end

          before do
            person.account = account
            person.save
          end

          it 'does not load the association' do
            from_db.save
            expect(from_db.ivar(:account)).to be false
          end
        end
      end

      context "when the relation is a referenced in" do

        let(:ghost) do
          Ghost.new(name: "Slimer")
        end

        let(:movie) do
          Movie.new(title: "Ghostbusters")
        end

        context "when saving a new parent document" do

          before do
            ghost.movie = movie
            ghost.save
          end

          it "saves the relation" do
            expect(movie).to be_persisted
          end
        end

        context "when saving an existing parent document" do

          before do
            ghost.save
            ghost.movie = movie
            ghost.save
          end

          it "saves the relation" do
            expect(movie).to be_persisted
          end
        end
      end

      context "when it has two relations with autosaves" do

        before do
          Person.autosave(Person.relations["drugs"].merge!(autosave: true))
        end

        let!(:person) do
          Person.create(drugs: [percocet], account: account)
        end

        let(:from_db) do
          Person.find person.id
        end

        let(:percocet) do
          Drug.new(name: "Percocet")
        end

        let(:account) do
          Account.new(name: "Testing")
        end

        context "when updating one document" do

          let(:placebo) do
            Drug.new(name: "Placebo")
          end

          before do
            from_db.drugs = [placebo]
            from_db.save
          end

          it 'loads the updated association' do
            expect(from_db.ivar(:drugs)).to eq([placebo])
          end

          it 'doest not load the other association' do
            expect(from_db.ivar(:account)).to be false
          end
        end

        context "when updating none document" do

          before do
            from_db.save
          end

          it 'doest not load drugs association' do
            expect(from_db.ivar(:drugs)).to be false
          end

          it 'doest not load account association' do
            expect(from_db.ivar(:account)).to be false
          end
        end
      end
    end
  end
end
