require "spec_helper"

describe Mongoid::Relations::Referenced::Many do

  before do
    Person.delete_all
    Post.delete_all
  end

  context "when appending to the relation" do

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
    end
  end

  context "when building the relation" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:post) do
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
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "554-44-3891")
      end

      let(:post) do
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
    end
  end

  context "when concating with the relation" do

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
    end
  end

  context "when creating the relation" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:post) do
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
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create(:ssn => "554-44-3891")
      end

      let(:post) do
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
    end
  end

  context "when pushing to the relation" do

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
    end
  end

  context "when setting the relation" do

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

  context "when removing the relation" do

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
