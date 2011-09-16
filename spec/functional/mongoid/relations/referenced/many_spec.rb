require "spec_helper"

describe Mongoid::Relations::Referenced::Many do

  before(:all) do
    Mongoid.raise_not_found_error = true
  end

  before do
    [ Person, Post, Movie, Rating, Game ].map(&:delete_all)
  end

  [ :<<, :push, :concat ].each do |method|

    describe "##{method}" do

      context "when the relations are not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
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

          it "does not save the target" do
            post.should be_new
          end

          it "adds the document to the target" do
            person.posts.size.should eq(1)
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create(:ssn => "554-44-3891")
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

          context "when documents already exist on the relation" do

            let(:post_two) do
              Post.new(:title => "Test")
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

            it "contains all documents in the target" do
              person.posts.should eq([ post, post_two ])
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
            movie.ratings.send(method, rating)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should eq(movie.id)
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should eq(movie)
          end

          it "does not save the target" do
            rating.should be_new
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

        context "when parent has String identity" do

          before do
            Movie.identity :type => String
            movie.ratings << Rating.new
          end

          after do
            Movie.identity :type => BSON::ObjectId
          end

          let(:movie) do
            Movie.create
          end

          it "should have rating references" do
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
          person.posts.target.should == [ post ]
        end

        it "sets the foreign key on the relation" do
          post.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          post.person.should == person
        end

        it "does not save the target" do
          post.should_not be_persisted
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "437-11-1112")
        end

        let(:post) do
          Post.new
        end

        before do
          person.posts = [ post ]
        end

        it "sets the target of the relation" do
          person.posts.target.should == [ post ]
        end

        it "sets the foreign key of the relation" do
          post.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          post.person.should == person
        end

        it "saves the target" do
          post.should be_persisted
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
          movie.ratings.target.should == [ rating ]
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should == movie.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == movie
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
          movie.ratings.target.should == [ rating ]
        end

        it "sets the foreign key of the relation" do
          rating.ratable_id.should == movie.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == movie
        end

        it "saves the target" do
          rating.should be_persisted
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
          Person.create(:ssn => "437-11-1112")
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
            Drug.new(:name => "Oxycodone")
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

  describe "#avg" do

    let(:person) do
      Person.create(:ssn => "123-45-6789")
    end

    let(:post_one) do
      Post.create(:rating => 5)
    end

    let(:post_two) do
      Post.create(:rating => 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:avg) do
      person.posts.avg(:rating)
    end

    it "returns the average value of the supplied field" do
      avg.should == 7.5
    end
  end

  [ :build, :new ].each do |method|

    describe "##{method}" do

      context "when the relation is not polymorphic" do

        context "when the parent is a new record" do

          let(:person) do
            Person.new
          end

          let!(:post) do
            person.posts.send(method, :title => "$$$")
          end

          it "sets the foreign key on the relation" do
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            post.person.should == person
          end

          it "sets the attributes" do
            post.title.should == "$$$"
          end

          it "does not save the target" do
            post.should be_new
          end

          it "adds the document to the target" do
            person.posts.size.should == 1
          end

          it "does not perform validation" do
            post.errors.should be_empty
          end
        end

        context "when the parent is not a new record" do

          let(:person) do
            Person.create(:ssn => "554-44-3891")
          end

          let!(:post) do
            person.posts.send(method, :text => "Testing")
          end

          it "sets the foreign key on the relation" do
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            post.person.should == person
          end

          it "sets the attributes" do
            post.text.should == "Testing"
          end

          it "does not save the target" do
            post.should be_new
          end

          it "adds the document to the target" do
            person.posts.size.should == 1
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when the parent is a new record" do

          let(:movie) do
            Movie.new
          end

          let!(:rating) do
            movie.ratings.send(method, :value => 3)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should == movie
          end

          it "sets the attributes" do
            rating.value.should == 3
          end

          it "does not save the target" do
            rating.should be_new
          end

          it "adds the document to the target" do
            movie.ratings.size.should == 1
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
            movie.ratings.send(method, :value => 4)
          end

          it "sets the foreign key on the relation" do
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should == movie
          end

          it "sets the attributes" do
            rating.value.should == 4
          end

          it "does not save the target" do
            rating.should be_new
          end

          it "adds the document to the target" do
            movie.ratings.size.should == 1
          end
        end
      end
    end
  end

  describe "#clear" do

    context "when the relation is not polymorphic" do

      context "when the parent has been persisted" do

        let!(:person) do
          Person.create(:ssn => "123-45-9988")
        end

        context "when the children are persisted" do

          let!(:post) do
            person.posts.create(:title => "Testing")
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
            relation.should == []
          end
        end

        context "when the children are not persisted" do

          let!(:post) do
            person.posts.build(:title => "Testing")
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
          person.posts.build(:title => "Testing")
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
            movie.ratings.create(:value => 1)
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
            relation.should == []
          end
        end

        context "when the children are not persisted" do

          let!(:rating) do
            movie.ratings.build(:value => 3)
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
          movie.ratings.build(:value => 2)
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

  describe "#count" do

    let(:movie) do
      Movie.create
    end

    context "when documents have been persisted" do

      let!(:rating) do
        movie.ratings.create(:value => 1)
      end

      it "returns the number of persisted documents" do
        movie.ratings.count.should == 1
      end
    end

    context "when documents have not been persisted" do

      let!(:rating) do
        movie.ratings.build(:value => 1)
      end

      it "returns 0" do
        movie.ratings.count.should == 0
      end
    end

    context "when new documents exist in the database" do

      context "when the documents are part of the relation" do

        before do
          Rating.create(:ratable => movie)
        end

        it "returns the count from the db" do
          movie.ratings.count.should == 1
        end
      end

      context "when the documents are not part of the relation" do

        before do
          Rating.create
        end

        it "returns the count from the db" do
          movie.ratings.count.should == 0
        end
      end
    end
  end

  describe "#create" do

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          person.posts.create(:text => "Testing")
        end

        it "raises an unsaved document error" do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "554-44-3891")
        end

        let!(:post) do
          person.posts.create(:text => "Testing") do |post|
            post.content = "The Content"
          end
        end

        it "sets the foreign key on the relation" do
          post.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          post.person.should == person
        end

        it "sets the attributes" do
          post.text.should == "Testing"
        end

        it "saves the target" do
          post.should_not be_a_new_record
        end

        it "calls the passed block" do
          post.content.should == "The Content"
        end

        it "adds the document to the target" do
          person.posts.count.should == 1
        end
      end
    end

    context "when the relation is polymorphic" do

      context "when the parent is a new record" do

        let(:movie) do
          Movie.new
        end

        let(:rating) do
          movie.ratings.create(:value => 1)
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
          movie.ratings.create(:value => 3)
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should == movie.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == movie
        end

        it "sets the attributes" do
          rating.value.should == 3
        end

        it "saves the target" do
          rating.should_not be_new
        end

        it "adds the document to the target" do
          movie.ratings.count.should == 1
        end
      end
    end
  end

  describe "#create!" do

    context "when the relation is not polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:post) do
          person.posts.create!(:title => "Testing")
        end

        it "raises an unsaved document error" do
          expect { post }.to raise_error(Mongoid::Errors::UnsavedDocument)
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create(:ssn => "554-44-3891")
        end

        let!(:post) do
          person.posts.create!(:title => "Testing")
        end

        it "sets the foreign key on the relation" do
          post.person_id.should == person.id
        end

        it "sets the base on the inverse relation" do
          post.person.should == person
        end

        it "sets the attributes" do
          post.title.should == "Testing"
        end

        it "saves the target" do
          post.should_not be_a_new_record
        end

        it "adds the document to the target" do
          person.posts.count.should == 1
        end

        context "when validation fails" do

          it "raises an error" do
            expect {
              person.posts.create!(:title => "$$$")
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
          movie.ratings.create!(:value => 1)
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
          movie.ratings.create!(:value => 4)
        end

        it "sets the foreign key on the relation" do
          rating.ratable_id.should == movie.id
        end

        it "sets the base on the inverse relation" do
          rating.ratable.should == movie
        end

        it "sets the attributes" do
          rating.value.should == 4
        end

        it "saves the target" do
          rating.should_not be_new
        end

        it "adds the document to the target" do
          movie.ratings.count.should == 1
        end

        context "when validation fails" do

          it "raises an error" do
            expect {
              movie.ratings.create!(:value => 1000)
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end

  describe "#delete" do

    let!(:person) do
      Person.create(:ssn => "123-11-1111")
    end

    context "when the document is found" do

      context "when no dependent option is set" do

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
            Drug.create(:person_id => person.id)
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
            person.posts.create(:title => "test")
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
            Post.create(:title => "foo", :person_id => person.id)
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
        Post.create(:title => "foo")
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
            Person.create(:ssn => "123-32-2321")
          end

          before do
            person.posts.create(:title => "Testing")
            person.posts.create(:title => "Test")
          end

          it "removes the correct posts" do
            person.posts.send(method, :conditions => { :title => "Testing" })
            person.posts.count.should == 1
          end

          it "deletes the documents from the database" do
            person.posts.send(method, :conditions => {:title => "Testing" })
            Post.where(:title => "Testing").count.should == 0
          end

          it "returns the number of documents deleted" do
            person.posts.send(method, :conditions => { :title => "Testing" }).should == 1
          end
        end

        context "when conditions are not provided" do

          let(:person) do
            Person.create(:ssn => "123-32-2321")
          end

          before do
            person.posts.create(:title => "Testing")
            person.posts.create(:title => "Test")
          end

          it "removes the correct posts" do
            person.posts.send(method)
            person.posts.count.should == 0
          end

          it "deletes the documents from the database" do
            person.posts.send(method)
            Post.where(:title => "Testing").count.should == 0
          end

          it "returns the number of documents deleted" do
            person.posts.send(method).should == 2
          end
        end
      end

      context "when the relation is polymorphic" do

        context "when conditions are provided" do

          let(:movie) do
            Movie.create(:title => "Bladerunner")
          end

          before do
            movie.ratings.create(:value => 1)
            movie.ratings.create(:value => 2)
          end

          it "removes the correct ratings" do
            movie.ratings.send(method, :conditions => { :value => 1 })
            movie.ratings.count.should == 1
          end

          it "deletes the documents from the database" do
            movie.ratings.send(method, :conditions => { :value => 1 })
            Rating.where(:value => 1).count.should == 0
          end

          it "returns the number of documents deleted" do
            movie.ratings.send(method, :conditions => { :value => 1 }).should == 1
          end
        end

        context "when conditions are not provided" do

          let(:movie) do
            Movie.create(:title => "Bladerunner")
          end

          before do
            movie.ratings.create(:value => 1)
            movie.ratings.create(:value => 2)
          end

          it "removes the correct ratings" do
            movie.ratings.send(method)
            movie.ratings.count.should == 0
          end

          it "deletes the documents from the database" do
            movie.ratings.send(method)
            Rating.where(:value => 1).count.should == 0
          end

          it "returns the number of documents deleted" do
            movie.ratings.send(method).should == 2
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

      let!(:person) do
        Person.create(:ssn => "243-12-5243")
      end

      let!(:post) do
        person.posts.create(:title => "testing")
      end

      let(:metadata) do
        Person.relations["posts"]
      end

      let!(:eager) do
        described_class.eager_load(metadata, Person.all)
      end

      let(:map) do
        Mongoid::IdentityMap.get(Post, "person_id" => person.id)
      end

      it "returns the appropriate criteria" do
        eager.selector.should eq({ "person_id" => { "$in" => [ person.id ] }})
      end

      it "puts the documents in the identity map" do
        map.should eq([ post ])
      end
    end

    context "when the relation is polymorphic" do

      let!(:movie) do
        Movie.create(:name => "Bladerunner")
      end

      let!(:book) do
        Book.create(:name => "Game of Thrones")
      end

      let!(:movie_rating) do
        movie.ratings.create(:value => 10)
      end

      let!(:book_rating) do
        book.create_rating(:value => 10)
      end

      let(:metadata) do
        Movie.relations["ratings"]
      end

      let!(:eager) do
        described_class.eager_load(metadata, Movie.all)
      end

      let(:map) do
        Mongoid::IdentityMap.get(Rating, "ratable_id" => movie.id)
      end

      it "returns the appropriate criteria" do
        eager.selector.should eq({ "ratable_id" => { "$in" => [ movie.id ] }})
      end

      it "puts the documents in the identity map" do
        map.should eq([ movie_rating ])
      end
    end
  end

  describe "#exists?" do

    let!(:person) do
      Person.create(:ssn => "292-19-4232")
    end

    context "when documents exist in the database" do

      before do
        person.posts.create
      end

      it "returns true" do
        person.posts.exists?.should == true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.posts.build
      end

      it "returns false" do
        person.posts.exists?.should == false
      end
    end
  end

  describe "#find" do

    context "when the relation is not polymorphic" do

      let(:person) do
        Person.create
      end

      let!(:post_one) do
        person.posts.create(:title => "Test")
      end

      let!(:post_two) do
        person.posts.create(:title => "OMG I has relations")
      end

      context "when providing an id" do

        context "when the id matches" do

          let(:post) do
            person.posts.find(post_one.id)
          end

          it "returns the matching document" do
            post.should == post_one
          end
        end

        context "when the id matches but is not scoped to the relation" do

          let(:post) do
            Post.create(:title => "Unscoped")
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
                person.posts.find(BSON::ObjectId.new)
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:post) do
              person.posts.find(BSON::ObjectId.new)
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
            posts.should == [ post_one, post_two ]
          end
        end

        context "when the ids do not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                person.posts.find([ BSON::ObjectId.new ])
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:posts) do
              person.posts.find([ BSON::ObjectId.new ])
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

      context "when finding first" do

        context "when there is a match" do

          let(:post) do
            person.posts.find(:first, :conditions => { :title => "Test" })
          end

          it "returns the first matching document" do
            post.should == post_one
          end
        end

        context "when there is no match" do

          let(:post) do
            person.posts.find(:first, :conditions => { :title => "Testing" })
          end

          it "returns nil" do
            post.should be_nil
          end
        end
      end

      context "when finding last" do

        context "when there is a match" do

          let(:post) do
            person.posts.find(:last, :conditions => { :title => "OMG I has relations" })
          end

          it "returns the last matching document" do
            post.should == post_two
          end
        end

        context "when there is no match" do

          let(:post) do
            person.posts.find(:last, :conditions => { :title => "Testing" })
          end

          it "returns nil" do
            post.should be_nil
          end
        end
      end

      context "when finding all" do

        context "when there is a match" do

          let(:posts) do
            person.posts.find(:all, :conditions => { :title => { "$exists" => true } })
          end

          it "returns the matching documents" do
            posts.should == [ post_one, post_two ]
          end
        end

        context "when there is no match" do

          let(:posts) do
            person.posts.find(:all, :conditions => { :title => "Other" })
          end

          it "returns an empty array" do
            posts.should be_empty
          end
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating_one) do
        movie.ratings.create(:value => 1)
      end

      let!(:rating_two) do
        movie.ratings.create(:value => 5)
      end

      context "when providing an id" do

        context "when the id matches" do

          let(:rating) do
            movie.ratings.find(rating_one.id)
          end

          it "returns the matching document" do
            rating.should == rating_one
          end
        end

        context "when the id does not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                movie.ratings.find(BSON::ObjectId.new)
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:rating) do
              movie.ratings.find(BSON::ObjectId.new)
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
            ratings.should == [ rating_one, rating_two ]
          end
        end

        context "when the ids do not match" do

          context "when config set to raise error" do

            before do
              Mongoid.raise_not_found_error = true
            end

            it "raises an error" do
              expect {
                movie.ratings.find([ BSON::ObjectId.new ])
              }.to raise_error(Mongoid::Errors::DocumentNotFound)
            end
          end

          context "when config set not to raise error" do

            let(:ratings) do
              movie.ratings.find([ BSON::ObjectId.new ])
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

      context "when finding first" do

        context "when there is a match" do

          let(:rating) do
            movie.ratings.find(:first, :conditions => { :value => 1 })
          end

          it "returns the first matching document" do
            rating.should == rating_one
          end
        end

        context "when there is no match" do

          let(:rating) do
            movie.ratings.find(:first, :conditions => { :value => 11 })
          end

          it "returns nil" do
            rating.should be_nil
          end
        end
      end

      context "when finding last" do

        context "when there is a match" do

          let(:rating) do
            movie.ratings.find(:last, :conditions => { :value => 5 })
          end

          it "returns the last matching document" do
            rating.should == rating_two
          end
        end

        context "when there is no match" do

          let(:rating) do
            movie.ratings.find(:last, :conditions => { :value => 3 })
          end

          it "returns nil" do
            rating.should be_nil
          end
        end
      end

      context "when finding all" do

        context "when there is a match" do

          let(:ratings) do
            movie.ratings.find(:all, :conditions => { :value => { "$exists" => true } })
          end

          it "returns the matching documents" do
            ratings.should == [ rating_one, rating_two ]
          end
        end

        context "when there is no match" do

          let(:ratings) do
            movie.ratings.find(:all, :conditions => { :value => 7 })
          end

          it "returns an empty array" do
            ratings.should be_empty
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
        person.posts.create(:title => "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.posts.find_or_create_by(:title => "Testing")
        end

        it "returns the document" do
          found.should == post
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.posts.find_or_create_by(:title => "Test") do |post|
            post.content = "The Content"
          end
        end

        it "sets the new document attributes" do
          found.title.should == "Test"
        end

        it "returns a newly persisted document" do
          found.should be_persisted
        end

        it "calls the passed block" do
          found.content.should == "The Content"
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating) do
        movie.ratings.create(:value => 1)
      end

      context "when the document exists" do

        let(:found) do
          movie.ratings.find_or_create_by(:value => 1)
        end

        it "returns the document" do
          found.should == rating
        end
      end

      context "when the document does not exist" do

        let(:found) do
          movie.ratings.find_or_create_by(:value => 3)
        end

        it "sets the new document attributes" do
          found.value.should == 3
        end

        it "returns a newly persisted document" do
          found.should be_persisted
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
        person.posts.create(:title => "Testing")
      end

      context "when the document exists" do

        let(:found) do
          person.posts.find_or_initialize_by(:title => "Testing")
        end

        it "returns the document" do
          found.should == post
        end
      end

      context "when the document does not exist" do

        let(:found) do
          person.posts.find_or_initialize_by(:title => "Test") do |post|
            post.content = "The Content"
          end
        end

        it "sets the new document attributes" do
          found.title.should == "Test"
        end

        it "returns a non persisted document" do
          found.should_not be_persisted
        end

        it "calls the passed block" do
          found.content.should == "The Content"
        end
      end
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create
      end

      let!(:rating) do
        movie.ratings.create(:value => 1)
      end

      context "when the document exists" do

        let(:found) do
          movie.ratings.find_or_initialize_by(:value => 1)
        end

        it "returns the document" do
          found.should == rating
        end
      end

      context "when the document does not exist" do

        let(:found) do
          movie.ratings.find_or_initialize_by(:value => 3)
        end

        it "sets the new document attributes" do
          found.value.should == 3
        end

        it "returns a non persisted document" do
          found.should_not be_persisted
        end
      end
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

  describe "#max" do

    let(:person) do
      Person.create(:ssn => "123-45-6789")
    end

    let(:post_one) do
      Post.create(:rating => 5)
    end

    let(:post_two) do
      Post.create(:rating => 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:max) do
      person.posts.max(:rating)
    end

    it "returns the max value of the supplied field" do
      max.should == 10
    end
  end

  describe "#method_missing" do

    let!(:person) do
      Person.create(:ssn => "333-33-3333")
    end

    let!(:post_one) do
      person.posts.create(:title => "First", :content => "Posting")
    end

    let!(:post_two) do
      person.posts.create(:title => "Second", :content => "Testing")
    end

    context "when providing a single criteria" do

      let(:posts) do
        person.posts.where(:title => "First")
      end

      it "applies the criteria to the documents" do
        posts.should == [ post_one ]
      end
    end

    context "when providing a criteria class method" do

      let(:posts) do
        person.posts.posting
      end

      it "applies the criteria to the documents" do
        posts.should == [ post_one ]
      end
    end

    context "when chaining criteria" do

      let(:posts) do
        person.posts.posting.where(:title.in => [ "First" ])
      end

      it "applies the criteria to the documents" do
        posts.should == [ post_one ]
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
      Person.create(:ssn => "123-45-6789")
    end

    let(:post_one) do
      Post.create(:rating => 5)
    end

    let(:post_two) do
      Post.create(:rating => 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:min) do
      person.posts.min(:rating)
    end

    it "returns the min value of the supplied field" do
      min.should == 5
    end
  end

  describe "#nullify_all" do

    context "when the inverse has not been loaded" do

      let(:person) do
        Person.create(:ssn => "999-99-9988")
      end

      let!(:post_one) do
        person.posts.create(:title => "One")
      end

      let!(:post_two) do
        person.posts.create(:title => "Two")
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
        Person.create(:ssn => "999-99-9999")
      end

      let!(:post_one) do
        person.posts.create(:title => "One")
      end

      let!(:post_two) do
        person.posts.create(:title => "Two")
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
    end

    context "when the relation is polymorphic" do

      let(:movie) do
        Movie.create(:title => "Oldboy")
      end

      let!(:rating_one) do
        movie.ratings.create(:value => 10)
      end

      let!(:rating_two) do
        movie.ratings.create(:value => 9)
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

  describe "#sum" do

    let(:person) do
      Person.create(:ssn => "123-45-6789")
    end

    let(:post_one) do
      Post.create(:rating => 5)
    end

    let(:post_two) do
      Post.create(:rating => 10)
    end

    before do
      person.posts.push(post_one, post_two)
    end

    let(:sum) do
      person.posts.sum(:rating)
    end

    it "returns the sum values of the supplied field" do
      sum.should == 15
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
          movie.ratings.create(:value => 1)
        end

        it "returns 1" do
          movie.ratings.send(method).should eq(1)
        end
      end

      context "when documents have not been persisted" do

        before do
          movie.ratings.build(:value => 1)
          movie.ratings.create(:value => 2)
        end

        it "returns the total number of documents" do
          movie.ratings.send(method).should eq(2)
        end
      end
    end
  end

  context "when the association has an order defined" do

    let(:person) do
      Person.create(:ssn => "999-99-9999")
    end

    let(:post_one) do
      Post.create(:rating => 10, :title => '1')
    end

    let(:post_two) do
      Post.create(:rating => 20, :title => '2')
    end

    let(:post_three) do
      Post.create(:rating => 20, :title => '3')
    end

    before do
      person.posts.nullify_all
      person.posts.push(post_one, post_two, post_three)
    end

    it "order documents" do
      person.posts(true).should == [post_two, post_three, post_one]
    end

    it "chaining order criterias" do
      person.posts.order_by(:title.desc).to_a.should == [post_three, post_two, post_one]
    end
  end

  context "when reloading the relation" do

    let!(:person) do
      Person.create(:ssn => "243-41-9678")
    end

    let!(:post_one) do
      Post.create(:title => "one")
    end

    let!(:post_two) do
      Post.create(:title => "two")
    end

    before do
      person.posts << post_one
    end

    context "when the relation references the same documents" do

      before do
        Post.collection.update(
          { :_id => post_one.id }, { "$set" => { :title => "reloaded" }}
        )
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

      it "reloads the new document from the database" do
        reloaded.should eq([ post_one, post_two ])
      end
    end
  end

  context "when the parent is using integer ids" do

    let(:jar) do
      Jar.create(:_id => 1)
    end

    it "allows creation of the document" do
      jar.id.should eq(1)
    end
  end
end
