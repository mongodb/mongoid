# frozen_string_literal: true

require 'spec_helper'

module RefHasManySpec
  module OverrideInitialize
    class Parent
      include Mongoid::Document
      has_many :children, inverse_of: :parent
    end

    class Child
      include Mongoid::Document
      belongs_to :parent
      field :name, type: String

      def initialize(*args)
        super
        self.name ||= 'default'
      end
    end
  end
end

describe Mongoid::Association::Referenced::HasMany::Proxy do
  config_override :raise_not_found_error, true

  before :all do
    Drug.belongs_to :person, primary_key: :username
    Person.has_many :drugs, validate: false, primary_key: :username
  end

  after :all do
    Drug.belongs_to :person, counter_cache: true
    Person.has_many :drugs, validate: false
  end

  %i[ << push ].each do |method|
    describe "##{method}" do
      context 'when providing the base class in child constructor' do
        let(:person) { Person.create! }

        before { person.posts.send(method, Post.new(person: person)) }

        it 'only adds the association once' do
          expect(person.posts.size).to eq(1)
        end

        it 'only persists the association once' do
          expect(person.reload.posts.size).to eq(1)
        end
      end

      context 'when the associations are not polymorphic' do
        context 'when the parent is a new record' do
          let(:person) { Person.new }

          context 'when the child is new' do
            let(:post) { Post.new }
            let!(:added) { person.posts.send(method, post) }

            it 'sets the foreign key on the association' do
              expect(post.person_id).to eq(person.id)
            end

            it 'sets the base on the inverse association' do
              expect(post.person).to eq(person)
            end

            it 'sets the same instance on the inverse association' do
              expect(post.person).to eql(person)
            end

            it 'does not save the target' do
              expect(post).to be_new_record
            end

            it 'adds the document to the target' do
              expect(person.posts.size).to eq(1)
            end

            it 'returns the association' do
              expect(added).to eq(person.posts)
            end
          end

          context 'when the child is persisted' do
            let(:post) { Post.create! }

            before do
              person.posts.send(method, post)
            end

            it 'sets the foreign key on the association' do
              expect(post.person_id).to eq(person.id)
            end

            it 'sets the base on the inverse association' do
              expect(post.person).to eq(person)
            end

            it 'sets the same instance on the inverse association' do
              expect(post.person).to eql(person)
            end

            it 'does not save the parent' do
              expect(person).to be_new_record
            end

            it 'adds the document to the target' do
              expect(person.posts.size).to eq(1)
            end

            context 'when subsequently saving the parent' do
              before do
                person.save!
                post.save!
              end

              it 'returns the correct count of the association' do
                expect(person.posts.count).to eq(1)
              end
            end
          end
        end

        context 'when appending in a parent create block' do
          let!(:post) { Post.create!(title: 'testing') }
          let!(:person) do
            Person.create! do |doc|
              doc.posts << post
            end
          end

          it 'adds the documents to the association' do
            expect(person.posts).to eq([ post ])
          end

          it 'sets the foreign key on the inverse association' do
            expect(post.person_id).to eq(person.id)
          end

          it 'saves the target' do
            expect(post).to be_persisted
          end

          it 'adds the correct number of documents' do
            expect(person.posts.size).to eq(1)
          end

          it 'persists the link' do
            expect(person.reload.posts).to eq([ post ])
          end
        end

        context 'when the parent is not a new record' do
          let(:person) { Person.create! }
          let(:post) { Post.new }

          before do
            person.posts.send(method, post)
          end

          it 'sets the foreign key on the association' do
            expect(post.person_id).to eq(person.id)
          end

          it 'sets the base on the inverse association' do
            expect(post.person).to eq(person)
          end

          it 'sets the same instance on the inverse association' do
            expect(post.person).to eql(person)
          end

          it 'saves the target' do
            expect(post).to be_persisted
          end

          it 'adds the document to the target' do
            expect(person.posts.count).to eq(1)
          end

          it 'increments the counter cache' do
            expect(person[:posts_count]).to eq(1)
            expect(person.posts_count).to eq(1)
          end

          it 'doesnt change the list of changes' do
            expect(person.changed).to eq([])
          end

          context 'when the related item has embedded associations' do
            let!(:user) { User.create! }

            before do
              p = Post.create!(roles: [ Role.create! ])
              user.posts = [ p ]
              user.save!
            end

            it 'add the document to the target' do
              expect(user.posts.size).to eq(1)
              expect(user.posts.first.roles.size).to eq(1)
            end
          end

          context 'when saving another post' do
            before do
              person.posts.send(method, Post.new)
            end

            it 'increments the counter cache' do
              expect(person.posts_count).to eq(2)
            end
          end

          context 'when documents already exist on the association' do
            let(:post_two) { Post.new(title: 'Test') }

            before do
              person.posts.send(method, post_two)
            end

            it 'sets the foreign key on the association' do
              expect(post_two.person_id).to eq(person.id)
            end

            it 'sets the base on the inverse association' do
              expect(post_two.person).to eq(person)
            end

            it 'sets the same instance on the inverse association' do
              expect(post_two.person).to eql(person)
            end

            it 'saves the target' do
              expect(post_two).to be_persisted
            end

            it 'adds the document to the target' do
              expect(person.posts.count).to eq(2)
            end

            it 'increments the counter cache' do
              expect(person.reload.posts_count).to eq(2)
            end

            it 'contains the initial document in the target' do
              expect(person.posts).to include(post)
            end

            it 'contains the added document in the target' do
              expect(person.posts).to include(post_two)
            end
          end
        end
      end

      context 'when.adding to the association' do
        let(:person) { Person.create! }

        context 'when the operation succeeds' do
          let(:post) { Post.new }

          before do
            person.posts.send(method, post)
          end

          it 'adds the document to the association' do
            expect(person.posts).to eq([ post ])
          end
        end

        context 'when the operation fails' do
          let!(:existing) { Post.create! }
          let(:post) { Post.new { |doc| doc._id = existing.id } }

          it 'raises an error' do
            expect { person.posts.send(method, post) }
              .to raise_error(Mongo::Error::OperationFailure)
          end
        end
      end

      context 'when the associations are polymorphic' do
        context 'when the parent is a new record' do
          let(:movie) { Movie.new }
          let(:rating) { Rating.new }

          before do
            movie.ratings.send(method, rating)
          end

          it 'sets the foreign key on the association' do
            expect(rating.ratable_id).to eq(movie.id)
          end

          it 'sets the base on the inverse association' do
            expect(rating.ratable).to eq(movie)
          end

          it 'does not save the target' do
            expect(rating).to be_new_record
          end

          it 'adds the document to the target' do
            expect(movie.ratings.size).to eq(1)
          end
        end

        context 'when the parent is not a new record' do
          let(:movie) { Movie.create! }
          let(:rating) { Rating.new }

          before do
            movie.ratings.send(method, rating)
          end

          it 'sets the foreign key on the association' do
            expect(rating.ratable_id).to eq(movie.id)
          end

          it 'sets the base on the inverse association' do
            expect(rating.ratable).to eq(movie)
          end

          it 'saves the target' do
            expect(rating).to be_persisted
          end

          it 'adds the document to the target' do
            expect(movie.ratings.count).to eq(1)
          end
        end
      end
    end
  end

  describe '#=' do
    context 'when the association is not polymorphic' do
      context 'when the parent is a new record' do
        let(:person) { Person.new }
        let(:post) { Post.new }

        before do
          person.posts = [ post ]
        end

        it 'sets the target of the association' do
          expect(person.posts._target).to eq([ post ])
        end

        it 'sets the foreign key on the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'does not save the target' do
          expect(post).not_to be_persisted
        end
      end

      context 'when the parent is not a new record' do
        let(:person) { Person.create! }
        let(:post) { Post.new }

        before do
          person.posts = [ post ]
        end

        it 'sets the target of the association' do
          expect(person.posts._target).to eq([ post ])
        end

        it 'sets the foreign key of the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'saves the target' do
          expect(post).to be_persisted
        end

        context 'when replacing the association with the same documents' do
          context 'when using the same in memory instance' do
            before do
              person.posts = [ post ]
            end

            it 'keeps the association intact' do
              expect(person.posts).to eq([ post ])
            end

            it 'does not delete the association' do
              expect(person.reload.posts).to eq([ post ])
            end
          end

          context 'when using a new instance' do
            let(:from_db) { Person.find(person.id) }

            before do
              from_db.posts = [ post ]
            end

            it 'keeps the association intact' do
              expect(from_db.posts).to eq([ post ])
            end

            it 'does not delete the association' do
              expect(from_db.reload.posts).to eq([ post ])
            end
          end
        end

        context 'when replacing the with a combination of old and new docs' do
          let(:new_post) { Post.create!(title: 'new post') }

          context 'when using the same in memory instance' do
            before do
              person.posts = [ post, new_post ]
            end

            it 'keeps the association intact' do
              expect(person.posts.size).to eq(2)
            end

            it 'keeps the first post' do
              expect(person.posts).to include(post)
            end

            it 'keeps the second post' do
              expect(person.posts).to include(new_post)
            end

            it 'does not delete the association' do
              expect(person.reload.posts).to eq([ post, new_post ])
            end
          end

          context 'when using a new instance' do
            let(:from_db) { Person.find(person.id) }

            before do
              from_db.posts = [ post, new_post ]
            end

            it 'keeps the association intact' do
              expect(from_db.posts).to eq([ post, new_post ])
            end

            it 'does not delete the association' do
              expect(from_db.reload.posts).to eq([ post, new_post ])
            end
          end
        end

        context 'when replacing the with a combination of only new docs' do
          let(:new_post) { Post.create!(title: 'new post') }

          context 'when using the same in memory instance' do
            before do
              person.posts = [ new_post ]
            end

            it 'keeps the association intact' do
              expect(person.posts).to eq([ new_post ])
            end

            it 'does not delete the association' do
              expect(person.reload.posts).to eq([ new_post ])
            end
          end

          context 'when using a new instance' do
            let(:from_db) { Person.find(person.id) }

            before do
              from_db.posts = [ new_post ]
            end

            it 'keeps the association intact' do
              expect(from_db.posts).to eq([ new_post ])
            end

            it 'does not delete the association' do
              expect(from_db.reload.posts).to eq([ new_post ])
            end
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      context 'when the parent is a new record' do
        let(:movie) { Movie.new }
        let(:rating) { Rating.new }

        before do
          movie.ratings = [ rating ]
        end

        it 'sets the target of the association' do
          expect(movie.ratings._target).to eq([ rating ])
        end

        it 'sets the foreign key on the association' do
          expect(rating.ratable_id).to eq(movie.id)
        end

        it 'sets the base on the inverse association' do
          expect(rating.ratable).to eq(movie)
        end

        it 'does not save the target' do
          expect(rating).not_to be_persisted
        end
      end

      context 'when the parent is not a new record' do
        let(:movie) { Movie.create! }
        let(:rating) { Rating.new }

        before do
          movie.ratings = [ rating ]
        end

        it 'sets the target of the association' do
          expect(movie.ratings._target).to eq([ rating ])
        end

        it 'sets the foreign key of the association' do
          expect(rating.ratable_id).to eq(movie.id)
        end

        it 'sets the base on the inverse association' do
          expect(rating.ratable).to eq(movie)
        end

        it 'saves the target' do
          expect(rating).to be_persisted
        end
      end
    end
  end

  describe '#= []' do
    context 'when the parent is persisted' do
      let(:posts) { [ Post.create!(title: '1'), Post.create!(title: '2') ] }
      let(:person) { Person.create!(posts: posts) }

      context 'when the parent has multiple children' do
        before do
          person.posts = []
        end

        it 'removes all the children' do
          expect(person.posts).to be_empty
        end

        it 'persists the changes' do
          expect(person.posts(true)).to be_empty
        end
      end
    end
  end

  describe '#= nil' do
    context 'when the association is not polymorphic' do
      context 'when the parent is a new record' do
        let(:person) { Person.new }
        let(:post) { Post.new }

        before do
          person.posts = [ post ]
          person.posts = nil
        end

        it 'sets the association to an empty array' do
          expect(person.posts).to be_empty
        end

        it 'removed the inverse association' do
          expect(post.person).to be_nil
        end

        it 'removes the foreign key value' do
          expect(post.person_id).to be_nil
        end
      end

      context 'when the parent is not a new record' do
        let(:person) { Person.create! }

        context 'when dependent is destructive' do
          let(:post) { Post.new }

          before do
            person.posts = [ post ]
            person.posts = nil
          end

          it 'sets the association to empty' do
            expect(person.posts).to be_empty
          end

          it 'removed the inverse association' do
            expect(post.person).to be_nil
          end

          it 'removes the foreign key value' do
            expect(post.person_id).to be_nil
          end

          it 'deletes the target from the database' do
            expect(post).to be_destroyed
          end
        end

        context 'when dependent is not destructive' do
          let(:drug) { Drug.new(name: 'Oxycodone') }

          before do
            person.drugs = [ drug ]
            person.drugs = nil
          end

          it 'sets the association to empty' do
            expect(person.drugs).to be_empty
          end

          it 'removed the inverse association' do
            expect(drug.person).to be_nil
          end

          it 'removes the foreign key value' do
            expect(drug.person_id).to be_nil
          end

          it 'nullifies the association' do
            expect(drug).not_to be_destroyed
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      context 'when the parent is a new record' do
        let(:movie) { Movie.new }
        let(:rating) { Rating.new }

        before do
          movie.ratings = [ rating ]
          movie.ratings = nil
        end

        it 'sets the association to an empty array' do
          expect(movie.ratings).to be_empty
        end

        it 'removed the inverse association' do
          expect(rating.ratable).to be_nil
        end

        it 'removes the foreign key value' do
          expect(rating.ratable_id).to be_nil
        end
      end

      context 'when the parent is not a new record' do
        let(:movie) { Movie.create! }
        let(:rating) { Rating.new }

        before do
          movie.ratings = [ rating ]
          movie.ratings = nil
        end

        it 'sets the association to empty' do
          expect(movie.ratings).to be_empty
        end

        it 'removed the inverse association' do
          expect(rating.ratable).to be_nil
        end

        it 'removes the foreign key value' do
          expect(rating.ratable_id).to be_nil
        end

        context 'when dependent is nullify' do
          it 'does not delete the target from the database' do
            expect(rating).not_to be_destroyed
          end
        end
      end
    end
  end

  describe '#\{name}_ids=' do
    let(:person) { Person.new }
    let(:post_one) { Post.create! }

    let(:post_two) { Post.create! }

    before do
      person.post_ids = [ post_one.id, post_two.id ]
    end

    it 'calls setter with documents find by given ids' do
      expect(person.posts).to eq([ post_one, post_two ])
    end
  end

  describe '#\{name}_ids' do
    let(:posts) { [ Post.create!, Post.create! ] }
    let(:person) { Person.create!(posts: posts) }

    it 'returns ids of documents that are in the association' do
      expect(person.post_ids).to eq(posts.map(&:id))
    end
  end

  %i[ build new ].each do |method|
    describe "##{method}" do
      context 'when model has #initialize' do
        let(:parent) { RefHasManySpec::OverrideInitialize::Parent.create }
        let(:child)  { parent.children.send(method) }

        it 'calls #initialize' do
          expect(child.name).to be == 'default'
        end
      end

      context 'when the association is not polymorphic' do
        context 'when the parent is a new record' do
          let(:person) { Person.new(title: 'sir') }
          let!(:post) { person.posts.send(method, title: '$$$') }

          it 'sets the foreign key on the association' do
            expect(post.person_id).to eq(person.id)
          end

          it 'sets the base on the inverse association' do
            expect(post.person).to eq(person)
          end

          it 'sets the attributes' do
            expect(post.title).to eq('$$$')
          end

          it 'sets the post processed defaults' do
            expect(post.person_title).to eq(person.title)
          end

          it 'does not save the target' do
            expect(post).to be_new_record
          end

          it 'adds the document to the target' do
            expect(person.posts.size).to eq(1)
          end

          it 'does not perform validation' do
            expect(post.errors).to be_empty
          end
        end

        context 'when the parent is not a new record' do
          let(:person) { Person.create! }
          let!(:post) { person.posts.send(method, text: 'Testing') }

          it 'sets the foreign key on the association' do
            expect(post.person_id).to eq(person.id)
          end

          it 'sets the base on the inverse association' do
            expect(post.person).to eq(person)
          end

          it 'sets the attributes' do
            expect(post.text).to eq('Testing')
          end

          it 'does not save the target' do
            expect(post).to be_new_record
          end

          it 'adds the document to the target' do
            expect(person.posts.size).to eq(1)
          end
        end
      end

      context 'when the association is polymorphic' do
        context 'when the parent is a subclass' do
          let(:video_game) { VideoGame.create! }
          let(:rating) { video_game.ratings.build }

          it 'sets the parent on the child' do
            expect(rating.ratable).to eq(video_game)
          end

          it 'sets the correct polymorphic type' do
            expect(rating.ratable_type).to eq('VideoGame')
          end
        end

        context 'when the parent is a new record' do
          let(:movie) { Movie.new }
          let!(:rating) { movie.ratings.send(method, value: 3) }

          it 'sets the foreign key on the association' do
            expect(rating.ratable_id).to eq(movie.id)
          end

          it 'sets the base on the inverse association' do
            expect(rating.ratable).to eq(movie)
          end

          it 'sets the attributes' do
            expect(rating.value).to eq(3)
          end

          it 'does not save the target' do
            expect(rating).to be_new_record
          end

          it 'adds the document to the target' do
            expect(movie.ratings.size).to eq(1)
          end

          it 'does not perform validation' do
            expect(rating.errors).to be_empty
          end
        end

        context 'when the parent is not a new record' do
          let(:movie) { Movie.create! }
          let!(:rating) { movie.ratings.send(method, value: 4) }

          it 'sets the foreign key on the association' do
            expect(rating.ratable_id).to eq(movie.id)
          end

          it 'sets the base on the inverse association' do
            expect(rating.ratable).to eq(movie)
          end

          it 'sets the attributes' do
            expect(rating.value).to eq(4)
          end

          it 'does not save the target' do
            expect(rating).to be_new_record
          end

          it 'adds the document to the target' do
            expect(movie.ratings.size).to eq(1)
          end
        end
      end
    end
  end

  describe '#clear' do
    context 'when the association is not polymorphic' do
      context 'when the parent has been persisted' do
        let!(:person) { Person.create! }

        context 'when the children are persisted' do
          let!(:post) { person.posts.create!(title: 'Testing') }
          let!(:association) { person.posts.clear }

          it 'clears out the association' do
            expect(person.posts).to be_empty
          end

          it 'marks the documents as deleted' do
            expect(post).to be_destroyed
          end

          it 'deletes the documents from the db' do
            expect(person.reload.posts).to be_empty
          end

          it 'returns the association' do
            expect(association).to be_empty
          end
        end

        context 'when the children are not persisted' do
          before do
            person.posts.build(title: 'Testing')
            person.posts.clear
          end

          it 'clears out the association' do
            expect(person.posts).to be_empty
          end
        end
      end

      context 'when the parent is not persisted' do
        let(:person) { Person.new }

        before do
          person.posts.build(title: 'Testing')
          person.posts.clear
        end

        it 'clears out the association' do
          expect(person.posts).to be_empty
        end
      end
    end

    context 'when the association is polymorphic' do
      context 'when the parent has been persisted' do
        let!(:movie) { Movie.create! }

        context 'when the children are persisted' do
          let!(:rating) { movie.ratings.create!(value: 1) }
          let!(:association) { movie.ratings.clear }

          it 'clears out the association' do
            expect(movie.ratings).to be_empty
          end

          it 'handles the proper dependent strategy' do
            expect(rating).not_to be_destroyed
          end

          it 'deletes the documents from the db' do
            expect(movie.reload.ratings).to be_empty
          end

          it 'returns the association' do
            expect(association).to be_empty
          end
        end

        context 'when the children are not persisted' do
          before do
            movie.ratings.build(value: 3)
            movie.ratings.clear
          end

          it 'clears out the association' do
            expect(movie.ratings).to be_empty
          end
        end
      end

      context 'when the parent is not persisted' do
        let(:movie) { Movie.new }

        before do
          movie.ratings.build(value: 2)
          movie.ratings.clear
        end

        it 'clears out the association' do
          expect(movie.ratings).to be_empty
        end
      end
    end
  end

  describe '#concat' do
    context 'when the associations are not polymorphic' do
      context 'when the parent is a new record' do
        let(:person) { Person.new }
        let(:post) { Post.new }

        before do
          person.posts.push post
        end

        it 'sets the foreign key on the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'sets the same instance on the inverse association' do
          expect(post.person).to eql(person)
        end

        it 'does not save the target' do
          expect(post).to be_new_record
        end

        it 'adds the document to the target' do
          expect(person.posts.size).to eq(1)
        end
      end

      context 'when appending in a parent create block' do
        let!(:post) { Post.create!(title: 'testing') }
        let!(:person) do
          Person.create! do |doc|
            doc.posts.push post
          end
        end

        it 'adds the documents to the association' do
          expect(person.posts).to eq([ post ])
        end

        it 'sets the foreign key on the inverse association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'saves the target' do
          expect(post).to be_persisted
        end

        it 'adds the correct number of documents' do
          expect(person.posts.size).to eq(1)
        end

        it 'persists the link' do
          expect(person.reload.posts).to eq([ post ])
        end
      end

      context 'when the parent is not a new record' do
        let(:person) { Person.create! }
        let(:post) { Post.new }

        let(:post_three) { Post.new }

        before do
          person.posts.push post, post_three
        end

        it 'sets the foreign key on the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'sets the same instance on the inverse association' do
          expect(post.person).to eql(person)
        end

        it 'saves the target' do
          expect(post).to be_persisted
        end

        it 'adds the document to the target' do
          expect(person.posts.count).to eq(2)
        end

        context 'when documents already exist on the association' do
          let(:post_two) { Post.new(title: 'Test') }

          before do
            person.posts.push post_two
          end

          it 'sets the foreign key on the association' do
            expect(post_two.person_id).to eq(person.id)
          end

          it 'sets the base on the inverse association' do
            expect(post_two.person).to eq(person)
          end

          it 'sets the same instance on the inverse association' do
            expect(post_two.person).to eql(person)
          end

          it 'saves the target' do
            expect(post_two).to be_persisted
          end

          it 'adds the document to the target' do
            expect(person.posts.count).to eq(3)
          end

          it 'contains the initial document in the target' do
            expect(person.posts).to include(post)
          end

          it 'contains the added document in the target' do
            expect(person.posts).to include(post_two)
          end
        end
      end
    end
  end

  context 'when the associations are polymorphic' do
    context 'when the parent is a new record' do
      let(:movie) { Movie.new }
      let(:rating) { Rating.new }

      before do
        movie.ratings.push rating
      end

      it 'sets the foreign key on the association' do
        expect(rating.ratable_id).to eq(movie.id)
      end

      it 'sets the base on the inverse association' do
        expect(rating.ratable).to eq(movie)
      end

      it 'does not save the target' do
        expect(rating).to be_new_record
      end

      it 'adds the document to the target' do
        expect(movie.ratings.size).to eq(1)
      end
    end

    context 'when the parent is not a new record' do
      let(:movie) { Movie.create! }
      let(:rating) { Rating.new }

      before do
        movie.ratings.push rating
      end

      it 'sets the foreign key on the association' do
        expect(rating.ratable_id).to eq(movie.id)
      end

      it 'sets the base on the inverse association' do
        expect(rating.ratable).to eq(movie)
      end

      it 'saves the target' do
        expect(rating).to be_persisted
      end

      it 'adds the document to the target' do
        expect(movie.ratings.count).to eq(1)
      end
    end
  end

  describe '#count' do
    let(:movie) { Movie.create! }

    context 'when documents have been persisted' do
      before { movie.ratings.create!(value: 1) }

      it 'returns the number of persisted documents' do
        expect(movie.ratings.count).to eq(1)
      end

      it 'block form includes persisted results' do
        expect(movie.ratings.count { |r| r.value >= 1 }).to eq(1)
        expect(movie.ratings.count { |r| r.value >= 2 }).to eq(0)
      end
    end

    context 'when documents have not been persisted' do
      before { movie.ratings.build(value: 1) }

      it 'returns 0' do
        expect(movie.ratings.count).to eq(0)
      end

      it 'block form does not include unpersisted results' do
        expect(movie.ratings.count { |r| r.value == 1 }).to eq(0)
      end
    end

    context 'when mixed persisted and unpersisted documents' do
      before do
        movie.ratings.create(value: 1)
        movie.ratings.build(value: 2)
      end

      it 'returns 1' do
        expect(movie.ratings.count).to eq(1)
      end

      it 'block form includes only persisted results' do
        expect(movie.ratings.count { |r| r.value >= 1 }).to eq(1)
        expect(movie.ratings.count { |r| r.value == 2 }).to eq(0)
      end
    end

    context 'when no document is added' do
      it 'returns false' do
        expect(movie.ratings.any?).to be false
      end
    end

    context 'when new documents exist in the database' do
      context 'when the documents are part of the association' do
        before do
          Rating.create!(ratable: movie)
        end

        it 'returns the count from the db' do
          expect(movie.ratings.count).to eq(1)
        end
      end

      context 'when the documents are not part of the association' do
        before do
          Rating.create!
        end

        it 'returns the count from the db' do
          expect(movie.ratings.count).to eq(0)
        end
      end
    end
  end

  describe '#any?' do
    shared_examples 'does not query database when association is loaded' do
      let!(:fresh_movie) { Movie.find(movie.id) }

      context 'when association is not loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(fresh_movie.ratings.any?).to be expected_result }
          expect_query(1) { expect(fresh_movie.ratings.any?).to be expected_result }
        end

        context 'when using a block' do
          def fresh_movie_ratings?
            fresh_movie.ratings.any? { false }
          end

          it 'queries database on first call only' do
            expect_query(1) { expect(fresh_movie_ratings?).to be false }
            expect_no_queries { expect(fresh_movie_ratings?).to be false }
          end
        end
      end

      context 'when association is loaded' do
        it 'does not query database' do
          expect_query(1) { expect(fresh_movie.ratings.any?).to be expected_result }
          fresh_movie.ratings.to_a
          expect_no_queries { expect(fresh_movie.ratings.any?).to be expected_result }
        end
      end
    end

    let(:movie) { Movie.create! }

    context 'when nothing exists on the association' do
      context 'when no document is added' do
        let!(:movie) { Movie.create! }
        let(:expected_result) { false }

        it 'returns false' do
          expect(movie.ratings.any?).to be false
        end

        include_examples 'does not query database when association is loaded'
      end

      context 'when the document is destroyed' do
        before do
          Rating.create!
        end

        let!(:movie) { Movie.create! }

        it 'returns false' do
          movie.destroy
          expect(movie.ratings.any?).to be false
        end
      end
    end

    context 'when appending to a association and _loaded/_unloaded are empty' do
      let!(:movie) { Movie.create! }

      before do
        movie.ratings << Rating.new
      end

      it 'returns true' do
        expect(movie.ratings.any?).to be true
      end

      context 'when association is not loaded' do
        before do
          movie.ratings._loaded?.should be false
        end

        it 'does not query the database because it knows about the added models' do
          expect_no_queries do
            movie.ratings.any?.should be true
          end
        end
      end

      context 'when association is loaded' do
        it 'does not query database' do
          expect_no_queries { expect(movie.ratings.any?).to be true }
          movie.ratings.to_a
          expect_no_queries { expect(movie.ratings.any?).to be true }
        end
      end
    end

    context 'when appending to an association in a transaction' do
      require_transaction_support

      let!(:movie) { Movie.create! }

      def with_transaction_via(model, &block)
        model.with_session do |session|
          session.with_transaction(&block)
        end
      end

      it 'returns true' do
        with_transaction_via(movie) do
          expect { movie.ratings << Rating.new }.not_to raise_error
          expect(movie.ratings.any?).to be true
        end
      end
    end

    context 'when documents have been persisted' do
      let(:expected_result) { true }

      before do
        movie.ratings.create!(value: 1)
      end

      it 'returns true' do
        expect(movie.ratings.any?).to be true
      end

      include_examples 'does not query database when association is loaded'
    end

    context 'when documents have not been persisted' do
      before do
        movie.ratings.build(value: 1)
      end

      it 'returns false' do
        expect(movie.ratings.any?).to be true
      end
    end

    context 'when new documents exist in the database' do
      before do
        Rating.create!(ratable: movie)
      end

      it 'returns true' do
        expect(movie.ratings.any?).to be true
      end
    end
  end

  describe '#create' do
    context 'when providing multiple attributes' do
      let(:person) { Person.create! }
      let!(:posts) { person.posts.create!([ { text: 'Test1' }, { text: 'Test2' } ]) }

      it 'creates multiple documents' do
        expect(posts.size).to eq(2)
      end

      it 'sets the first attributes' do
        expect(posts.first.text).to eq('Test1')
      end

      it 'sets the second attributes' do
        expect(posts.last.text).to eq('Test2')
      end

      it 'persists the children' do
        expect(person.posts.count).to eq(2)
      end
    end

    context 'when the association is not polymorphic' do
      context 'when the parent is a new record' do
        let(:person) { Person.new }
        let(:post) { person.posts.create!(text: 'Testing') }

        it 'raises an unsaved document error' do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context 'when.creating the document' do
        context 'when the operation is successful' do
          let(:person) { Person.create! }
          let!(:post) { person.posts.create!(text: 'Testing') }

          it 'creates the document' do
            expect(person.posts).to eq([ post ])
          end
        end

        context 'when the operation fails' do
          let(:person) { Person.create! }
          let!(:existing) { Post.create! }

          it 'raises an error' do
            expect { person.posts.create! { |doc| doc._id = existing.id } }
              .to raise_error(Mongo::Error::OperationFailure)
          end
        end
      end

      context 'when the parent is not a new record' do
        let(:person) { Person.create! }
        let!(:post) do
          person.posts.create!(text: 'Testing') do |post|
            post.content = 'The Content'
          end
        end

        it 'sets the foreign key on the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'sets the attributes' do
          expect(post.text).to eq('Testing')
        end

        it 'saves the target' do
          expect(post).not_to be_a_new_record
        end

        it 'calls the passed block' do
          expect(post.content).to eq('The Content')
        end

        it 'adds the document to the target' do
          expect(person.posts.count).to eq(1)
        end
      end

      context 'when passing a new object' do
        let!(:odd) { Odd.create!(name: 'one') }

        before do
          odd.evens.create!(name: 'two', odds: [ Odd.new(name: 'three') ])
        end

        it 'only push one even to the list' do
          expect(odd.evens.count).to eq(1)
        end

        it 'saves the reference back' do
          expect(odd.evens.first.odds.count).to eq(1)
        end

        it 'only saves one even' do
          expect(Even.count).to eq(1)
        end

        it 'saves the first odd and the second' do
          expect(Odd.count).to eq(2)
        end
      end
    end

    context 'when the association is polymorphic' do
      context 'when the parent is a new record' do
        let(:movie) { Movie.new }
        let(:rating) { movie.ratings.create!(value: 1) }

        it 'raises an unsaved document error' do
          expect { rating }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context 'when the parent is not a new record' do
        let(:movie) { Movie.create! }
        let!(:rating) { movie.ratings.create!(value: 3) }

        it 'sets the foreign key on the association' do
          expect(rating.ratable_id).to eq(movie.id)
        end

        it 'sets the base on the inverse association' do
          expect(rating.ratable).to eq(movie)
        end

        it 'sets the attributes' do
          expect(rating.value).to eq(3)
        end

        it 'saves the target' do
          expect(rating).not_to be_new_record
        end

        it 'adds the document to the target' do
          expect(movie.ratings.count).to eq(1)
        end
      end
    end

    context 'when using a different primary_key' do
      let(:person) { Person.create!(username: 'arthurnn') }
      let(:drug) { person.drugs.create! }

      it 'saves pk value on fk field' do
        expect(drug.person_id).to eq('arthurnn')
      end
    end
  end

  describe '#create!' do
    context 'when providing multiple attributes' do
      let(:person) { Person.create! }
      let!(:posts) { person.posts.create!([ { text: 'Test1' }, { text: 'Test2' } ]) }

      it 'creates multiple documents' do
        expect(posts.size).to eq(2)
      end

      it 'sets the first attributes' do
        expect(posts.first.text).to eq('Test1')
      end

      it 'sets the second attributes' do
        expect(posts.last.text).to eq('Test2')
      end

      it 'persists the children' do
        expect(person.posts.count).to eq(2)
      end
    end

    context 'when the association is not polymorphic' do
      context 'when the parent is a new record' do
        let(:person) { Person.new }
        let(:post) { person.posts.create!(title: 'Testing') }

        it 'raises an unsaved document error' do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context 'when the parent is not a new record' do
        let(:person) { Person.create! }
        let!(:post) { person.posts.create!(title: 'Testing') }

        it 'sets the foreign key on the association' do
          expect(post.person_id).to eq(person.id)
        end

        it 'sets the base on the inverse association' do
          expect(post.person).to eq(person)
        end

        it 'sets the attributes' do
          expect(post.title).to eq('Testing')
        end

        it 'saves the target' do
          expect(post).not_to be_a_new_record
        end

        it 'adds the document to the target' do
          expect(person.posts.count).to eq(1)
        end

        context 'when validation fails' do
          it 'raises an error' do
            expect { person.posts.create!(title: '$$$') }
              .to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      context 'when the parent is a new record' do
        let(:movie) { Movie.new }
        let(:rating) { movie.ratings.create!(value: 1) }

        it 'raises an unsaved document error' do
          expect { rating }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context 'when the parent is not a new record' do
        let(:movie) { Movie.create! }
        let!(:rating) { movie.ratings.create!(value: 4) }

        it 'sets the foreign key on the association' do
          expect(rating.ratable_id).to eq(movie.id)
        end

        it 'sets the base on the inverse association' do
          expect(rating.ratable).to eq(movie)
        end

        it 'sets the attributes' do
          expect(rating.value).to eq(4)
        end

        it 'saves the target' do
          expect(rating).not_to be_new_record
        end

        it 'adds the document to the target' do
          expect(movie.ratings.count).to eq(1)
        end

        context 'when validation fails' do
          it 'raises an error' do
            expect { movie.ratings.create!(value: 1000) }
              .to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  describe '#criteria' do
    let(:base) { Movie.new }

    context 'when the association is polymorphic' do
      let(:association) { Movie.relations['ratings'] }
      let(:criteria) { association.criteria(base) }

      it 'includes the type in the criteria' do
        expect(criteria.selector).to eq(
          { 'ratable_id' => base.id, 'ratable_type' => 'Movie' }
        )
      end
    end

    context 'when the association is not polymorphic' do
      let(:association) { Person.relations['posts'] }
      let(:base) { Person.new }

      let(:criteria) { association.criteria(base) }

      it 'does not include the type in the criteria' do
        expect(criteria.selector).to eq({ 'person_id' => base.id })
      end
    end
  end

  %i[ delete delete_one ].each do |method|
    describe "##{method}" do
      let!(:person) { Person.create!(username: 'arthurnn') }

      context 'when the document is found' do
        context 'when no dependent option is set' do
          context 'when we are assigning attributes' do
            let!(:drug) { person.drugs.create! }
            let(:deleted) { person.drugs.send(method, drug) }

            before do
              Mongoid::Threaded.begin_execution(:assign)
            end

            after do
              Mongoid::Threaded.exit_execution(:assign)
            end

            it 'does not cascade' do
              expect(deleted.changes.keys).to eq([ 'person_id' ])
            end
          end

          context 'when the document is loaded' do
            let!(:drug) { person.drugs.create! }
            let!(:deleted) { person.drugs.send(method, drug) }

            it 'returns the document' do
              expect(deleted).to eq(drug)
            end

            it 'deletes the foreign key' do
              expect(drug.person_id).to be_nil
            end

            it 'removes the document from the association' do
              expect(person.drugs).not_to include(drug)
            end
          end

          context 'when the document is not loaded' do
            let!(:drug) { Drug.create!(person_id: person.username) }
            let!(:deleted) { person.drugs.send(method, drug) }

            it 'returns the document' do
              expect(deleted).to eq(drug)
            end

            it 'deletes the foreign key' do
              expect(drug.person_id).to be_nil
            end

            it 'removes the document from the association' do
              expect(person.drugs).not_to include(drug)
            end
          end
        end

        context 'when dependent is delete' do
          context 'when the document is loaded' do
            let!(:post) { person.posts.create!(title: 'test') }
            let!(:deleted) { person.posts.send(method, post) }

            it 'returns the document' do
              expect(deleted).to eq(post)
            end

            it 'deletes the document' do
              expect(post).to be_destroyed
            end

            it 'removes the document from the association' do
              expect(person.posts).not_to include(post)
            end
          end

          context 'when the document is not loaded' do
            let!(:post) { Post.create!(title: 'foo', person_id: person.id) }
            let!(:deleted) { person.posts.send(method, post) }

            it 'returns the document' do
              expect(deleted).to eq(post)
            end

            it 'deletes the document' do
              expect(post).to be_destroyed
            end

            it 'removes the document from the association' do
              expect(person.posts).not_to include(post)
            end
          end
        end
      end

      context 'when the document is not found' do
        let!(:post) { Post.create!(title: 'foo') }
        let!(:deleted) { person.posts.send(method, post) }

        it 'returns nil' do
          expect(deleted).to be_nil
        end

        it 'does not delete the document' do
          expect(post).to be_persisted
        end
      end
    end
  end

  %i[ delete_all destroy_all ].each do |method|
    describe "##{method}" do
      context 'when the association is not polymorphic' do
        context 'when conditions are provided' do
          let(:person) { Person.create!(username: 'durran') }
          let!(:post2) { person.posts.create!(title: 'Test') }

          before { person.posts.create!(title: 'Testing') }

          it 'removes the correct posts' do
            person.posts.send(method, { title: 'Testing' })
            expect(person.posts.count).to eq(1)
            expect(person.reload.posts_count).to eq(1) if method == :destroy_all
          end

          it 'deletes the documents from the database' do
            person.posts.send(method, { title: 'Testing' })
            expect(Post.where(title: 'Testing').count).to eq(0)
          end

          it 'returns the number of documents deleted' do
            expect(person.posts.send(method, { title: 'Testing' })).to eq(1)
          end

          it 'sets the association locally' do
            person.posts.send(method, { title: 'Testing' })
            expect(person.posts).to eq([ post2 ])
          end
        end

        context 'when conditions are not provided' do
          let(:person) { Person.create! }

          before do
            person.posts.create!(title: 'Testing')
            person.posts.create!(title: 'Test')
          end

          it 'removes the correct posts' do
            person.posts.send(method)
            expect(person.posts.count).to eq(0)
          end

          it 'deletes the documents from the database' do
            person.posts.send(method)
            expect(Post.where(title: 'Testing').count).to eq(0)
          end

          it 'returns the number of documents deleted' do
            expect(person.posts.send(method)).to eq(2)
          end

          it 'sets the association locally' do
            person.posts.send(method)
            expect(person.posts).to eq([])
          end
        end
      end

      context 'when the association is polymorphic' do
        context 'when conditions are provided' do
          let(:movie) { Movie.create!(title: 'Bladerunner') }
          let!(:rating2) { movie.ratings.create!(value: 2) }

          before { movie.ratings.create!(value: 1) }

          it 'removes the correct ratings' do
            movie.ratings.send(method, { value: 1 })
            expect(movie.ratings.count).to eq(1)
          end

          it 'deletes the documents from the database' do
            movie.ratings.send(method, { value: 1 })
            expect(Rating.where(value: 1).count).to eq(0)
          end

          it 'returns the number of documents deleted' do
            expect(movie.ratings.send(method, { value: 1 })).to eq(1)
          end

          it 'sets the association locally' do
            movie.ratings.send(method, { value: 1 })
            expect(movie.ratings).to eq([ rating2 ])
          end
        end

        context 'when conditions are not provided' do
          let(:movie) { Movie.create!(title: 'Bladerunner') }

          before do
            movie.ratings.create!(value: 1)
            movie.ratings.create!(value: 2)
          end

          it 'removes the correct ratings' do
            movie.ratings.send(method)
            expect(movie.ratings.count).to eq(0)
          end

          it 'deletes the documents from the database' do
            movie.ratings.send(method)
            expect(Rating.where(value: 1).count).to eq(0)
          end

          it 'returns the number of documents deleted' do
            expect(movie.ratings.send(method)).to eq(2)
          end

          it 'sets the association locally' do
            movie.ratings.send(method)
            expect(movie.ratings).to eq([])
          end
        end
      end
    end
  end

  describe '.embedded?' do
    it 'returns false' do
      expect(described_class).not_to be_embedded
    end
  end

  describe '#exists?' do
    let!(:person) { Person.create! }

    context 'when documents exist in the database' do
      before do
        person.posts.create!
      end

      it 'returns true' do
        expect(person.posts.exists?).to be true
      end

      context 'when association is not loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be true }
          expect_query(1) { expect(person.posts.exists?).to be true }
        end
      end

      context 'when association is loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be true }
          person.posts.to_a
          expect_query(1) { expect(person.posts.exists?).to be true }
        end
      end

      context 'when invoked with specifying conditions' do
        let(:other_person) { Person.create! }
        let(:post) { person.posts.first }

        before do
          person.posts.create title: 'bumfuzzle'
          other_person.posts.create title: 'bumbershoot'
        end

        context 'when the conditions match an associated record' do
          it 'detects its existence by condition' do
            expect(person.posts.exists?(title: 'bumfuzzle')).to be true
            expect(other_person.posts.exists?(title: 'bumbershoot')).to be true
          end

          it 'detects its existence by id' do
            expect(person.posts.exists?(post._id)).to be true
          end

          it 'returns false when given false' do
            expect(person.posts.exists?(false)).to be false
          end

          it 'returns false when given nil' do
            expect(person.posts.exists?(nil)).to be false
          end
        end

        context 'when the conditions match an unassociated record' do
          it 'does not detect its existence' do
            expect(person.posts.exists?(title: 'bumbershoot')).to be false
            expect(other_person.posts.exists?(title: 'bumfuzzle')).to be false
          end
        end
      end
    end

    context 'when documents exist in application but not in database' do
      before do
        person.posts.build
      end

      it 'returns false' do
        expect(person.posts.exists?).to be false
      end

      context 'when association is not loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be false }
          expect_query(1) { expect(person.posts.exists?).to be false }
        end
      end

      context 'when association is loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be false }
          person.posts.to_a
          expect_query(1) { expect(person.posts.exists?).to be false }
        end
      end
    end

    context 'when no documents exist' do
      it 'returns false' do
        expect(person.posts.exists?).to be false
      end

      context 'when association is not loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be false }
          expect_query(1) { expect(person.posts.exists?).to be false }
        end
      end

      context 'when association is loaded' do
        it 'queries database on each call' do
          expect_query(1) { expect(person.posts.exists?).to be false }

          person.posts.to_a

          expect_query(1) { expect(person.posts.exists?).to be false }
        end
      end

      context 'when invoked with specifying conditions' do
        it 'returns false' do
          expect(person.posts.exists?(title: 'hullaballoo')).to be false
        end
      end
    end
  end

  describe '#find' do
    context 'when iterating after the find' do
      let(:person) { Person.create! }
      let(:post_id) { person.posts.first.id }

      before do
        5.times { person.posts.create! }
      end

      it 'does not change the in memory size' do
        expect { person.posts.find(post_id) }
          .not_to(change { person.posts.to_a.size })
      end
    end

    context 'when the association is not polymorphic' do
      let(:person) { Person.create! }
      let!(:post_one) { person.posts.create!(title: 'Test') }
      let!(:post_two) { person.posts.create!(title: 'OMG I has associations') }

      context 'when providing an id' do
        context 'when the id matches' do
          let(:post) { person.posts.find(post_one.id) }

          it 'returns the matching document' do
            expect(post).to eq(post_one)
          end
        end

        context 'when the id matches but is not scoped to the association' do
          let(:post) { Post.create!(title: 'Unscoped') }

          it 'raises an error' do
            expect { person.posts.find(post.id) }
              .to raise_error(Mongoid::Errors::DocumentNotFound,
                              /Document\(s\) not found for class Post with id\(s\)/)
          end
        end

        context 'when the id does not match' do
          context 'when config set to raise error' do
            config_override :raise_not_found_error, true

            it 'raises an error' do
              expect { person.posts.find(BSON::ObjectId.new) }
                .to raise_error(Mongoid::Errors::DocumentNotFound,
                                /Document\(s\) not found for class Post with id\(s\)/)
            end
          end

          context 'when config set not to raise error' do
            config_override :raise_not_found_error, false

            let(:post) { person.posts.find(BSON::ObjectId.new) }

            it 'returns nil' do
              expect(post).to be_nil
            end
          end
        end
      end

      context 'when providing an array of ids' do
        context 'when the ids match' do
          let(:posts) { person.posts.find([ post_one.id, post_two.id ]) }

          it 'returns the matching documents' do
            expect(posts).to eq([ post_one, post_two ])
          end
        end

        context 'when the ids do not match' do
          context 'when config set to raise error' do
            config_override :raise_not_found_error, true

            it 'raises an error' do
              expect { person.posts.find([ BSON::ObjectId.new ]) }
                .to raise_error(Mongoid::Errors::DocumentNotFound,
                                /Document\(s\) not found for class Post with id\(s\)/)
            end
          end

          context 'when config set not to raise error' do
            config_override :raise_not_found_error, false

            let(:posts) { person.posts.find([ BSON::ObjectId.new ]) }

            it 'returns an empty array' do
              expect(posts).to be_empty
            end
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      let(:movie) { Movie.create! }
      let!(:rating_one) { movie.ratings.create!(value: 1) }
      let!(:rating_two) { movie.ratings.create!(value: 5) }

      context 'when providing an id' do
        context 'when the id matches' do
          let(:rating) { movie.ratings.find(rating_one.id) }

          it 'returns the matching document' do
            expect(rating).to eq(rating_one)
          end
        end

        context 'when the id does not match' do
          context 'when config set to raise error' do
            config_override :raise_not_found_error, true

            let(:expected_error) { Mongoid::Errors::DocumentNotFound }
            let(:expected_message) do
              /Document\(s\) not found for class Rating with id\(s\)/
            end

            it 'raises an error' do
              expect { movie.ratings.find(BSON::ObjectId.new) }
                .to raise_error(expected_error, expected_message)
            end
          end

          context 'when config set not to raise error' do
            config_override :raise_not_found_error, false

            let(:rating) { movie.ratings.find(BSON::ObjectId.new) }

            it 'returns nil' do
              expect(rating).to be_nil
            end
          end
        end
      end

      context 'when providing an array of ids' do
        context 'when the ids match' do
          let(:ratings) { movie.ratings.find([ rating_one.id, rating_two.id ]) }

          it 'returns the first matching document' do
            expect(ratings).to include(rating_one)
          end

          it 'returns the second matching document' do
            expect(ratings).to include(rating_two)
          end

          it 'returns the correct number of documents' do
            expect(ratings.size).to eq(2)
          end
        end

        context 'when the ids do not match' do
          context 'when config set to raise error' do
            config_override :raise_not_found_error, true

            let(:expected_error) { Mongoid::Errors::DocumentNotFound }
            let(:expected_message) do
              /Document\(s\) not found for class Rating with id\(s\)/
            end

            it 'raises an error' do
              expect { movie.ratings.find([ BSON::ObjectId.new ]) }
                .to raise_error(expected_error, expected_message)
            end
          end

          context 'when config set not to raise error' do
            config_override :raise_not_found_error, false

            let(:ratings) { movie.ratings.find([ BSON::ObjectId.new ]) }

            it 'returns an empty array' do
              expect(ratings).to be_empty
            end
          end
        end
      end
    end

    context 'with block' do
      let(:titles) { [ 'post one', 'post two' ] }
      let!(:author) { Person.create!(title: 'Person') }
      let!(:post_one) { author.posts.create!(title: titles[0]) }

      before { author.posts.create!(title: titles[1]) }

      it 'finds one' do
        expect(
          author.posts.find do |post|
            post.title == titles[0]
          end
        ).to be_a(Post)
      end

      it 'returns first match of multiple' do
        expect(
          author.posts.find do |post|
            titles.include?(post.title)
          end
        ).to eq(post_one)
      end

      it 'returns nil when not found' do
        expect(
          author.posts.find do |post|
            post.title == 'non existing one'
          end
        ).to be_nil
      end
    end
  end

  describe '#find_or_create_by' do
    context 'when the association is not polymorphic' do
      let(:person) { Person.create! }
      let!(:post) { person.posts.create!(title: 'Testing') }

      context 'when the document exists' do
        let(:found) { person.posts.find_or_create_by(title: 'Testing') }

        it 'returns the document' do
          expect(found).to eq(post)
        end

        it 'keeps the document in the association' do
          expect(found.person).to eq(person)
        end
      end

      context 'when the document does not exist' do
        context 'when there is no criteria attached' do
          let(:found) do
            person.posts.find_or_create_by(title: 'Test') do |post|
              post.content = 'The Content'
            end
          end

          it 'sets the new document attributes' do
            expect(found.title).to eq('Test')
          end

          it 'returns a newly persisted document' do
            expect(found).to be_persisted
          end

          it 'calls the passed block' do
            expect(found.content).to eq('The Content')
          end

          it 'keeps the document in the association' do
            expect(found.person).to eq(person)
          end
        end

        context 'when a criteria is attached' do
          let(:found) { person.posts.recent.find_or_create_by(title: 'Test') }

          it 'sets the new document attributes' do
            expect(found.title).to eq('Test')
          end

          it 'returns a newly persisted document' do
            expect(found).to be_persisted
          end

          it 'keeps the document in the association' do
            expect(found.person).to eq(person)
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      let(:movie) { Movie.create! }
      let!(:rating) { movie.ratings.create!(value: 1) }

      context 'when the document exists' do
        let(:found) { movie.ratings.find_or_create_by(value: 1) }

        it 'returns the document' do
          expect(found).to eq(rating)
        end

        it 'keeps the document in the association' do
          expect(found.ratable).to eq(movie)
        end
      end

      context 'when the document does not exist' do
        let(:found) { movie.ratings.find_or_create_by(value: 3) }

        it 'sets the new document attributes' do
          expect(found.value).to eq(3)
        end

        it 'returns a newly persisted document' do
          expect(found).to be_persisted
        end

        it 'keeps the document in the association' do
          expect(found.ratable).to eq(movie)
        end
      end
    end
  end

  describe '#find_or_create_by!' do
    context 'when the association is not polymorphic' do
      let(:person) { Person.create! }
      let!(:post) { person.posts.create!(title: 'Testing') }

      context 'when the document exists' do
        let(:found) { person.posts.find_or_create_by!(title: 'Testing') }

        it 'returns the document' do
          expect(found).to eq(post)
        end

        it 'keeps the document in the association' do
          expect(found.person).to eq(person)
        end
      end

      context 'when the document does not exist' do
        context 'when there is no criteria attached' do
          let(:found) do
            person.posts.find_or_create_by!(title: 'Test') do |post|
              post.content = 'The Content'
            end
          end

          it 'sets the new document attributes' do
            expect(found.title).to eq('Test')
          end

          it 'returns a newly persisted document' do
            expect(found).to be_persisted
          end

          it 'calls the passed block' do
            expect(found.content).to eq('The Content')
          end

          it 'keeps the document in the association' do
            expect(found.person).to eq(person)
          end
        end

        context 'when a criteria is attached' do
          let(:found) { person.posts.recent.find_or_create_by!(title: 'Test') }

          it 'sets the new document attributes' do
            expect(found.title).to eq('Test')
          end

          it 'returns a newly persisted document' do
            expect(found).to be_persisted
          end

          it 'keeps the document in the association' do
            expect(found.person).to eq(person)
          end
        end
      end
    end

    context 'when the association is polymorphic' do
      let(:movie) { Movie.create! }
      let!(:rating) { movie.ratings.create!(value: 1) }

      context 'when the document exists' do
        let(:found) { movie.ratings.find_or_create_by!(value: 1) }

        it 'returns the document' do
          expect(found).to eq(rating)
        end

        it 'keeps the document in the association' do
          expect(found.ratable).to eq(movie)
        end
      end

      context 'when the document does not exist' do
        let(:found) { movie.ratings.find_or_create_by!(value: 3) }

        it 'sets the new document attributes' do
          expect(found.value).to eq(3)
        end

        it 'returns a newly persisted document' do
          expect(found).to be_persisted
        end

        it 'keeps the document in the association' do
          expect(found.ratable).to eq(movie)
        end

        context 'when validation fails' do
          it 'raises an error' do
            expect { movie.comments.find_or_create_by!(title: '') }
              .to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  describe '#find_or_initialize_by' do
    context 'when the association is not polymorphic' do
      let(:person) { Person.create! }
      let!(:post) { person.posts.create!(title: 'Testing') }

      context 'when the document exists' do
        let(:found) { person.posts.find_or_initialize_by(title: 'Testing') }

        it 'returns the document' do
          expect(found).to eq(post)
        end
      end

      context 'when the document does not exist' do
        let(:found) do
          person.posts.find_or_initialize_by(title: 'Test') do |post|
            post.content = 'The Content'
          end
        end

        it 'sets the new document attributes' do
          expect(found.title).to eq('Test')
        end

        it 'returns a non persisted document' do
          expect(found).not_to be_persisted
        end

        it 'calls the passed block' do
          expect(found.content).to eq('The Content')
        end
      end
    end

    context 'when the association is polymorphic' do
      let(:movie) { Movie.create! }
      let!(:rating) { movie.ratings.create!(value: 1) }

      context 'when the document exists' do
        let(:found) { movie.ratings.find_or_initialize_by(value: 1) }

        it 'returns the document' do
          expect(found).to eq(rating)
        end
      end

      context 'when the document does not exist' do
        let(:found) { movie.ratings.find_or_initialize_by(value: 3) }

        it 'sets the new document attributes' do
          expect(found.value).to eq(3)
        end

        it 'returns a non persisted document' do
          expect(found).not_to be_persisted
        end
      end
    end
  end

  describe '#initialize' do
    context 'when an illegal mixed association exists' do
      let(:post) { Post.new }

      it 'raises an error' do
        expect { post.videos }
          .to raise_error(Mongoid::Errors::MixedRelations)
      end
    end

    context 'when a cyclic association exists' do
      let(:post) { Post.new }

      it 'does not raise an error' do
        expect(post.roles).to be_empty
      end
    end
  end

  describe '#last' do
    let(:person) { Person.create! }

    before { person.posts.create! }

    context 'when a new document is added' do
      let!(:new_post) { person.posts.new }

      context 'when the target is subsequently loaded' do
        before do
          person.posts.entries
        end

        it 'returns the expected last document' do
          expect(person.posts.last).to eq(new_post)
        end
      end
    end
  end

  describe '#max' do
    let(:person) { Person.create! }
    let(:post_one) { Post.create!(rating: 5) }
    let(:post_two) { Post.create!(rating: 10) }

    # rubocop:disable Performance/CompareWithBlock
    let(:max) do
      person.posts.max do |a, b|
        a.rating <=> b.rating
      end
    end
    # rubocop:enable Performance/CompareWithBlock

    before do
      person.posts.push(post_one, post_two)
    end

    it 'returns the document with the max value of the supplied field' do
      expect(max).to eq(post_two)
    end
  end

  describe '#max_by' do
    let(:person) { Person.create! }
    let(:post_one) { Post.create!(rating: 5) }
    let(:post_two) { Post.create!(rating: 10) }
    let(:max) { person.posts.max_by(&:rating) }

    before do
      person.posts.push(post_one, post_two)
    end

    it 'returns the document with the max value of the supplied field' do
      expect(max).to eq(post_two)
    end
  end

  describe '#method_missing' do
    let!(:person) { Person.create! }
    let!(:post_one) { person.posts.create!(title: 'First', content: 'Posting') }

    before do
      person.posts.create!(title: 'Second', content: 'Testing')
    end

    context 'when providing a single criteria' do
      let(:posts) { person.posts.where(title: 'First') }

      it 'applies the criteria to the documents' do
        expect(posts).to eq([ post_one ])
      end

      context 'when providing a collation' do
        let(:posts) { person.posts.where(title: 'FIRST').collation(locale: 'en_US', strength: 2) }

        it 'applies the collation option to the query' do
          expect(posts).to eq([ post_one ])
        end
      end
    end

    context 'when providing a criteria class method' do
      let(:posts) { person.posts.posting }

      it 'applies the criteria to the documents' do
        expect(posts).to eq([ post_one ])
      end
    end

    context 'when chaining criteria' do
      let(:posts) { person.posts.posting.where(:title.in => [ 'First' ]) }

      it 'applies the criteria to the documents' do
        expect(posts).to eq([ post_one ])
      end
    end

    context 'when delegating methods' do
      describe '#distinct' do
        let(:values) { person.posts.distinct(:title) }

        it 'returns the distinct values for the fields' do
          expect(values).to include('First')
          expect(values).to include('Second')
        end
      end
    end
  end

  describe '#min' do
    let(:person) { Person.create! }
    let(:post_one) { Post.create!(rating: 5) }
    let(:post_two) { Post.create!(rating: 10) }

    # rubocop:disable Performance/CompareWithBlock
    let(:min) do
      person.posts.min do |a, b|
        a.rating <=> b.rating
      end
    end
    # rubocop:enable Performance/CompareWithBlock

    before do
      person.posts.push(post_one, post_two)
    end

    it 'returns the min value of the supplied field' do
      expect(min).to eq(post_one)
    end
  end

  describe '#min_by' do
    let(:person) { Person.create! }
    let(:post_one) { Post.create!(rating: 5) }

    let(:post_two) { Post.create!(rating: 10) }
    let(:min) { person.posts.min_by(&:rating) }

    before do
      person.posts.push(post_one, post_two)
    end

    it 'returns the min value of the supplied field' do
      expect(min).to eq(post_one)
    end
  end

  describe '#nullify_all' do
    context 'when the inverse has not been loaded' do
      let(:person) { Person.create! }
      let(:from_db) { Person.first }

      before do
        person.posts.create!(title: 'One')
        person.posts.create!(title: 'Two')
        from_db.posts.nullify_all
      end

      it 'loads the targets before nullifying' do
        expect(from_db.posts).to be_empty
      end

      it 'persists the base nullifications' do
        expect(Person.first.posts).to be_empty
      end

      it 'persists the inverse nullifications' do
        Post.all.each do |post|
          expect(post.person).to be_nil
        end
      end
    end

    context 'when the association is not polymorphic' do
      let(:person) { Person.create! }
      let!(:post_one) { person.posts.create!(title: 'One') }
      let!(:post_two) { person.posts.create!(title: 'Two') }

      before do
        person.posts.nullify_all
      end

      it 'removes all the foreign keys from the target' do
        [ post_one, post_two ].each do |post|
          expect(post.person_id).to be_nil
        end
      end

      it 'removes all the references from the target' do
        [ post_one, post_two ].each do |post|
          expect(post.person).to be_nil
        end
      end

      it 'saves the documents' do
        expect(post_one.reload.person).to be_nil
      end

      context 'when adding a nullified document back to the association' do
        before do
          person.posts.push(post_one)
        end

        it 'persists the association' do
          expect(person.posts(true)).to eq([ post_one ])
        end
      end
    end

    context 'when the association is polymorphic' do
      let(:movie) { Movie.create!(title: 'Oldboy') }
      let!(:rating_one) { movie.ratings.create!(value: 10) }
      let!(:rating_two) { movie.ratings.create!(value: 9) }

      before do
        movie.ratings.nullify_all
      end

      it 'removes all the foreign keys from the target' do
        [ rating_one, rating_two ].each do |rating|
          expect(rating.ratable_id).to be_nil
        end
      end

      it 'removes all the references from the target' do
        [ rating_one, rating_two ].each do |rating|
          expect(rating.ratable).to be_nil
        end
      end
    end
  end

  describe '#respond_to?' do
    let(:person) { Person.new }
    let(:posts) { person.posts }

    Array.public_instance_methods.each do |method|
      context "when checking #{method}" do
        it 'returns true' do
          expect(posts.respond_to?(method)).to be true
        end
      end
    end

    described_class.public_instance_methods.each do |method|
      context "when checking #{method}" do
        it 'returns true' do
          expect(posts.respond_to?(method)).to be true
        end
      end
    end

    Post.scopes.each_key do |method|
      context "when checking #{method}" do
        it 'returns true' do
          expect(posts.respond_to?(method)).to be true
        end
      end
    end
  end

  describe '#scoped' do
    let(:person) { Person.new }
    let(:scoped) { person.posts.scoped }

    it 'returns the association criteria' do
      expect(scoped).to be_a(Mongoid::Criteria)
    end

    it 'returns with an empty selector' do
      expect(scoped.selector).to eq({ 'person_id' => person.id })
    end
  end

  %i[ size length ].each do |method|
    describe "##{method}" do
      let(:movie) { Movie.create! }

      context 'when documents have been persisted' do
        before do
          movie.ratings.create!(value: 1)
        end

        it 'returns 1' do
          expect(movie.ratings.send(method)).to eq(1)
        end
      end

      context 'when documents have not been persisted' do
        before do
          movie.ratings.build(value: 1)
          movie.ratings.create!(value: 2)
        end

        it 'returns the total number of documents' do
          expect(movie.ratings.send(method)).to eq(2)
        end
      end
    end
  end

  describe '#unscoped' do
    context 'when the association has no default scope' do
      before { Post.create!(title: 'unattributed') }

      let!(:person) { Person.create! }
      let!(:post_one) { person.posts.create!(title: 'first') }
      let(:unscoped) { person.posts.unscoped }

      it 'returns only the associated documents' do
        expect(unscoped).to eq([ post_one ])
      end
    end

    context 'when the association has a default scope' do
      before { Acolyte.create!(name: 'unaffiliated') }

      let!(:church) { Church.create! }
      let!(:acolyte_one) { church.acolytes.create!(name: 'first') }
      let(:unscoped) { church.acolytes.unscoped }

      it 'only returns associated documents' do
        expect(unscoped).to eq([ acolyte_one ])
      end

      it 'removes the default scoping options' do
        expect(unscoped.options).to eq({})
      end
    end
  end

  context 'when the association has an order defined' do
    let(:person) { Person.create! }
    let(:post_one) { OrderedPost.create!(rating: 10, title: '1') }

    let(:post_two) { OrderedPost.create!(rating: 20, title: '2') }
    let(:post_three) { OrderedPost.create!(rating: 20, title: '3') }

    before do
      person.ordered_posts.nullify_all
      person.ordered_posts.push(post_one, post_two, post_three)
    end

    it 'order documents' do
      expect(person.ordered_posts(true))
        .to eq [ post_two, post_three, post_one ]
    end

    it 'chaining order criteria' do
      expect(person.ordered_posts.order_by(:title.desc).to_a)
        .to eq [ post_three, post_two, post_one ]
    end
  end

  context 'when reloading the association' do
    let!(:person) { Person.create! }
    let!(:post_one) { Post.create!(title: 'one') }

    let!(:post_two) { Post.create!(title: 'two') }

    before do
      person.posts << post_one
    end

    context 'when the association references the same documents' do
      before do
        Post.collection.find({ _id: post_one.id })
            .update_one({ '$set' => { title: 'reloaded' } })
      end

      let(:reloaded) { person.posts(true) }

      it 'reloads the document from the database' do
        expect(reloaded.first.title).to eq('reloaded')
      end
    end

    context 'when the association references different documents' do
      before do
        person.posts << post_two
      end

      let(:reloaded) { person.posts(true) }

      it 'reloads the first document from the database' do
        expect(reloaded).to include(post_one)
      end

      it 'reloads the new document from the database' do
        expect(reloaded).to include(post_two)
      end
    end
  end

  context 'when the parent is using integer ids' do
    let(:jar) do
      Jar.create! do |doc|
        doc._id = 1
      end
    end

    it 'allows creation of the document' do
      expect(jar.id).to eq(1)
    end
  end

  context 'when adding a document' do
    let(:person) { Person.new }
    let(:post_one) { Post.new }
    let(:first_add) { person.posts.push(post_one) }

    context 'when chaining a second add' do
      let(:post_two) { Post.new }
      let(:result) { first_add.push(post_two) }

      it 'adds both documents' do
        expect(result).to eq([ post_one, post_two ])
      end
    end
  end

  context 'when pushing with a before_add callback' do
    let(:artist) { Artist.new }
    let(:album) { Album.new }

    context 'when execution raises no errors' do
      before do
        artist.albums << album
      end

      it 'executes method callbacks' do
        expect(artist.before_add_referenced_called).to be true
      end

      it 'executes proc callbacks' do
        expect(album.before_add_called).to be true
      end

      it 'adds the document to the association' do
        expect(artist.albums).to eq([ album ])
      end
    end

    context 'when execution raises errors' do
      before do
        allow(artist).to receive(:before_add_album).and_raise
      end

      it 'does not add the document to the association' do
        expect { artist.albums << album }.to raise_error(StandardError)
        expect(artist.albums).to be_empty
      end
    end
  end

  context 'when pushing with an after_add callback' do
    let(:artist) { Artist.new }
    let(:album) { Album.new }

    it 'executes the callback' do
      artist.albums << album
      expect(artist.after_add_referenced_called).to be true
    end

    context 'when execution raises errors' do
      before do
        allow(artist).to receive(:after_add_album).and_raise
      end

      it 'adds the document to the association' do
        expect { artist.albums << album }.to raise_error(StandardError)
        expect(artist.albums).to eq([ album ])
      end
    end

    context 'when the association already exists' do
      before do
        artist.albums << album
        album.save!
        artist.save!
      end

      let(:reloaded_album) do
        Album.where(artist_id: artist.id).first.tap do |a|
          allow(a.artist).to receive(:after_add_album)
        end
      end

      let(:reloaded_album_artist) { reloaded_album.artist }

      it 'does not execute the callback when the association is accessed' do
        expect(reloaded_album_artist.after_add_referenced_called).to be_nil
        expect(reloaded_album_artist).not_to have_received(:after_add_album)
      end
    end
  end

  context 'when #delete or #clear with before_remove callback' do
    let(:artist) { Artist.new }
    let(:album) { Album.new }

    before do
      artist.albums << album
    end

    context 'when executing raises no errors' do
      describe '#delete' do
        before do
          artist.albums.delete album
        end

        it 'executes the callback' do
          expect(artist.before_remove_referenced_called).to be true
        end

        it 'removes the document from the association' do
          expect(artist.albums).to be_empty
        end
      end

      describe '#clear' do
        before do
          artist.albums.clear
        end

        it 'executes the callback' do
          expect(artist.before_remove_referenced_called).to be true
        end

        it 'clears the association' do
          expect(artist.albums).to be_empty
        end
      end

      context 'when execution raises errors' do
        before do
          allow(artist).to receive(:before_remove_album).and_raise
        end

        describe '#delete' do
          it 'does not remove the document from the association' do
            expect { artist.albums.delete(album) }.to raise_error(StandardError)
            expect(artist.albums).to eq([ album ])
          end
        end

        describe '#clear' do
          it 'does not clear the association' do
            expect { artist.albums.clear }.to raise_error(StandardError)
            expect(artist.albums).to eq([ album ])
          end
        end
      end
    end
  end

  context 'when #delete or #clear with after_remove callback' do
    let(:artist) { Artist.new }
    let(:album) { Album.new }

    before do
      artist.albums << album
    end

    context 'without errors' do
      describe '#delete' do
        it 'executes the callback' do
          expect { artist.albums.delete album }.not_to raise_error
          expect(artist.after_remove_referenced_called).to be true
        end
      end

      describe '#clear' do
        it 'executes the callback' do
          expect { artist.albums.clear }.not_to raise_error
          expect(artist.after_remove_referenced_called).to be true
        end
      end
    end

    context 'when errors are raised' do
      before do
        allow(artist).to receive(:after_remove_album).and_raise
      end

      describe '#delete' do
        it 'removes the documents from the association' do
          expect { artist.albums.delete(album) }.to raise_error(StandardError)
          expect(artist.albums).to be_empty
        end
      end

      describe '#clear' do
        it 'removes the documents from the association' do
          expect { artist.albums.clear }.to raise_error(StandardError)
          expect(artist.albums).to be_empty
        end
      end
    end
  end

  context 'when executing a criteria call on an ordered association' do
    let(:person) { Person.create! }
    let!(:post_one) { person.ordered_posts.create!(rating: 1) }

    let!(:post_two) { person.ordered_posts.create!(rating: 5) }
    let(:criteria) { person.ordered_posts.only(:_id, :rating) }

    it 'does not drop the ordering' do
      expect(criteria).to eq([ post_two, post_one ])
    end
  end

  context 'when accessing a scope named open' do
    let(:person) { Person.create! }
    let!(:post) { person.posts.create!(title: 'open') }

    it 'returns the appropriate documents' do
      expect(person.posts.open).to eq([ post ])
    end
  end

  context 'when accessing a association named parent' do
    let!(:parent) { Odd.create!(name: 'odd parent') }
    let(:child) do
      Even
        .create!(parent_id: parent.id, name: 'original even child')
        .tap(&:parent) # preload the parent association
    end

    let(:new_child_name) { 'updated even child' }

    it 'updates the child after accessing the parent' do
      child.name = new_child_name
      child.save!

      reloaded = Even.find(child.id)
      expect(reloaded.name).to eq(new_child_name)
    end
  end

  context 'when a document has referenced and embedded associations' do
    let(:agent) { Agent.new }
    let(:basic) { Basic.new }

    let(:address) { Address.new }

    before do
      agent.basics << basic
      agent.address = address
    end

    it 'saves the document correctly' do
      expect(agent.save!).to be(true)
    end
  end

  context 'when the two models use the same name to refer to the association' do
    let(:agent) { Agent.new }
    let(:band) { Band.new }

    before do
      agent.same_name = band
      agent.save!
      band.save!
      band.reload
    end

    it 'constructs the correct criteria' do
      expect(band.same_name).to eq [ agent ]
    end
  end

  context 'when updating a document with counter_cache on' do
    let(:post) { Post.create! }
    let(:arthur) { Person.create! }
    let(:betty) { Person.create! }

    context 'when setting an attribution' do
      it 'sets the counter correctly' do
        post.update_attribute(:person, arthur)
        expect(arthur.reload.posts_count).to eq 1
      end
    end

    context 'when changing an attribution' do
      it 'sets the counter correctly' do
        post.update_attribute(:person, arthur)
        post.update_attribute(:person, betty)
        expect(arthur.reload.posts_count).to eq 0
        expect(betty.reload.posts_count).to eq 1
      end
    end

    context 'when removing an attribution' do
      it 'sets the counter correctly' do
        post.update_attribute(:person, arthur)
        post.update_attribute(:person, nil)
        expect(arthur.reload.posts_count).to eq 0
      end
    end
  end

  context 'when there is a foreign key in the aliased associations' do
    it 'has the correct aliases' do
      expect(Band.aliased_associations['artist_ids']).to eq('artists')
      expect(Artist.aliased_associations.key?('band_id')).to be false
      expect(Artist.aliased_fields['band']).to eq('band_id')
    end
  end

  context 'when executing concat on foreign key array from the db' do
    before do
      Agent.create!
      Basic.create!
      agent.basic_ids.push basic.id
    end

    let!(:agent) { Agent.first }
    let!(:basic) { Basic.first }

    it 'works on the first attempt' do
      expect(agent.basic_ids).to eq [ basic.id ]
    end
  end
end
