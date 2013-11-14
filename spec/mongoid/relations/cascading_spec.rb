require "spec_helper"

describe Mongoid::Relations::Cascading do

  describe "#cascade!" do

    let(:band) do
      Band.new
    end

    context "when the metadata exists" do

      context "when the metadata has no cascade strategy" do

        before do
          band.cascades.push("records")
        end

        after do
          band.cascades.delete("records")
        end

        it "ignores the cascade" do
          expect(band.cascade!).to eq([ "records" ])
        end
      end
    end
  end

  describe ".cascade" do

    let(:klass) do
      Class.new.tap { |c| c.send(:include, Mongoid::Document) }
    end

    context "when the metadata doesnt exist" do

      before do
        klass.cascades.push("nothing")
      end

      it "does not raise an error" do
        expect {
          klass.new.cascade!
        }.not_to raise_error
      end
    end

    context "when a dependent option is provided" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          name: :posts,
          dependent: :destroy,
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      let!(:cascaded) do
        klass.cascade(metadata)
      end

      it "adds the action to the cascades" do
        expect(klass.cascades).to include("posts")
      end

      it "returns self" do
        expect(cascaded).to eq(klass)
      end
    end

    context "when no dependent option is provided" do

      let(:metadata) do
        Mongoid::Relations::Metadata.new(
          name: :posts,
          relation: Mongoid::Relations::Referenced::Many
        )
      end

      let!(:cascaded) do
        klass.cascade(metadata)
      end

      it "does not add an action to the cascades" do
        expect(klass.cascades).to_not include("posts")
      end

      it "returns self" do
        expect(cascaded).to eq(klass)
      end
    end
  end

  [ :delete, :destroy ].each do |method|

    describe "##{method}" do

      context "when cascading removals" do

        context "when dependent is delete" do

          let(:person) do
            Person.create
          end

          let!(:post) do
            person.posts.create(title: "Testing")
          end

          before do
            person.send(method)
          end

          it "deletes the associated documents" do
            expect {
              Post.find(post.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when dependent is destroy" do

          let(:person) do
            Person.create
          end

          let!(:game) do
            person.create_game(name: "Pong")
          end

          before do
            person.send(method)
          end

          it "destroys the associated documents" do
            expect {
              Game.find(game.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when dependent is nullify" do

          context "when nullifying a references many" do

            let(:movie) do
              Movie.create(title: "Bladerunner")
            end

            let!(:rating) do
              movie.ratings.create(value: 10)
            end

            let(:from_db) do
              Rating.find(rating.id)
            end

            before do
              movie.send(method)
            end

            it "removes the references to the removed document" do
              expect(from_db.ratable_id).to be_nil
            end
          end

          context "when nullifying a references one" do

            context "when the relation exists" do

              let(:book) do
                Book.create(title: "Neuromancer")
              end

              let!(:rating) do
                book.create_rating(value: 10)
              end

              let(:from_db) do
                Rating.find(rating.id)
              end

              before do
                book.send(method)
              end

              it "removes the references to the removed document" do
                expect(from_db.ratable_id).to be_nil
              end
            end

            context "when the relation is nil" do

              let(:book) do
                Book.create(title: "Neuromancer")
              end

              it "returns nil" do
                expect(book.send(method)).to be true
              end
            end
          end

          context "when nullifying a many to many" do

            let(:person) do
              Person.create
            end

            let!(:preference) do
              person.preferences.create(name: "Setting")
            end

            let(:from_db) do
              Preference.find(preference.id)
            end

            before do
              person.send(method)
            end

            it "removes the references from the removed document" do
              expect(person.preference_ids).to_not include(preference.id)
            end

            it "removes the references to the removed document" do
              expect(from_db.person_ids).to_not include(person.id)
            end
          end
        end

        context "when dependent is restrict" do

          context "when restricting a references many" do

            before do
              Person.has_many :drugs, dependent: :restrict
            end

            after do
              Person.cascades.delete("drugs")
              Person.has_many :drugs, validate: false
            end

            context "when the relation is empty" do

              let(:person) do
                Person.new drugs: []
              end

              it "raises no error" do
                expect{ person.send(method) }.to_not raise_error
              end

              it "deletes the parent" do
                person.send(method)
                expect(person).to be_destroyed
              end
            end

            context "when the relation is not empty" do

              let(:person) do
                Person.new drugs: [ Drug.new ]
              end

              it "raises DeleteRestriction error" do
                expect{ person.send(method) }.to raise_error(Mongoid::Errors::DeleteRestriction)
              end
            end
          end

          context "when restricting a references one" do

            before do
              Person.has_one :account, dependent: :restrict
            end

            after do
              Person.cascades.delete("account")
              Person.has_one :account, validate: false
            end

            context "when the relation is empty" do

              let(:person) do
                Person.new account: nil
              end

              it "raises no error" do
                expect{ person.send(method) }.to_not raise_error
              end

              it "deletes the parent" do
                person.send(method)
                expect(person).to be_destroyed
              end
            end

            context "when the relation is not empty" do

              let(:person) do
                Person.new account: Account.new(name: 'test')
              end

              it "raises DeleteRestriction error" do
                expect { person.send(method) }.to raise_error(Mongoid::Errors::DeleteRestriction)
              end
            end
          end

          context "when restricting a many to many" do

            before do
              Person.has_and_belongs_to_many :houses, dependent: :restrict
            end

            after do
              Person.cascades.delete("houses")
              Person.has_and_belongs_to_many :houses, validate: false
            end

            context "when the relation is empty" do

              let(:person) do
                Person.new houses: []
              end

              it "raises no error" do
                expect{ person.send(method) }.to_not raise_error
              end

              it "deletes the parent" do
                person.send(method)
                expect(person).to be_destroyed
              end
            end

            context "when the relation is not empty" do

              let(:person) do
                Person.new houses: [House.new]
              end

              it "raises DeleteRestriction error" do
                expect { person.send(method) }.to raise_error(Mongoid::Errors::DeleteRestriction)
              end
            end
          end
        end
      end
    end
  end
end
