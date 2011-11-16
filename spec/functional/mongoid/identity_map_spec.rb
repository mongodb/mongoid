require "spec_helper"

describe Mongoid::IdentityMap do

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  context "prove that eager loading is beeing used" do

    let(:person)  { Person.create(:title => 'Mr.', :ssn => '1') }
    let(:post)    { person.posts.create(:title => 'A Post') }
    let(:account) { person.user_accounts.create(:email => 'e@mail.com') }

      it "should call set_many with .to_a.first (many)" do
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).to_a.first
      end

      it "should call set_many with .first (many)" do
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).first
      end

      it "should call set_many with .find() (many)" do
        pid = person.id
        Mongoid::IdentityMap.clear
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).find(pid)
      end

  end

  context "ensure object identity with eager loading (many)" do

    let(:person_0) { Person.create(:title => 'Mr.', :ssn => '1') }
    let(:post_0)   { person_0.posts.create }

    let(:person_1) { Person.includes(:posts).to_a.last }
    let(:post_1)   { person_1.posts.first }
    let(:post_2)   { Post.find(post_0.id) }

    it "should return identical objects for create- and find-results" do
      person_0.should == person_1
    end

    it "should return the same ruby object for create- and find-results" do
      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'
    end

    it "should return identical objects for many-relations" do
      post_0.should == post_1
      post_0.should == post_2
    end

    it "should return the same ruby object for many-relations" do
      post_0.title         = "A post"
      post_1.title.should == "A post"
      post_2.title.should == "A post"
    end

  end

  context "ensure object identity without eager loading (many)" do

    let(:person_0) { Person.create(:title => 'Mr.', :ssn => '1') }
    let(:post_0)   { person_0.posts.create }

    let(:person_1) { Person.last }
    let(:post_1)   { person_1.posts.first }
    let(:post_2)   { Post.find(post_0.id) }

    it "should return identical objects for create- and find-results" do
      person_0.should == person_1
    end

    it "should return the same ruby object for create- and find-results" do
      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'
    end

    it "should return identical objects for many-relations" do
      post_0.should == post_1
      post_0.should == post_2
    end

    it "should return the same ruby object for many-relations" do
      post_0.title         = "A post"
      post_1.title.should == "A post"
      post_2.title.should == "A post"
    end

  end

  context "ensure object identity without eager loading (many2many)" do

    let(:person_0)  { Person.create(:title => 'Mr.', :ssn => '1') }
    let(:person_1)  { Person.where(:_id => person_0.id).last }
    let(:account_0) { person_0.user_accounts.create }
    let(:account_1) { person_1.user_accounts.first }
    let(:account_2) { UserAccount.find(account_0.id) }

    before do
      Person.delete_all
      UserAccount.delete_all
    end

    it "should return the same object for create- and find-results" do
      person_0.should == person_1
    end

    it "should return the same ruby object for create- and find-results" do
      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'
    end

    it "should return identical objects for many2many-relations" do
      account_0.should == account_1
      account_0.should == account_2
    end

    it "should return the same ruby object for many2many-relations" do
      account_0.email         = "e@mail.com"
      account_1.email.should == "e@mail.com"
      account_2.email.should == "e@mail.com"
    end

  end

end
