require "spec_helper"

describe Mongoid::Relations::Referenced::Many do

  before do
    Person.delete_all
    Post.delete_all
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
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            post.person.should == person
          end

          it "does not save the target" do
            post.should be_a_new_record
          end

          it "adds the document to the target" do
            person.posts.count.should == 1
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
            post.person_id.should == person.id
          end

          it "sets the base on the inverse relation" do
            post.person.should == person
          end

          it "saves the target" do
            post.should_not be_a_new_record
          end

          it "adds the document to the target" do
            person.posts.count.should == 1
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
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should == movie
          end

          it "does not save the target" do
            rating.should be_new
          end

          it "adds the document to the target" do
            movie.ratings.count.should == 1
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
            rating.ratable_id.should == movie.id
          end

          it "sets the base on the inverse relation" do
            rating.ratable.should == movie
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
  end

  describe "#build" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let!(:post) do
        person.posts.build(:title => "$$$")
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
        post.should be_a_new_record
      end

      it "adds the document to the target" do
        person.posts.count.should == 1
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
        person.posts.build(:text => "Testing")
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
        post.should be_a_new_record
      end

      it "adds the document to the target" do
        person.posts.count.should == 1
      end
    end
  end

  describe "#clear" do

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

  describe "#create" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let!(:post) do
        person.posts.create(:text => "Testing")
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
        post.should be_a_new_record
      end

      it "adds the document to the target" do
        person.posts.count.should == 1
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "554-44-3891")
      end

      let!(:post) do
        person.posts.create(:text => "Testing")
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

      it "adds the document to the target" do
        person.posts.count.should == 1
      end
    end
  end

  describe "#create!" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
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

      it "does not save the target" do
        post.should be_a_new_record
      end

      it "adds the document to the target" do
        person.posts.count.should == 1
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

  describe "#delete_all" do

    context "when conditions are provided" do

      let(:person) do
        Person.create(:ssn => "123-32-2321")
      end

      before do
        person.posts.create(:title => "Testing")
        person.posts.create(:title => "Test")
      end

      it "removes the correct posts" do
        person.posts.delete_all(:title => "Testing")
        person.posts.count.should == 1
      end

      it "deletes the documents from the database" do
        person.posts.delete_all(:title => "Testing")
        Post.where(:title => "Testing").count.should == 0
      end

      it "returns the number of documents deleted" do
        person.posts.delete_all(:title => "Testing").should == 1
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
        person.posts.delete_all
        person.posts.count.should == 0
      end

      it "deletes the documents from the database" do
        person.posts.delete_all
        Post.where(:title => "Testing").count.should == 0
      end

      it "returns the number of documents deleted" do
        person.posts.delete_all.should == 2
      end
    end
  end

  describe "#destroy_all" do

    context "when conditions are provided" do

      let(:person) do
        Person.create(:ssn => "123-32-2321")
      end

      before do
        person.posts.create(:title => "Testing")
        person.posts.create(:title => "Test")
      end

      it "removes the correct posts" do
        person.posts.destroy_all(:title => "Testing")
        person.posts.count.should == 1
      end

      it "deletes the documents from the database" do
        person.posts.destroy_all(:title => "Testing")
        Post.where(:title => "Testing").count.should == 0
      end

      it "returns the number of documents deleted" do
        person.posts.destroy_all(:title => "Testing").should == 1
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
        person.posts.destroy_all
        person.posts.count.should == 0
      end

      it "deletes the documents from the database" do
        person.posts.destroy_all
        Post.where(:title => "Testing").count.should == 0
      end

      it "returns the number of documents deleted" do
        person.posts.destroy_all.should == 2
      end
    end
  end

  describe "#find" do

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

      context "when the id does not match" do

        context "when config set to raise error" do

          before do
            Mongoid.raise_not_found_error = true
          end

          after do
            Mongoid.raise_not_found_error = false
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

          after do
            Mongoid.raise_not_found_error = false
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

  describe "#find_or_create_by" do

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
        person.posts.find_or_create_by(:title => "Test")
      end

      it "sets the new document attributes" do
        found.title.should == "Test"
      end

      it "returns a newly persisted document" do
        found.should be_persisted
      end
    end
  end

  describe "#find_or_initialize_by" do

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
        person.posts.find_or_initialize_by(:title => "Test")
      end

      it "sets the new document attributes" do
        found.title.should == "Test"
      end

      it "returns a non persisted document" do
        found.should_not be_persisted
      end
    end
  end

  describe "#=" do

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

  describe "#= nil" do

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
  end
end
