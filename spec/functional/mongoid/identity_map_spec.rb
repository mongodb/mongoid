require "spec_helper"

describe Mongoid::IdentityMap do

  before(:all) do
    Mongoid.identity_map_enabled = true
  end

  after(:all) do
    Mongoid.identity_map_enabled = false
  end

  context "ensure object identity when using 'includes'" do

    it "should return the same object for create- and find-results" do
      person = Person.create(:title => 'Mr.', :ssn => '1')
      post   = person.posts.create

      person = Person.includes(:posts).to_a.first
      post_1 = person.posts.first
      post_2 = Post.find(post.id)

      post.should == post_1
      post.should == post_2

      post.title           = "A post"
      post_1.title.should == "A post"
      post_2.title.should == "A post"
    end

  end

  # FIXME the mocha expectations are not cleared across these two
  #       contexts (why?). Even ...::Many.unstub(:eager_load) doesn't help.
  #       So we spec this last:

  context "prove that eager loading is beeing used" do

    let(:person) { Person.create(:title => 'Mr.', :ssn => '1') }
    let(:post)   { person.posts.create(:title => 'A Post') }

      it "should call set_many with .to_a.first" do
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).to_a.first
      end

      it "should call set_many with .first" do
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).first
      end

      it "should call set_many with .find()" do
        pid = person.id
        Mongoid::IdentityMap.clear
        Mongoid::Relations::Referenced::Many.expects(:eager_load)
        Person.includes(:posts).find(pid)
      end

  end

end
