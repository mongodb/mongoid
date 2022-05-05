# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Accessors do

  describe "\#{getter}?" do

    let(:person) do
      Person.create!
    end

    context "when the association is a has one" do

      context "when the association exists" do

        let!(:game) do
          person.build_game
        end

        it "returns true" do
          expect(person).to have_game
        end
      end

      context "when the association does not exist" do

        context "when not autobuilding" do

          it "returns false" do
            expect(person).to_not have_game
          end
        end

        context "when autobuilding" do

          it "returns false" do
            expect(person).to_not have_book
          end
        end
      end
    end

    context "when the association is a has many" do

      context "when the association has documents" do

        let!(:post) do
          person.posts.build
        end

        it "returns true" do
          expect(person).to have_posts
        end
      end

      context "when the association does not have documents" do

        it "returns false" do
          expect(person).to_not have_posts
        end
      end
    end

    context "when the association is a has and belongs to many" do

      context "when the association has documents" do

        let!(:preference) do
          person.preferences.build
        end

        it "returns true" do
          expect(person).to have_preferences
        end
      end

      context "when the association does not have documents" do

        it "returns false" do
          expect(person).to_not have_preferences
        end
      end
    end

    context "when the association is a belongs to" do

      context "when the association is named next" do

        let(:user) do
          User.create!
        end

        it "allows the existence check" do
          expect(user).to_not have_next
        end
      end

      context "when the association exists" do

        let!(:game) do
          person.build_game
        end

        it "returns true" do
          expect(game).to have_person
        end
      end

      context "when the association does not exist" do

        context "when the association does not autobuild" do

          let(:game) do
            Game.new
          end

          it "returns false" do
            expect(game).to_not have_person
          end
        end

        context "when the association autobuilds" do

          let(:book) do
            Book.new
          end

          it "returns false" do
            expect(book).to_not have_person
          end
        end
      end
    end

    context "when the association is an embeds one" do

      context "when the association exists" do

        let!(:name) do
          person.build_name
        end

        it "returns true" do
          expect(person).to have_name
        end
      end

      context "when the association does not exist" do

        context "when the association does not autobuild" do

          it "returns false" do
            expect(person).to_not have_name
          end
        end

        context "when the association autobuilds" do

          let(:person) do
            Person.new
          end

          it "returns false" do
            expect(person).to_not have_passport
          end
        end
      end

      context "when the association is set to nil first" do
        context "when broken_updates feature flag is not set" do
          config_override :broken_updates, false

          let!(:name) do
            person.build_name
          end

          it "returns true" do
            person.name = nil
            person.name = name
            expect(person).to have_name
          end
        end

        context "when broken_updates feature flag is set" do
          config_override :broken_updates, true

          let!(:name) do
            person.build_name
          end

          it "returns true" do
            person.name = nil
            person.name = name
            expect(person).to have_name
          end
        end
      end
    end

    context "when the association is an embeds many" do

      context "when the association has documents" do

        let!(:address) do
          person.addresses.build
        end

        it "returns true" do
          expect(person).to have_addresses
        end
      end

      context "when the association does not have documents" do

        it "returns false" do
          expect(person).to_not have_addresses
        end
      end
    end

    context "when the association is an embedded in" do

      context "when the association exists" do

        let!(:name) do
          person.build_name
        end

        it "returns true" do
          expect(name).to have_namable
        end
      end

      context "when the association does not exist" do

        context "when the association does not autobuild" do

          let(:name) do
            Name.new
          end

          it "returns false" do
            expect(name).to_not have_namable
          end
        end

        context "when the association autobuilds" do

          let(:passport) do
            Passport.new
          end

          it "returns false" do
            expect(passport).to_not have_person
          end
        end
      end
    end
  end

  describe "\#{getter}" do

    let(:person) do
      Person.new
    end

    context "when autobuilding the association" do

      context "when the association is an embeds one" do

        context "when the association does not exist" do

          let!(:passport) do
            person.passport
          end

          it "builds the new document" do
            expect(passport).to be_a(Passport)
          end

          it "stores in the altered attribute" do
            expect(person.as_document["pass"]).to eq(passport.attributes)
          end
        end

        context "when the association exists" do

          let!(:passport) do
            person.build_passport(number: "123123321")
          end

          it "does not build a new document" do
            expect(person.passport).to eq(passport)
          end

        end
      end

      context "when the association is an embedded in" do

        let(:passport) do
          Passport.new
        end

        context "when the association does not exist" do

          let(:person) do
            passport.person
          end

          it "builds the new document" do
            expect(person).to be_a(Person)
          end
        end

        context "when the association exists" do

          let!(:person) do
            passport.build_person(title: "sir")
          end

          it "does not build a new document" do
            expect(passport.person).to eq(person)
          end
        end
      end

      context "when the association is a has one" do

        context "when the association does not exist" do

          let(:book) do
            person.book
          end

          it "builds the new document" do
            expect(book).to be_a(Book)
          end
        end

        context "when the association exists" do

          let!(:book) do
            person.build_book(title: "art of war")
          end

          it "does not build a new document" do
            expect(person.book).to eq(book)
          end
        end
      end

      context "when the association is a belongs to" do

        let(:book) do
          Book.new
        end

        context "when the association does not exist" do

          let(:person) do
            book.person
          end

          it "builds the new document" do
            expect(person).to be_a(Person)
          end
        end

        context "when the association exists" do

          let!(:person) do
            book.build_person(title: "sir")
          end

          it "does not build a new document" do
            expect(book.person).to eq(person)
          end
        end
      end
    end

    context "when the association is not polymorphic" do

      let(:person) do
        Person.create!
      end

      context "when the association is a many to many" do

        let!(:preference) do
          Preference.create!(name: "Setting")
        end

        before do
          person.preferences << Preference.last
        end

        context "when reloading the association directly" do

          let(:preferences) do
            person.preferences(true)
          end

          it "reloads the correct documents" do
            expect(preferences).to eq([ preference ])
          end

          it "reloads a new instance" do
            expect(preferences.first).to_not equal(preference)
          end
        end

        context "when reloading via the base document" do

          let(:preferences) do
            person.reload.preferences
          end

          it "reloads the correct documents" do
            expect(preferences).to eq([ preference ])
          end

          it "reloads a new instance" do
            expect(preferences.first).to_not equal(preference)
          end
        end

        context "when performing a fresh find on the base" do

          let(:preferences) do
            Person.find(person.id).preferences
          end

          it "reloads the correct documents" do
            expect(preferences).to eq([ preference ])
          end
        end
      end

      context "when the association is a many to one" do

        let!(:post) do
          Post.create!(title: "First!")
        end

        before do
          person.posts << Post.last
        end

        context "when reloading the association directly" do

          let(:posts) do
            person.posts(true)
          end

          it "reloads the correct documents" do
            expect(posts).to eq([ post ])
          end

          it "reloads a new instance" do
            expect(posts.first).to_not equal(post)
          end
        end

        context "when reloading via the base document" do

          let(:posts) do
            person.reload.posts
          end

          it "reloads the correct documents" do
            expect(posts).to eq([ post ])
          end

          it "reloads a new instance" do
            expect(posts.first).to_not equal(post)
          end
        end

        context "when performing a fresh find on the base" do

          let(:posts) do
            Person.find(person.id).posts
          end

          it "reloads the correct documents" do
            expect(posts).to eq([ post ])
          end
        end
      end

      context "when the association is a references one" do

        let!(:game) do
          Game.create!(name: "Centipeded")
        end

        before do
          person.game = Game.last
        end

        context "when reloading the association directly" do

          let(:reloaded_game) do
            person.game(true)
          end

          it "reloads the correct documents" do
            expect(reloaded_game).to eq(game)
          end

          it "reloads a new instance" do
            expect(reloaded_game).to_not equal(game)
          end
        end

        context "when reloading via the base document" do

          let(:reloaded_game) do
            person.reload.game
          end

          it "reloads the correct documents" do
            expect(reloaded_game).to eq(game)
          end

          it "reloads a new instance" do
            expect(reloaded_game).to_not equal(game)
          end
        end

        context "when performing a fresh find on the base" do

          let(:reloaded_game) do
            Person.find(person.id).game
          end

          it "reloads the correct documents" do
            expect(reloaded_game).to eq(game)
          end
        end
      end
    end

    context "when the association is polymorphic" do

      context "when there's a single references many/one" do

        let!(:movie) do
          Movie.create!(title: "Inception")
        end

        let!(:book) do
          Book.create!(title: "Jurassic Park")
        end

        let!(:movie_rating) do
          movie.ratings.create!(value: 10)
        end

        let!(:book_rating) do
          book.create_rating(value: 5)
        end

        context "when accessing a referenced in" do

          let!(:rating) do
            Rating.where(value: 10).first
          end

          it "returns the correct document" do
            expect(rating.ratable).to eq(movie)
          end
        end

        context "when accessing a references many" do

          let(:ratings) do
            Movie.first.ratings
          end

          it "returns the correct documents" do
            expect(ratings).to eq([ movie_rating ])
          end
        end

        context "when accessing a references one" do

          let!(:rating) do
            Book.find(book.id).rating
          end

          it "returns the correct document" do
            expect(rating).to eq(book_rating)
          end
        end
      end
    end

    context 'when projecting' do
      context 'embeds_one' do

        let!(:person) do
          Person.create!(passport: Passport.new(number: "123123321", country: "USA"))
        end

        context "when the record is queried with the embedded association projected" do
          let(:persisted_person) { Person.only(:passport).first }

          it 'creates an accessor for the projected embedded document' do
            expect(persisted_person.passport.number).to eq("123123321")
            expect(persisted_person.passport.country).to eq("USA")
          end
        end

        context 'when the record is queried with a field on the embedded association projected' do
          let(:persisted_person) { Person.only("pass.number").first }

          it 'creates an accessor for the projected field on the embedded document' do
            expect(persisted_person.passport.number).to eq("123123321")
          end

          it 'does not create an accessor for another field on the embedded document' do
            expect do
              persisted_person.passport.country
            end.to raise_error(ActiveModel::MissingAttributeError)
          end
        end

        context 'when projecting association and a field in association' do
          shared_examples 'is prohibited on 4.4+ server' do
            context '4.4 server and higher' do
              min_server_version '4.4'

              it 'is not allowed by server' do
                lambda do
                  persisted_person
                end.should raise_error(Mongo::Error::OperationFailure, /Path collision at pass/)
              end
            end
          end

          context 'association then field' do
            let(:persisted_person) { Person.only(:pass, "pass.number").first }

            context '4.2 server and lower' do
              max_server_version '4.2'

              it 'creates an accessor for the projected field on the embedded document' do
                expect(persisted_person.passport.number).to eq("123123321")
              end

              it 'does not create an accessor for another field on the embedded document' do
                expect do
                  persisted_person.passport.country
                end.to raise_error(ActiveModel::MissingAttributeError)
              end
            end

            include_examples 'is prohibited on 4.4+ server'
          end

          context 'field then association' do
            let(:persisted_person) { Person.only('pass.number', :pass).first }

            context '4.2 server and lower' do
              max_server_version '4.2'

              it 'creates an accessor for the projected field on the embedded document' do
                expect(persisted_person.passport.number).to eq("123123321")
              end

              it 'retrieves other fields' do
                persisted_person.passport.country.should == 'USA'
              end
            end

            include_examples 'is prohibited on 4.4+ server'
          end
        end
      end

      context 'embeds_many' do

        let!(:person) do
          Person.create!(phone_numbers: [
            Phone.new(number: '111-111-1111', landline: true),
          ])
        end

        context 'when the record is queried with the embedded association projected' do
          let(:persisted_person) { Person.only(:phone_numbers).first }

          it 'creates an accessor for the embedded document' do
            expect(persisted_person.phone_numbers.first.number).to eq('111-111-1111')
            expect(persisted_person.phone_numbers.first.landline).to be true
          end
        end

        shared_examples 'allows access to field of projected association' do
          it 'creates an accessor for the embedded document' do
            expect(persisted_person.phone_numbers.first).to be_a_kind_of(Phone)
          end

          it 'creates an accessor for the projected field on the embedded document' do
            expect(persisted_person.phone_numbers.first.number).to eq('111-111-1111')
          end
        end

        context 'when the record is queried with a field on the embedded association projected' do
          let(:persisted_person) { Person.only("phone_numbers.number").first }

          include_examples 'allows access to field of projected association'

          it 'does not create an accessor for another field on the embedded document' do
            expect do
              persisted_person.phone_numbers.first.landline
            end.to raise_error(ActiveModel::MissingAttributeError)
          end
        end

        context 'when projecting association and a field in association' do

          shared_examples 'is prohibited on 4.4+ server' do
            context '4.4 server and higher' do
              min_server_version '4.4'

              it 'is not allowed by server' do
                lambda do
                  persisted_person
                end.should raise_error(Mongo::Error::OperationFailure, /Path collision at phone_numbers/)
              end
            end
          end

          context 'association then field' do
            let(:persisted_person) { Person.only(:phone_numbers, 'phone_numbers.number').first }

            context '4.2 server and lower' do
              max_server_version '4.2'

              include_examples 'allows access to field of projected association'

              it 'does not create an accessor for another field on the embedded document' do
                expect do
                  persisted_person.phone_numbers.first.landline
                end.to raise_error(ActiveModel::MissingAttributeError)
              end

            end

            include_examples 'is prohibited on 4.4+ server'
          end

          context 'field then association' do
            let(:persisted_person) { Person.only('phone_numbers.number', :phone_numbers).first }

            context '4.2 server and lower' do
              max_server_version '4.2'

              include_examples 'allows access to field of projected association'

              it 'retrieves all fields of association' do
                persisted_person.phone_numbers.first.landline.should be true
              end
            end

            include_examples 'is prohibited on 4.4+ server'
          end
        end
      end
    end
  end

  context "when setting associations to empty values" do

    context "when the document is a referenced in" do

      let(:post) do
        Post.new
      end

      context "when setting the association directly" do

        before do
          post.person = ""
        end

        it "converts them to nil" do
          expect(post.person).to be_nil
        end
      end

      context "when setting the foreign key" do

        before do
          post.person_id = ""
        end

        it "converts it to nil" do
          expect(post.person_id).to be_nil
        end
      end
    end

    context "when the document is a references one" do

      let(:person) do
        Person.new
      end

      context "when setting the association directly" do

        before do
          person.game = ""
        end

        it "converts them to nil" do
          expect(person.game).to be_nil
        end
      end

      context "when setting the foreign key" do

        let(:game) do
          Game.new
        end

        before do
          game.person_id = ""
        end

        it "converts it to nil" do
          expect(game.person_id).to be_nil
        end
      end
    end

    context "when the document is a references many" do

      let(:person) do
        Person.new
      end

      context "when setting the foreign key" do

        let(:post) do
          Post.new
        end

        before do
          post.person_id = ""
        end

        it "converts it to nil" do
          expect(post.person).to be_nil
        end
      end

      context "when setting the _ids accessor" do

        let(:post) do
          Post.create!
        end

        before do
          person.post_ids = [ "" ]
        end

        it "ignore blank values" do
          expect(person.post_ids).to be_empty
        end
      end
    end

    context "when the document is a references many to many" do

      let(:person) do
        Person.new
      end

      context "when setting the foreign key" do

        before do
          person.preference_ids = [ "", "" ]
        end

        it "does not add them" do
          expect(person.preference_ids).to be_empty
        end
      end
    end
  end

  context 'when setting associations to nil values' do
    context 'when the document embeds one' do
      let(:definitions) do
        class AccessorEmbedding
          include Mongoid::Document

          embeds_one :accessor_embedded
        end

        class AccessorEmbedded
          include Mongoid::Document

          embedded_in :accessor_embedding
        end

        define_embedded
      end

      let(:embedding) do
        AccessorEmbedding.create!
      end

      let(:define_embedded) do
        AccessorEmbedded.create!(accessor_embedding: embedding)
      end

      it 'successfully removes the embedded document' do
        definitions

        expect(embedding.accessor_embedded).not_to be_nil

        embedding.accessor_embedded = nil
        embedding.save!

        expect(embedding.reload.accessor_embedded).to be_nil
      end
    end
  end

  context "when setting association foreign keys" do

    let(:game) do
      Game.new
    end

    let(:person) do
      Person.create!
    end

    context "when value is an empty string" do

      before do
        game.person_id = ""
        game.save!
      end

      it "sets the foreign key to empty" do
        expect(game.reload.person_id).to be_blank
      end
    end

    context "when value is a populated string" do

      before do
        game.person_id = person.id.to_s
        game.save!
      end

      it "sets the foreign key as ObjectID" do
        expect(game.reload.person_id).to eq(person.id)
      end
    end

    context "when value is a ObjectID" do

      before do
        game.person_id = person.id
        game.save!
      end

      it "keeps the foreign key as ObjectID" do
        expect(game.reload.person_id).to eq(person.id)
      end
    end

    context "when setting ids multiple times on the association itself" do

      before do
        game.person = person.id
        game.person = person.id
      end

      it "sets the association foreign key" do
        expect(game.person_id).to eq(person.id)
      end

      it "sets the appropriate association" do
        expect(game.person).to eq(person)
      end
    end
  end

  context 'when setting the association more than once' do

    let(:person) do
      Person.create!
    end

    context 'when the association is a references one' do

      let(:game) do
        Game.create!
      end

      before do
        person.game = game
        game.person = person
      end

      it 'allows the object to be set twice' do
        expect(person.game = game).to be(game)
      end
    end

    context 'when the association is a references many' do

      let!(:preference) do
        Preference.create!(name: "Setting")
      end

      before do
        person.preferences << Preference.last
      end

      it 'allows the object to be set twice' do
        expect(person.preferences << Preference.last).to be_a(Array)
      end
    end

    context 'when the association is an embeds one' do

      let!(:name) do
        Name.new
      end

      before do
        person.name = name
        name.person = person
      end

      it 'allows the object to be set twice' do
        expect(person.name = name).to be(name)
      end
    end

    context 'when the association is an embeds many' do

      let!(:address) do
        Address.new
      end

      before do
        person.addresses << address
      end

      it 'allows the object to be set twice' do
        expect(person.addresses << address).to be_a(Array)
      end
    end
  end
end
