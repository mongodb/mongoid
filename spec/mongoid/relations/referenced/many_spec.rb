require "spec_helper"

describe Mongoid::Relations::Referenced::Many do

  before :all do
    Mongoid.raise_not_found_error = true

    Drug.belongs_to :person, primary_key: :username
    Person.has_many :drugs, validate: false, primary_key: :username
  end

  after :all do
    Drug.belongs_to :person, counter_cache: true
    Person.has_many :drugs, validate: false
  end

  [ :<<, :push ].each do |method|

    describe "##{method}" do

      context "when the relations are not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          context "when the child is new" do

            let(:post) do
              Post.new
            end

            let!(:added) do
              person.posts.send(method, post)
            end

            it "sets the foreign key on the relation" do
              post.person_id.should eq(person.id)
            end

            it "sets the base on the inverse relation" do
              post.person.should eq(person)
            end

            it "sets the same instance on the inverse relation" do
              post.person.should eql(person)
            end

            it "does not save the target" do
              post.should be_new_record
            end

            it "adds the document to the target" do
              person.posts.size.should eq(1)
            end

            it "returns the relation" do
              added.should eq(person.posts)
            end
          end

          context "when the child is persisted" do

            let(:post) do
              Post.create
            end

            before do
              person.posts.send(method, post)
            end

            it "sets the foreign key on the relation" do
              post.person_id.should eq(person.id)
            end

            it "sets the base on the inverse relation" do
              post.person.should eq(person)
            end

            it "sets the same instance on the inverse relation" do
              post.person.should eql(person)
            end

            it "does not save the parent" do
              person.should be_new_record
            end

            it "adds the document to the target" do
              person.posts.size.should eq(1)
            end

            context "when subsequently saving the parent" do

              before do
                person.save
                post.save
              end

              it "returns the correct count of the relation" do
                person.posts.count.should eq(1)
              end
            end
          end
        end

        context "when appending in a parent create block" do

          let!(:post) do
            Post.create(title: "testing")
          end

          let!(:person) do
            Person.create do |doc|
              doc.posts << post
            end
          end

          it "adds the documents to the relation" do
            person.posts.should eq([ post ])
          end

          it "sets the foreign key on the inverse relation" do
            post.person_id.should eq(person.id)
          end

          it "saves the target" do
            post.should be_persisted
          end

          it "adds the correct number of documents" do
            person.posts.size.should eq(1)
          end

          it "persists the link" do
            person.reload.posts.should eq([ post ])
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create
          end

          let(:post) do
            Post.new
          end

          before do
            person.posts.send(method, post)
          end

          it "sets the foreign key on the relation" do
            post.person_id.should eq(person.id)
          end

          it "sets the base on the inverse relation" do
            post.person.should eq(person)
          end

          it "sets the same instance on the inverse relation" do
            post.person.should eql(person)
          end

          it "saves the target" do
            post.should be_persisted
          end

          it "adds the document to the target" do
            person.posts.count.should eq(1)
          end

          it "increments the counter cache" do
            person.reload.posts_count.should eq(1)
          end

          context "when documents already exist on the relation" do

            let(:post_two) do
              Post.new(title: "Test")
            end

            before do
              person.posts.send(method, post_two)
            end

            it "sets the foreign key on the relation" do
              post_two.person_id.should eq(person.id)
            end

            it "sets the base on the inverse relation" do
              post_two.person.should eq(person)
            end

            it "sets the same instance on the inverse relation" do
              post_two.person.should eql(person)
            end

            it "saves the target" do
              post_two.should be_persisted
            end

            it "adds the document to the target" do
              person.posts.count.should eq(2)
            end

            it "increments the counter cache" do
              person.reload.posts_count.should eq(2)
            end

            it "contains the initial document in the target" do
              person.posts.should include(post)
            end

            it "contains the added document in the target" do
              person.posts.should include(post_two)
            end
          end
        end
      end

      context "when.with(safe: true).adding to the relation" do

        let(:person) do
          Person.create
        end

        context "when the operation succeeds" do

          let(:post) do
            Post.new
          end

          before do
            person.posts.with(safe: true).send(method, post)
          end

          it "adds the document to the relation" do
            person.posts.should eq([ post ])
          end
        end

        context "when the operation fails" do

          let!(:existing) do
            Post.create
          end

          let(:post) do
            Post.new do |doc|
              doc._id = existing.id
            end
          end

          it "raises an error" do
            expect {
              person.posts.with(safe: true).send(method, post)
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end
      end

      context "when the relations are polymorphic" do

        context "when the parent is a new record" do

          let(:movie) do
            Movie.new
          end

          let(:rating) do
            Rating.new
          end

          before do
            movie.ratings.send(method, rating)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should eq(movie.id)
          end

          it "does not set the inverse field on the relation" do
            rating.ratable_field.should be_nil
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should eq(movie)
          end

          it "does not save the target" do
            rating.should be_new_record
          end

          it "adds the document to the target" do
            movie.ratings.size.should eq(1)
          end
        end

        context "when the parent is not a new record" do

          let(:movie) do
            Movie.create
          end

          let(:rating) do
            Rating.new
          end

          before do
            movie.ratings.send(method, rating)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should eq(movie.id)
          end

          it "does not set the inverse field on the relation" do
            rating.ratable_field.should be_nil
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should eq(movie)
          end

          it "saves the target" do
            rating.should be_persisted
          end

          it "adds the document to the target" do
            movie.ratings.count.should eq(1)
          end
        end
      end
    end
  end

  describe "#=" do

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new
        end

        before do
          person.posts = [ post ]
        end

        it "sets the target of the relation" do
          person.posts.target.should eq([ post ])
        end

        it "sets the foreign key on the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "does not save the target" do
          post.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let(:post) do
          Post.new
        end

        before do
          person.posts = [ post ]
        end

        it "sets the target of the relation" do
          person.posts.target.should eq([ post ])
        end

        it "sets the foreign key of the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "saves the target" do
          post.should be_persisted
        end

        context "when replacing the relation with the same documents" do

          context "when using the same in memory instance" do

            before do
              person.posts = [ post ]
            end

            it "keeps the relation intact" do
              person.posts.should eq([ post ])
            end

            it "does not delete the relation" do
              person.reload.posts.should eq([ post ])
            end
          end

          context "when using a new instance" do

            let(:from_db) do
              Person.find(person.id)
            end

            before do
              from_db.posts = [ post ]
            end

            it "keeps the relation intact" do
              from_db.posts.should eq([ post ])
            end

            it "does not delete the relation" do
              from_db.reload.posts.should eq([ post ])
            end
          end
        end

        context "when replacing the with a combination of old and new docs" do

          let(:new_post) do
            Post.create(title: "new post")
          end

          context "when using the same in memory instance" do

            before do
              person.posts = [ post, new_post ]
            end

            it "keeps the relation intact" do
              person.posts.size.should eq(2)
            end

            it "keeps the first post" do
              person.posts.should include(post)
            end

            it "keeps the second post" do
              person.posts.should include(new_post)
            end

            it "does not delete the relation" do
              person.reload.posts.should eq([ post, new_post ])
            end
          end

          context "when using a new instance" do

            let(:from_db) do
              Person.find(person.id)
            end

            before do
              from_db.posts = [ post, new_post ]
            end

            it "keeps the relation intact" do
              from_db.posts.should eq([ post, new_post ])
            end

            it "does not delete the relation" do
              from_db.reload.posts.should eq([ post, new_post ])
            end
          end
        end

        context "when replacing the with a combination of only new docs" do

          let(:new_post) do
            Post.create(title: "new post")
          end

          context "when using the same in memory instance" do

            before do
              person.posts = [ new_post ]
            end

            it "keeps the relation intact" do
              person.posts.should eq([ new_post ])
            end

            it "does not delete the relation" do
              person.reload.posts.should eq([ new_post ])
            end
          end

          context "when using a new instance" do

            let(:from_db) do
              Person.find(person.id)
            end

            before do
              from_db.posts = [ new_post ]
            end

            it "keeps the relation intact" do
              from_db.posts.should eq([ new_post ])
            end

            it "does not delete the relation" do
              from_db.reload.posts.should eq([ new_post ])
            end
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent is a new record" do

        let(:movie) do
          Movie.new
        end

        let(:rating) do
          Rating.new
        end

        before do
          movie.ratings = [ rating ]
        end

        it "sets the target of the relation" do
          movie.ratings.target.should eq([ rating ])
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should eq(movie.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(movie)
        end

        it "does not save the target" do
          rating.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:movie) do
          Movie.create
        end

        let(:rating) do
          Rating.new
        end

        before do
          movie.ratings = [ rating ]
        end

        it "sets the target of the relation" do
          movie.ratings.target.should eq([ rating ])
        end

        it "sets the foreign key of the relation" do
          rating.ratable_id.should eq(movie.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(movie)
        end

        it "saves the target" do
          rating.should be_persisted
        end
      end
    end
  end

  describe "#= []" do

    context "when the parent is persisted" do

      let(:posts) do
        [ Post.create(title: "1"), Post.create(title: "2") ]
      end

      let(:person) do
        Person.create(posts: posts)
      end

      context "when the parent has multiple children" do

        before do
          person.posts = []
        end

        it "removes all the children" do
          person.posts.should be_empty
        end

        it "persists the changes" do
          person.posts(true).should be_empty
        end
      end
    end
  end

  describe "#= nil" do

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new
        end

        before do
          person.posts = [ post ]
          person.posts = nil
        end

        it "sets the relation to an empty array" do
          person.posts.should be_empty
        end

        it "removed the inverse relation" do
          post.person.should be_nil
        end

        it "removes the foreign key value" do
          post.person_id.should be_nil
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        context "when dependent is destructive" do

          let(:post) do
            Post.new
          end

          before do
            person.posts = [ post ]
            person.posts = nil
          end

          it "sets the relation to empty" do
            person.posts.should be_empty
          end

          it "removed the inverse relation" do
            post.person.should be_nil
          end

          it "removes the foreign key value" do
            post.person_id.should be_nil
          end

          it "deletes the target from the database" do
            post.should be_destroyed
          end
        end

        context "when dependent is not destructive" do

          let(:drug) do
            Drug.new(name: "Oxycodone")
          end

          before do
            person.drugs = [ drug ]
            person.drugs = nil
          end

          it "sets the relation to empty" do
            person.drugs.should be_empty
          end

          it "removed the inverse relation" do
            drug.person.should be_nil
          end

          it "removes the foreign key value" do
            drug.person_id.should be_nil
          end

          it "nullifies the relation" do
            drug.should_not be_destroyed
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent is a new record" do

        let(:movie) do
          Movie.new
        end

        let(:rating) do
          Rating.new
        end

        before do
          movie.ratings = [ rating ]
          movie.ratings = nil
        end

        it "sets the relation to an empty array" do
          movie.ratings.should be_empty
        end

        it "removed the inverse relation" do
          rating.ratable.should be_nil
        end

        it "removes the foreign key value" do
          rating.ratable_id.should be_nil
        end
      end

      context "when the parent is not a new record" do

        let(:movie) do
          Movie.create
        end

        let(:rating) do
          Rating.new
        end

        before do
          movie.ratings = [ rating ]
          movie.ratings = nil
        end

        it "sets the relation to empty" do
          movie.ratings.should be_empty
        end

        it "removed the inverse relation" do
          rating.ratable.should be_nil
        end

        it "removes the foreign key value" do
          rating.ratable_id.should be_nil
        end

        context "when dependent is nullify" do

          it "does not delete the target from the database" do
            rating.should_not be_destroyed
          end
        end
      end
    end
  end

  describe "#\{name}_ids=" do

    let(:person) do
      Person.new
    end

    let(:post_one) do
      Post.create
    end

    let(:post_two) do
      Post.create
    end

    before do
      person.post_ids = [ post_one.id, post_two.id ]
    end

    it "calls setter with documents find by given ids" do
      person.posts.should eq([ post_one, post_two ])
    end
  end

  describe "#\{name}_ids" do

    let(:posts) do
      [ Post.create, Post.create ]
    end

    let(:person) do
      Person.create(posts: posts)
    end

    it "returns ids of documents that are in the relation" do
      person.post_ids.should eq(posts.map(&:id))
    end
  end

  [ :build, :new ].each do |method|

    describe "##{method}" do

      context "when providing scoped mass assignment" do

        let(:person) do
          Person.new
        end

        let(:drug) do
          person.drugs.send(
            method,
            { name: "Oxycontin", generic: false }, as: :admin
          )
        end

        it "sets the attributes for the provided role" do
          drug.name.should eq("Oxycontin")
        end

        it "does not set the attributes for other roles" do
          drug.generic.should be_nil
        end
      end

      context "when the relation is not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new(title: "sir")
          end

          let!(:post) do
            person.posts.send(method, title: "$$$")
          end

          it "sets the foreign key on the relation" do
            post.person_id.should eq(person.id)
          end

          it "sets the base on the inverse relation" do
            post.person.should eq(person)
          end

          it "sets the attributes" do
            post.title.should eq("$$$")
          end

          it "sets the post processed defaults" do
            post.person_title.should eq(person.title)
          end

          it "does not save the target" do
            post.should be_new_record
          end

          it "adds the document to the target" do
            person.posts.size.should eq(1)
          end

          it "does not perform validation" do
            post.errors.should be_empty
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create
          end

          let!(:post) do
            person.posts.send(method, text: "Testing")
          end

          it "sets the foreign key on the relation" do
            post.person_id.should eq(person.id)
          end

          it "sets the base on the inverse relation" do
            post.person.should eq(person)
          end

          it "sets the attributes" do
            post.text.should eq("Testing")
          end

          it "does not save the target" do
            post.should be_new_record
          end

          it "adds the document to the target" do
            person.posts.size.should eq(1)
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the parent is a new record" do

          let(:movie) do
            Movie.new
          end

          let!(:rating) do
            movie.ratings.send(method, value: 3)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should eq(movie.id)
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should eq(movie)
          end

          it "sets the attributes" do
            rating.value.should eq(3)
          end

          it "does not save the target" do
            rating.should be_new_record
          end

          it "adds the document to the target" do
            movie.ratings.size.should eq(1)
          end

          it "does not perform validation" do
            rating.errors.should be_empty
          end
        end

        context "when the parent is not a new record" do

          let(:movie) do
            Movie.create
          end

          let!(:rating) do
            movie.ratings.send(method, value: 4)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should eq(movie.id)
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should eq(movie)
          end

          it "sets the attributes" do
            rating.value.should eq(4)
          end

          it "does not save the target" do
            rating.should be_new_record
          end

          it "adds the document to the target" do
            movie.ratings.size.should eq(1)
          end
        end
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Referenced::Many
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(extension?: false)
    end

    it "returns the embedded in builder" do
      described_class.builder(nil, metadata, document).should
        be_a_kind_of(builder_klass)
    end
  end

  describe "#clear" do

    context "when the relation is not polymorphic" do

      context "when the parent has been persisted" do

        let!(:person) do
          Person.create
        end

        context "when the children are persisted" do

          let!(:post) do
            person.posts.create(title: "Testing")
          end

          let!(:relation) do
            person.posts.clear
          end

          it "clears out the relation" do
            person.posts.should be_empty
          end

          it "marks the documents as deleted" do
            post.should be_destroyed
          end

          it "deletes the documents from the db" do
            person.reload.posts.should be_empty
          end

          it "returns the relation" do
            relation.should be_empty
          end
        end

        context "when the children are not persisted" do

          let!(:post) do
            person.posts.build(title: "Testing")
          end

          let!(:relation) do
            person.posts.clear
          end

          it "clears out the relation" do
            person.posts.should be_empty
          end
        end
      end

      context "when the parent is not persisted" do

        let(:person) do
          Person.new
        end

        let!(:post) do
          person.posts.build(title: "Testing")
        end

        let!(:relation) do
          person.posts.clear
        end

        it "clears out the relation" do
          person.posts.should be_empty
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent has been persisted" do

        let!(:movie) do
          Movie.create
        end

        context "when the children are persisted" do

          let!(:rating) do
            movie.ratings.create(value: 1)
          end

          let!(:relation) do
            movie.ratings.clear
          end

          it "clears out the relation" do
            movie.ratings.should be_empty
          end

          it "handles the proper dependent strategy" do
            rating.should_not be_destroyed
          end

          it "deletes the documents from the db" do
            movie.reload.ratings.should be_empty
          end

          it "returns the relation" do
            relation.should be_empty
          end
        end

        context "when the children are not persisted" do

          let!(:rating) do
            movie.ratings.build(value: 3)
          end

          let!(:relation) do
            movie.ratings.clear
          end

          it "clears out the relation" do
            movie.ratings.should be_empty
          end
        end
      end

      context "when the parent is not persisted" do

        let(:movie) do
          Movie.new
        end

        let!(:rating) do
          movie.ratings.build(value: 2)
        end

        let!(:relation) do
          movie.ratings.clear
        end

        it "clears out the relation" do
          movie.ratings.should be_empty
        end
      end
    end
  end

  describe "#concat" do

    context "when the relations are not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new
        end

        before do
          person.posts.concat([ post ])
        end

        it "sets the foreign key on the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "sets the same instance on the inverse relation" do
          post.person.should eql(person)
        end

        it "does not save the target" do
          post.should be_new_record
        end

        it "adds the document to the target" do
          person.posts.size.should eq(1)
        end
      end

      context "when appending in a parent create block" do

        let!(:post) do
          Post.create(title: "testing")
        end

        let!(:person) do
          Person.create do |doc|
            doc.posts.concat([ post ])
          end
        end

        it "adds the documents to the relation" do
          person.posts.should eq([ post ])
        end

        it "sets the foreign key on the inverse relation" do
          post.person_id.should eq(person.id)
        end

        it "saves the target" do
          post.should be_persisted
        end

        it "adds the correct number of documents" do
          person.posts.size.should eq(1)
        end

        it "persists the link" do
          person.reload.posts.should eq([ post ])
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let(:post) do
          Post.new
        end

        let(:post_three) do
          Post.new
        end

        before do
          person.posts.concat([ post, post_three ])
        end

        it "sets the foreign key on the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "sets the same instance on the inverse relation" do
          post.person.should eql(person)
        end

        it "saves the target" do
          post.should be_persisted
        end

        it "adds the document to the target" do
          person.posts.count.should eq(2)
        end

        context "when documents already exist on the relation" do

          let(:post_two) do
            Post.new(title: "Test")
          end

          before do
            person.posts.concat([ post_two ])
          end

          it "sets the foreign key on the relation" do
            post_two.person_id.should eq(person.id)
          end

          it "sets the base on the inverse relation" do
            post_two.person.should eq(person)
          end

          it "sets the same instance on the inverse relation" do
            post_two.person.should eql(person)
          end

          it "saves the target" do
            post_two.should be_persisted
          end

          it "adds the document to the target" do
            person.posts.count.should eq(3)
          end

          it "contains the initial document in the target" do
            person.posts.should include(post)
          end

          it "contains the added document in the target" do
            person.posts.should include(post_two)
          end
        end
      end
    end
  end

  context "when the relations are polymorphic" do

    context "when the parent is a new record" do

      let(:movie) do
        Movie.new
      end

      let(:rating) do
        Rating.new
      end

      before do
        movie.ratings.concat([ rating ])
      end

      it "sets the foreign key on the relation" do
        rating.ratable_id.should eq(movie.id)
      end

      it "sets the base on the inverse relation" do
        rating.ratable.should eq(movie)
      end

      it "does not save the target" do
        rating.should be_new_record
      end

      it "adds the document to the target" do
        movie.ratings.size.should eq(1)
      end
    end

    context "when the parent is not a new record" do

      let(:movie) do
        Movie.create
      end

      let(:rating) do
        Rating.new
      end

      before do
        movie.ratings.concat([ rating ])
      end

      it "sets the foreign key on the relation" do
        rating.ratable_id.should eq(movie.id)
      end

      it "sets the base on the inverse relation" do
        rating.ratable.should eq(movie)
      end

      it "saves the target" do
        rating.should be_persisted
      end

      it "adds the document to the target" do
        movie.ratings.count.should eq(1)
      end
    end
  end

  describe "#count" do

    let(:movie) do
      Movie.create
    end

    context "when documents have been persisted" do

      let!(:rating) do
        movie.ratings.create(value: 1)
      end

      it "returns the number of persisted documents" do
        movie.ratings.count.should eq(1)
      end
    end

    context "when documents have not been persisted" do

      let!(:rating) do
        movie.ratings.build(value: 1)
      end

      it "returns 0" do
        movie.ratings.count.should eq(0)
      end
    end

    context "when new documents exist in the database" do

      context "when the documents are part of the relation" do

        before do
          Rating.create(ratable: movie)
        end

        it "returns the count from the db" do
          movie.ratings.count.should eq(1)
        end
      end

      context "when the documents are not part of the relation" do

        before do
          Rating.create
        end

        it "returns the count from the db" do
          movie.ratings.count.should eq(0)
        end
      end
    end
  end

  describe "#create" do

    context "when providing scoped mass assignment" do

      let(:person) do
        Person.create
      end

      let(:drug) do
        person.drugs.create(
          { name: "Oxycontin", generic: false }, as: :admin
        )
      end

      it "sets the attributes for the provided role" do
        drug.name.should eq("Oxycontin")
      end

      it "does not set the attributes for other roles" do
        drug.generic.should be_nil
      end
    end

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          person.posts.create(text: "Testing")
        end

        it "raises an unsaved document error" do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when.with(safe: true).creating the document" do

        context "when the operation is successful" do

          let(:person) do
            Person.create
          end

          let!(:post) do
            person.posts.with(safe: true).create(text: "Testing")
          end

          it "creates the document" do
            person.posts.should eq([ post ])
          end
        end

        context "when the operation fails" do

          let(:person) do
            Person.create
          end

          let!(:existing) do
            Post.create
          end

          it "raises an error" do
            expect {
              person.posts.with(safe: true).create do |doc|
                doc._id = existing.id
              end
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let!(:post) do
          person.posts.create(text: "Testing") do |post|
            post.content = "The Content"
          end
        end

        it "sets the foreign key on the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "sets the attributes" do
          post.text.should eq("Testing")
        end

        it "saves the target" do
          post.should_not be_a_new_record
        end

        it "calls the passed block" do
          post.content.should eq("The Content")
        end

        it "adds the document to the target" do
          person.posts.count.should eq(1)
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent is a new record" do

        let(:movie) do
          Movie.new
        end

        let(:rating) do
          movie.ratings.create(value: 1)
        end

        it "raises an unsaved document error" do
          expect { rating }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when the parent is not a new record" do

        let(:movie) do
          Movie.create
        end

        let!(:rating) do
          movie.ratings.create(value: 3)
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should eq(movie.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(movie)
        end

        it "sets the attributes" do
          rating.value.should eq(3)
        end

        it "saves the target" do
          rating.should_not be_new_record
        end

        it "adds the document to the target" do
          movie.ratings.count.should eq(1)
        end
      end
    end

    context "when using a diferent primary_key" do

      let(:person) do
        Person.create!(username: 'arthurnn')
      end

      let(:drug) do
        person.drugs.create!
      end

      it 'saves pk value on fk field' do
        drug.person_id.should eq('arthurnn')
      end
    end
  end

  describe "#create!" do

    context "when providing mass scoping options" do

      let(:person) do
        Person.create
      end

      let(:drug) do
        person.drugs.create!(
          { name: "Oxycontin", generic: false }, as: :admin
        )
      end

      it "sets the attributes for the provided role" do
        drug.name.should eq("Oxycontin")
      end

      it "does not set the attributes for other roles" do
        drug.generic.should be_nil
      end
    end

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          person.posts.create!(title: "Testing")
        end

        it "raises an unsaved document error" do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create
        end

        let!(:post) do
          person.posts.create!(title: "Testing")
        end

        it "sets the foreign key on the relation" do
          post.person_id.should eq(person.id)
        end

        it "sets the base on the inverse relation" do
          post.person.should eq(person)
        end

        it "sets the attributes" do
          post.title.should eq("Testing")
        end

        it "saves the target" do
          post.should_not be_a_new_record
        end

        it "adds the document to the target" do
          person.posts.count.should eq(1)
        end

        context "when validation fails" do

          it "raises an error" do
            expect {
              person.posts.create!(title: "$$$")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent is a new record" do

        let(:movie) do
          Movie.new
        end

        let(:rating) do
          movie.ratings.create!(value: 1)
        end

        it "raises an unsaved document error" do
          expect { rating }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when the parent is not a new record" do

        let(:movie) do
          Movie.create
        end

        let!(:rating) do
          movie.ratings.create!(value: 4)
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should eq(movie.id)
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should eq(movie)
        end

        it "sets the attributes" do
          rating.value.should eq(4)
        end

        it "saves the target" do
          rating.should_not be_new_record
        end

        it "adds the document to the target" do
          movie.ratings.count.should eq(1)
        end

        context "when validation fails" do

          it "raises an error" do
            expect {
              movie.ratings.create!(value: 1000)
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  describe ".criteria" do

    let(:id) do
      Moped::BSON::ObjectId.new
    end

    context "when the relation is polymorphic" do

      let(:metadata) do
        Movie.relations["ratings"]
      end

      let(:criteria) do
        described_class.criteria(metadata, id, Movie)
      end

      it "includes the type in the criteria" do
        criteria.selector.should eq(
          {
            "ratable_id"    => id,
            "ratable_type"  => "Movie",
            "ratable_field" => { "$in" => [ :ratings, nil ] }
          }
        )
      end
    end

    context "when the relation is not polymorphic" do

      let(:metadata) do
        Person.relations["posts"]
      end

      let(:criteria) do
        described_class.criteria(metadata, id, Person)
      end

      it "does not include the type in the criteria" do
        criteria.selector.should eq({ "person_id" => id })
      end
    end
  end

  describe "#delete" do

    let!(:person) do
      Person.create(username: 'arthurnn')
    end

    context "when the document is found" do

      context "when no dependent option is set" do

        context "when we are assigning attributes" do

          let!(:drug) do
            person.drugs.create
          end

          before do
            Mongoid::Threaded.begin_execution(:assign)
          end

          after do
            Mongoid::Threaded.exit_execution(:assign)
          end

          let(:deleted) do
            person.drugs.delete(drug)
          end

          it "does not cascade" do
            deleted.changes.keys.should eq([ "person_id" ])
          end
        end

        context "when the document is loaded" do

          let!(:drug) do
            person.drugs.create
          end

          let!(:deleted) do
            person.drugs.delete(drug)
          end

          it "returns the document" do
            deleted.should eq(drug)
          end

          it "deletes the foreign key" do
            drug.person_id.should be_nil
          end

          it "removes the document from the relation" do
            person.drugs.should_not include(drug)
          end
        end

        context "when the document is not loaded" do

          let!(:drug) do
            Drug.create(person_id: person.username)
          end

          let!(:deleted) do
            person.drugs.delete(drug)
          end

          it "returns the document" do
            deleted.should eq(drug)
          end

          it "deletes the foreign key" do
            drug.person_id.should be_nil
          end

          it "removes the document from the relation" do
            person.drugs.should_not include(drug)
          end
        end
      end

      context "when dependent is delete" do

        context "when the document is loaded" do

          let!(:post) do
            person.posts.create(title: "test")
          end

          let!(:deleted) do
            person.posts.delete(post)
          end

          it "returns the document" do
            deleted.should eq(post)
          end

          it "deletes the document" do
            post.should be_destroyed
          end

          it "removes the document from the relation" do
            person.posts.should_not include(post)
          end
        end

        context "when the document is not loaded" do

          let!(:post) do
            Post.create(title: "foo", person_id: person.id)
          end

          let!(:deleted) do
            person.posts.delete(post)
          end

          it "returns the document" do
            deleted.should eq(post)
          end

          it "deletes the document" do
            post.should be_destroyed
          end

          it "removes the document from the relation" do
            person.posts.should_not include(post)
          end
        end
      end
    end

    context "when the document is not found" do

      let!(:post) do
        Post.create(title: "foo")
      end

      let!(:deleted) do
        person.posts.delete(post)
      end

      it "returns nil" do
        deleted.should be_nil
      end

      it "does not delete the document" do
        post.should be_persisted
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      context "when the relation is not polymorphic" do

        context "when conditions are provided" do

          let(:person) do
            Person.create(username: 'durran')
          end

          before do
            person.posts.create(title: "Testing")
            person.posts.create(title: "Test")
          end

          it "removes the correct posts" do
            person.posts.send(method, conditions: { title: "Testing" })
            person.posts.count.should eq(1)
            person.reload.posts_count.should eq(1) if method == :destroy_all
          end

          it "deletes the documents from the database" do
            person.posts.send(method, conditions: {title: "Testing" })
            Post.where(title: "Testing").count.should eq(0)
          end

          it "returns the number of documents deleted" do
            person.posts.send(method, conditions: { title: "Testing" }).should eq(1)
          end
        end

        context "when conditions are not provided" do

          let(:person) do
            Person.create
          end

          before do
            person.posts.create(title: "Testing")
            person.posts.create(title: "Test")
          end

          it "removes the correct posts" do
            person.posts.send(method)
            person.posts.count.should eq(0)
          end

          it "deletes the documents from the database" do
            person.posts.send(method)
            Post.where(title: "Testing").count.should eq(0)
          end

          it "returns the number of documents deleted" do
            person.posts.send(method).should eq(2)
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when conditions are provided" do

          let(:movie) do
            Movie.create(title: "Bladerunner")
          end

          before do
            movie.ratings.create(value: 1)
            movie.ratings.create(value: 2)
          end

          it "removes the correct ratings" do
            movie.ratings.send(method, conditions: { value: 1 })
            movie.ratings.count.should eq(1)
          end

          it "deletes the documents from the database" do
            movie.ratings.send(method, conditions: { value: 1 })
            Rating.where(value: 1).count.should eq(0)
          end

          it "returns the number of documents deleted" do
            movie.ratings.send(method, conditions: { value: 1 }).should eq(1)
          end
        end

        context "when conditions are not provided" do

          let(:movie) do
            Movie.create(title: "Bladerunner")
          end

          before do
            movie.ratings.create(value: 1)
            movie.ratings.create(value: 2)
          end

          it "removes the correct ratings" do
            movie.ratings.send(method)
            movie.ratings.count.should eq(0)
          end

          it "deletes the documents from the database" do
            movie.ratings.send(method)
            Rating.where(value: 1).count.should eq(0)
          end

          it "returns the number of documents deleted" do
            movie.ratings.send(method).should eq(2)
          end
        end
      end
    end
  end

  describe ".eager_load" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when the relation is not polymorphic" do

      context "when the eager load has returned documents" do

        let!(:person) do
          Person.create
        end

        let!(:post) do
          person.posts.create(title: "testing")
        end

        let(:metadata) do
          Person.relations["posts"]
        end

        let!(:eager) do
          described_class.eager_load(metadata, Person.all.map(&:_id))
        end

        let(:map) do
          Mongoid::IdentityMap.get(Post, {"person_id" => person.id}.merge!(metadata.type_relation))
        end

        it "puts the documents in the identity map" do
          map.should eq({ post.id => post })
        end
      end

      context "when the eager load has not returned documents" do

        let!(:person) do
          Person.create
        end

        let(:metadata) do
          Person.relations["posts"]
        end

        let!(:eager) do
          described_class.eager_load(metadata, Person.all.map(&:_id))
        end

        let(:map) do
          Mongoid::IdentityMap.get(Post, {"person_id" => person.id}.merge!(metadata.type_relation))
        end

        it "puts an empty array in the identity map" do
          map.should be_empty
        end
      end

      context "when the eager load has not returned documents for some" do

        let!(:person_one) do
          Person.create
        end

        let!(:person_two) do
          Person.create
        end

        let!(:post) do
          person_one.posts.create(title: "testing")
        end

        let(:metadata) do
          Person.relations["posts"]
        end

        let!(:eager) do
          described_class.eager_load(metadata, Person.all.map(&:_id))
        end

        let(:map_one) do
          Mongoid::IdentityMap.get(Post, {"person_id" => person_one.id}.merge!(metadata.type_relation))
        end

        let(:map_two) do
          Mongoid::IdentityMap.get(Post, {"person_id" => person_two.id}.merge!(metadata.type_relation))
        end

        it "puts the found documents in the identity map" do
          map_one.should eq({ post.id => post })
        end

        it "puts an empty array for parents with no docs" do
          map_two.should be_empty
        end
      end
    end

    context "when the relation is polymorphic" do

      let!(:movie) do
        Movie.create(name: "Bladerunner")
      end

      let!(:book) do
        Book.create(name: "Game of Thrones")
      end

      let!(:movie_rating) do
        movie.ratings.create(value: 10)
      end

      let!(:book_rating) do
        book.create_rating(value: 10)
      end

      let(:metadata) do
        Movie.relations["ratings"]
      end

      let!(:eager) do
        described_class.eager_load(metadata, Movie.all.map(&:_id))
      end

      let(:map) do
        Mongoid::IdentityMap.get(Rating, {"ratable_id" => movie.id}.merge!(metadata.type_relation))
      end

      it "puts the documents in the identity map" do
        map.should eq({ movie_rating.id => movie_rating })
      end
    end
  end

  describe ".embedded?" do

    it "returns false" do
      described_class.should_not be_embedded
    end
  end

  describe "#exists?" do

    let!(:person) do
      Person.create
    end

    context "when documents exist in the database" do

      before do
        person.posts.create
      end

      it "returns true" do
        person.posts.exists?.should be_true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.posts.build
      end

      it "returns false" do
        person.posts.exists?.should be_false
      end
    end
  end

  describe "#find" do

    context "when the identity map is enabled" do

      before do
        Mongoid.identity_map_enabled = true
      end

      after do
        Mongoid.identity_map_enabled = false
      end

      context "when the document is in the map" do

        let(:person) do
          Person.create
        end

        before do
          person.posts.create(title: "Test")
        end

        context "when the document does not belong to the relation" do

          let!(:post) do
            Post.create(title: "testing")
          end

          it "raises an error" do
            expect {
              person.posts.find(post.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end
    end

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:post_one) do
        person.posts.create(title: "Test")
      end

      let!(:post_two) do
        person.posts.create(title: "OMG I has relations")
      end

      context "when providing an id" do

        context "when the id matches" do

          let(:post) do
            person.posts.find(post_one.id)
          end

          it "returns the matching document" do
            post.should eq(post_one)
          end
        end

        context "when the id matches but is not scoped to the relation" do

          let(:post) do
            Post.create(title: "Unscoped")
          end

          it "raises an error" do
            expect {
              person.posts.find(post.id)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when the id does not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                person.posts.find(Moped::BSON::ObjectId.new)
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:post) do
              person.posts.find(Moped::BSON::ObjectId.new)
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns nil" do
              post.should be_nil
            end
          end
        end
      end

      context "when providing an array of ids" do

        context "when the ids match" do

          let(:posts) do
            person.posts.find([ post_one.id, post_two.id ])
          end

          it "returns the matching documents" do
            posts.should eq([ post_one, post_two ])
          end
        end

        context "when the ids do not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                person.posts.find([ Moped::BSON::ObjectId.new ])
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:posts) do
              person.posts.find([ Moped::BSON::ObjectId.new ])
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns an empty array" do
              posts.should be_empty
            end
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating_one) do
        movie.ratings.create(value: 1)
      end

      let!(:rating_two) do
        movie.ratings.create(value: 5)
      end

      context "when providing an id" do

        context "when the id matches" do

          let(:rating) do
            movie.ratings.find(rating_one.id)
          end

          it "returns the matching document" do
            rating.should eq(rating_one)
          end
        end

        context "when the id does not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                movie.ratings.find(Moped::BSON::ObjectId.new)
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:rating) do
              movie.ratings.find(Moped::BSON::ObjectId.new)
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns nil" do
              rating.should be_nil
            end
          end
        end
      end

      context "when providing an array of ids" do

        context "when the ids match" do

          let(:ratings) do
            movie.ratings.find([ rating_one.id, rating_two.id ])
          end

          it "returns the matching documents" do
            ratings.should eq([ rating_one, rating_two ])
          end
        end

        context "when the ids do not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                movie.ratings.find([ Moped::BSON::ObjectId.new ])
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:ratings) do
              movie.ratings.find([ Moped::BSON::ObjectId.new ])
            end

            before do
              Mongoid.raise_not_found_error = false
            end

            after do
              Mongoid.raise_not_found_error = true
            end

            it "returns an empty array" do
              ratings.should be_empty
            end
          end
        end
      end
    end
  end

  describe "#find_or_create_by" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:post) do
        person.posts.create(title: "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.posts.find_or_create_by(title: "Testing")
        end

        it "returns the document" do
          found.should eq(post)
        end

        it "keeps the document in the relation" do
          found.person.should eq(person)
        end
      end

      context "when the document does not exist" do

        context "when there is no criteria attached" do

          let(:found) do
            person.posts.find_or_create_by(title: "Test") do |post|
              post.content = "The Content"
            end
          end

          it "sets the new document attributes" do
            found.title.should eq("Test")
          end

          it "returns a newly persisted document" do
            found.should be_persisted
          end

          it "calls the passed block" do
            found.content.should eq("The Content")
          end

          it "keeps the document in the relation" do
            found.person.should eq(person)
          end
        end

        context "when a criteria is attached" do

          let(:found) do
            person.posts.recent.find_or_create_by(title: "Test")
          end

          it "sets the new document attributes" do
            found.title.should eq("Test")
          end

          it "returns a newly persisted document" do
            found.should be_persisted
          end

          it "keeps the document in the relation" do
            found.person.should eq(person)
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating) do
        movie.ratings.create(value: 1)
      end

      context "when the document exists" do

        let(:found) do
          movie.ratings.find_or_create_by(value: 1)
        end

        it "returns the document" do
          found.should eq(rating)
        end

        it "keeps the document in the relation" do
          found.ratable.should eq(movie)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          movie.ratings.find_or_create_by(value: 3)
        end

        it "sets the new document attributes" do
          found.value.should eq(3)
        end

        it "returns a newly persisted document" do
          found.should be_persisted
        end

        it "keeps the document in the relation" do
          found.ratable.should eq(movie)
        end
      end
    end
  end

  describe "#find_or_initialize_by" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:post) do
        person.posts.create(title: "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.posts.find_or_initialize_by(title: "Testing")
        end

        it "returns the document" do
          found.should eq(post)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.posts.find_or_initialize_by(title: "Test") do |post|
            post.content = "The Content"
          end
        end

        it "sets the new document attributes" do
          found.title.should eq("Test")
        end

        it "returns a non persisted document" do
          found.should_not be_persisted
        end

        it "calls the passed block" do
          found.content.should eq("The Content")
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating) do
        movie.ratings.create(value: 1)
      end

      context "when the document exists" do

        let(:found) do
          movie.ratings.find_or_initialize_by(value: 1)
        end

        it "returns the document" do
          found.should eq(rating)
        end
      end

      context "when the document does not exist" do

        let(:found) do
          movie.ratings.find_or_initialize_by(value: 3)
        end

        it "sets the new document attributes" do
          found.value.should eq(3)
        end

        it "returns a non persisted document" do
          found.should_not be_persisted
        end
      end
    end
  end

  describe ".foreign_key_suffix" do

    it "returns _id" do
      described_class.foreign_key_suffix.should eq("_id")
    end
  end

  describe "#initialize" do

    context "when an illegal mixed relation exists" do

      let(:post) do
        Post.new
      end

      it "raises an error" do
        expect {
          post.videos
        }.to raise_error(Mongoid::Errors::MixedRelations)
      end
    end
  end

  describe ".macro" do

    it "returns has_many" do
      described_class.macro.should eq(:has_many)
    end
  end

  describe "#max" do

    let(:person) do
      Person.create
    end

    let(:post_one) do
      Post.create(rating: 5)
    end

    let(:post_two) do
      Post.create(rating: 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:max) do
      person.posts.max do |a,b|
        a.rating <=> b.rating
      end
    end

    it "returns the document with the max value of the supplied field" do
      max.should eq(post_two)
    end
  end

  describe "#max_by" do

    let(:person) do
      Person.create
    end

    let(:post_one) do
      Post.create(rating: 5)
    end

    let(:post_two) do
      Post.create(rating: 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:max) do
      person.posts.max_by(&:rating)
    end

    it "returns the document with the max value of the supplied field" do
      max.should eq(post_two)
    end
  end

  describe "#method_missing" do

    let!(:person) do
      Person.create
    end

    let!(:post_one) do
      person.posts.create(title: "First", content: "Posting")
    end

    let!(:post_two) do
      person.posts.create(title: "Second", content: "Testing")
    end

    context "when providing a single criteria" do

      let(:posts) do
        person.posts.where(title: "First")
      end

      it "applies the criteria to the documents" do
        posts.should eq([ post_one ])
      end
    end

    context "when providing a criteria class method" do

      let(:posts) do
        person.posts.posting
      end

      it "applies the criteria to the documents" do
        posts.should eq([ post_one ])
      end
    end

    context "when chaining criteria" do

      let(:posts) do
        person.posts.posting.where(:title.in => [ "First" ])
      end

      it "applies the criteria to the documents" do
        posts.should eq([ post_one ])
      end
    end

    context "when delegating methods" do

      describe "#distinct" do

        it "returns the distinct values for the fields" do
          person.posts.distinct(:title).should =~ [ "First",  "Second"]
        end
      end
    end
  end

  describe "#min" do

    let(:person) do
      Person.create
    end

    let(:post_one) do
      Post.create(rating: 5)
    end

    let(:post_two) do
      Post.create(rating: 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:min) do
      person.posts.min do |a, b|
        a.rating <=> b.rating
      end
    end

    it "returns the min value of the supplied field" do
      min.should eq(post_one)
    end
  end

  describe "#min_by" do

    let(:person) do
      Person.create
    end

    let(:post_one) do
      Post.create(rating: 5)
    end

    let(:post_two) do
      Post.create(rating: 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:min) do
      person.posts.min_by(&:rating)
    end

    it "returns the min value of the supplied field" do
      min.should eq(post_one)
    end
  end

  describe "#nullify_all" do

    context "when the inverse has not been loaded" do

      let(:person) do
        Person.create
      end

      let!(:post_one) do
        person.posts.create(title: "One")
      end

      let!(:post_two) do
        person.posts.create(title: "Two")
      end

      let(:from_db) do
        Person.first
      end

      before do
        from_db.posts.nullify_all
      end

      it "loads the targets before nullifying" do
        from_db.posts.should be_empty
      end

      it "persists the base nullifications" do
        Person.first.posts.should be_empty
      end

      it "persists the inverse nullifications" do
        Post.all.each do |post|
          post.person.should be_nil
        end
      end
    end

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:post_one) do
        person.posts.create(title: "One")
      end

      let!(:post_two) do
        person.posts.create(title: "Two")
      end

      before do
        person.posts.nullify_all
      end

      it "removes all the foreign keys from the target" do
        [ post_one, post_two ].each do |post|
          post.person_id.should be_nil
        end
      end

      it "removes all the references from the target" do
        [ post_one, post_two ].each do |post|
          post.person.should be_nil
        end
      end

      it "saves the documents" do
        post_one.reload.person.should be_nil
      end

      context "when adding a nullified document back to the relation" do

        before do
          person.posts.push(post_one)
        end

        it "persists the relation" do
          person.posts(true).should eq([ post_one ])
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create(title: "Oldboy")
      end

      let!(:rating_one) do
        movie.ratings.create(value: 10)
      end

      let!(:rating_two) do
        movie.ratings.create(value: 9)
      end

      before do
        movie.ratings.nullify_all
      end

      it "removes all the foreign keys from the target" do
        [ rating_one, rating_two ].each do |rating|
          rating.ratable_id.should be_nil
        end
      end

      it "removes all the references from the target" do
        [ rating_one, rating_two ].each do |rating|
          rating.ratable.should be_nil
        end
      end
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:posts) do
      person.posts
    end

    Array.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          posts.respond_to?(method).should be_true
        end
      end
    end

    Mongoid::Relations::Referenced::Many.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          posts.respond_to?(method).should be_true
        end
      end
    end

    Post.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          posts.respond_to?(method).should be_true
        end
      end
    end
  end

  describe ".stores_foreign_key?" do

    it "returns false" do
      described_class.stores_foreign_key?.should be_false
    end
  end

  describe "#scoped" do

    let(:person) do
      Person.new
    end

    let(:scoped) do
      person.posts.scoped
    end

    it "returns the relation criteria" do
      scoped.should be_a(Mongoid::Criteria)
    end

    it "returns with an empty selector" do
      scoped.selector.should eq({ "person_id" => person.id })
    end
  end

  [ :size, :length ].each do |method|

    describe "##{method}" do

      let(:movie) do
        Movie.create
      end

      context "when documents have been persisted" do

        let!(:rating) do
          movie.ratings.create(value: 1)
        end

        it "returns 1" do
          movie.ratings.send(method).should eq(1)
        end
      end

      context "when documents have not been persisted" do

        before do
          movie.ratings.build(value: 1)
          movie.ratings.create(value: 2)
        end

        it "returns the total number of documents" do
          movie.ratings.send(method).should eq(2)
        end
      end
    end
  end

  describe "#unscoped" do

    context "when the relation has no default scope" do

      let!(:person) do
        Person.create
      end

      let!(:post_one) do
        person.posts.create(title: "first")
      end

      let!(:post_two) do
        Post.create(title: "second")
      end

      let(:unscoped) do
        person.posts.unscoped
      end

      it "returns only the associated documents" do
        unscoped.should eq([ post_one ])
      end
    end

    context "when the relation has a default scope" do

      let!(:church) do
        Church.create
      end

      let!(:acolyte_one) do
        church.acolytes.create(name: "first")
      end

      let!(:acolyte_two) do
        Acolyte.create(name: "second")
      end

      let(:unscoped) do
        church.acolytes.unscoped
      end

      it "only returns associated documents" do
        unscoped.should eq([ acolyte_one ])
      end

      it "removes the default scoping options" do
        unscoped.options.should eq({})
      end
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should eq(
        [
          :after_add,
          :after_remove,
          :as,
          :autosave,
          :before_add,
          :before_remove,
          :dependent,
          :foreign_key,
          :order,
          :primary_key
        ]
      )
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should be_true
    end
  end

  context "when the association has an order defined" do

    let(:person) do
      Person.create
    end

    let(:post_one) do
      OrderedPost.create(rating: 10, title: '1')
    end

    let(:post_two) do
      OrderedPost.create(rating: 20, title: '2')
    end

    let(:post_three) do
      OrderedPost.create(rating: 20, title: '3')
    end

    before do
      person.ordered_posts.nullify_all
      person.ordered_posts.push(post_one, post_two, post_three)
    end

    it "order documents" do
      person.ordered_posts(true).should eq(
        [post_two, post_three, post_one]
      )
    end

    it "chaining order criterias" do
      person.ordered_posts.order_by(:title.desc).to_a.should eq(
        [post_three, post_two, post_one]
      )
    end
  end

  context "when reloading the relation" do

    let!(:person) do
      Person.create
    end

    let!(:post_one) do
      Post.create(title: "one")
    end

    let!(:post_two) do
      Post.create(title: "two")
    end

    before do
      person.posts << post_one
    end

    context "when the relation references the same documents" do

      before do
        Post.collection.find({ _id: post_one.id }).
          update({ "$set" => { title: "reloaded" }})
      end

      let(:reloaded) do
        person.posts(true)
      end

      it "reloads the document from the database" do
        reloaded.first.title.should eq("reloaded")
      end
    end

    context "when the relation references different documents" do

      before do
        person.posts << post_two
      end

      let(:reloaded) do
        person.posts(true)
      end

      it "reloads the first document from the database" do
        reloaded.should include(post_one)
      end

      it "reloads the new document from the database" do
        reloaded.should include(post_two)
      end
    end
  end

  context "when the parent is using integer ids" do

    let(:jar) do
      Jar.create do |doc|
        doc._id = 1
      end
    end

    it "allows creation of the document" do
      jar.id.should eq(1)
    end
  end

  context "when adding a document" do

    let(:person) do
      Person.new
    end

    let(:post_one) do
      Post.new
    end

    let(:first_add) do
      person.posts.push(post_one)
    end

    context "when chaining a second add" do

      let(:post_two) do
        Post.new
      end

      let(:result) do
        first_add.push(post_two)
      end

      it "adds both documents" do
        result.should eq([ post_one, post_two ])
      end
    end
  end

  context "when pushing with a before_add callback" do

    let(:artist) do
      Artist.new
    end

    let(:album) do
      Album.new
    end

    context "when execution raises no errors" do

      before do
        artist.albums << album
      end

      it "it executes method callbacks" do
        artist.before_add_referenced_called.should be_true
      end

      it "it executes proc callbacks" do
        album.before_add_called.should be_true
      end

      it "adds the document to the relation" do
        artist.albums.should eq([ album ])
      end
    end

    context "when execution raises errors" do

      before do
        artist.should_receive(:before_add_album).and_raise
      end

      it "does not add the document to the relation" do
        expect {
          artist.albums << album
        }.to raise_error
        artist.albums.should be_empty
      end
    end
  end

  context "when pushing with an after_add callback" do

    let(:artist) do
      Artist.new
    end

    let(:album) do
      Album.new
    end

    it "executes the callback" do
      artist.albums << album
      artist.after_add_referenced_called.should be_true
    end

    context "when execution raises errors" do

      before do
        artist.should_receive(:after_add_album).and_raise
      end

      it "adds the document to the relation" do
        expect {
          artist.albums << album
        }.to raise_error
        artist.albums.should eq([ album ])
      end
    end
  end

  context "when #delete or #clear with before_remove callback" do

    let(:artist) do
      Artist.new
    end

    let(:album) do
      Album.new
    end

    before do
      artist.albums << album
    end

    context "when executing raises no errors" do

      describe "#delete" do

        before do
          artist.albums.delete album
        end

        it "executes the callback" do
          artist.before_remove_referenced_called.should be_true
        end

        it "removes the document from the relation" do
          artist.albums.should be_empty
        end
      end

      describe "#clear" do

        before do
          artist.albums.clear
        end

        it "executes the callback" do
          artist.before_remove_referenced_called.should be_true
        end

        it "clears the relation" do
          artist.albums.should be_empty
        end
      end

      context "when execution raises errors" do

        before do
          artist.should_receive(:before_remove_album).and_raise
        end

        describe "#delete" do

          before do
            expect {
              artist.albums.delete album
            }.to raise_error
          end

          it "does not remove the document from the relation" do
            artist.albums.should eq([ album ])
          end
        end

        describe "#clear" do

          before do
            expect {
              artist.albums.clear
            }.to raise_error
          end

          it "does not clear the relation" do
            artist.albums.should eq([ album ])
          end
        end
      end
    end
  end

  context "when #delete or #clear with after_remove callback" do

    let(:artist) do
      Artist.new
    end

    let(:album) do
      Album.new
    end

    before do
      artist.albums << album
    end

    context "without errors" do

      describe "#delete" do

        before do
          artist.albums.delete album
        end

        it "executes the callback" do
          artist.after_remove_referenced_called.should be_true
        end
      end

      describe "#clear" do

        before do
          artist.albums.clear
        end

        it "executes the callback" do
          artist.albums.clear
          artist.after_remove_referenced_called.should be_true
        end
      end
    end

    context "when errors are raised" do

      before do
        artist.should_receive(:after_remove_album).and_raise
      end

      describe "#delete" do

        before do
          expect {
            artist.albums.delete album
          }.to raise_error
        end

        it "removes the documents from the relation" do
          artist.albums.should be_empty
        end
      end

      describe "#clear" do

        before do
          expect {
            artist.albums.clear
          }.to raise_error
        end

        it "removes the documents from the relation" do
          artist.albums.should be_empty
        end
      end
    end
  end

  context "when executing a criteria call on an ordered relation" do

    let(:person) do
      Person.create
    end

    let!(:post_one) do
      person.ordered_posts.create(rating: 1)
    end

    let!(:post_two) do
      person.ordered_posts.create(rating: 5)
    end

    let(:criteria) do
      person.ordered_posts.only(:_id, :rating)
    end

    it "does not drop the ordering" do
      criteria.should eq([ post_two, post_one ])
    end
  end
end
