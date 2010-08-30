require "spec_helper"

describe Mongoid::Relations::Referenced::Many do

  before do
    Person.delete_all
    Post.delete_all
  end

  describe "#<<" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:post) do
        Post.new
      end

      before do
        person.posts << post
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
        person.posts << post
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

  describe "#build" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
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

  describe "#concat" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:post) do
        Post.new
      end

      before do
        person.posts.concat([post])
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
        person.posts.concat([post])
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

    context "when an id is provided" do

      let(:person) do
        Person.create(:ssn => "987-77-7712")
      end

      let(:post) do
        person.posts.create(:title => "Testing")
      end

      it "returns the matching document" do
        person.posts.find(post.id).should == post
      end
    end

    context "when a type is provided" do

      let(:person) do
        Person.create(:ssn => "987-77-7712")
      end

      let!(:post) do
        person.posts.create(:title => "Testing")
      end

      context "when finding all" do

        it "returns the matching documents" do
          person.posts.find(
            :all,
            :conditions => { :title => "Testing" }).should == [ post ]
        end
      end

      context "when finding first" do

        it "returns the matching documents" do
          person.posts.find(
            :first,
            :conditions => { :title => "Testing" }).should == post
        end
      end

      context "when finding last" do

        it "returns the matching documents" do
          person.posts.find(
            :last,
            :conditions => { :title => "Testing" }).should == post
        end
      end
    end
  end

  describe "#push" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:post) do
        Post.new
      end

      before do
        person.posts.push(post)
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
        person.posts.push(post)
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
