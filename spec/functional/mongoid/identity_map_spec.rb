require "spec_helper"

describe Mongoid::IdentityMap do

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  context "ensure object identity with eager loading (many)" do

    it "should return the same object for create- and find-results" do
      person_0 = Person.create(:title => 'Mr.', :ssn => '1')
      post_0   = person_0.posts.create

      person_1 = Person.includes(:posts).to_a.last
      post_1   = person_1.posts.first
      post_2   = Post.find(post_0.id)

      person_0.should == person_1

      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'

      post_0.should == post_1
      post_0.should == post_2

      post_0.title         = "A post"
      post_1.title.should == "A post"
      post_2.title.should == "A post"
    end

  end

  context "ensure object identity without eager loading (many)" do

    it "should return the same object for create- and find-results" do
      person_0 = Person.create(:title => 'Mr.', :ssn => '1')
      post_0   = person_0.posts.create

      person_1 = Person.last
      post_1   = person_1.posts.first
      post_2   = Post.find(post_0.id)

      person_0.should == person_1

      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'

      post_0.should == post_1
      post_0.should == post_2

      post_0.title         = "A post"
      post_1.title.should == "A post"
      post_2.title.should == "A post"
    end

  end

  context "ensure object identity without eager loading (many2many)" do

    it "should return the same object for create- and find-results" do
      person_0  = Person.create(:title => 'Mr.', :ssn => '1')
      account_0 = person_0.user_accounts.create

      person_1  = Person.where(:_id => person_0.id).last
      account_1 = person_1.user_accounts.first
      account_2 = UserAccount.find(account_0.id)

      person_0.should == person_1

      person_0.title         = 'Mrs.'
      person_1.title.should == 'Mrs.'

      account_0.should == account_1
      account_0.should == account_2

      account_0.email         = "e@mail.com"
      account_1.email.should == "e@mail.com"
      account_2.email.should == "e@mail.com"
    end

  end

  # FIXME the mocha expectations are not cleared across these two
  #       contexts (why?). Even ...::Many.unstub(:eager_load) doesn't help.
  #       So we spec this last:

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

end
