require "spec_helper"

describe Mongoid::Paranoia do

  before :all do
    ParanoidPost.delete_all
  end

  context 'a soft deleted item' do

    before :each do
      @post = ParanoidPost.create(:title => 'Can I die more than once?')
      @post.delete
      @post.reload
    end

    after :each do
      @post.destroy!
    end

    it 'should have a deletion date' do
      @post.deleted_at.should_not be_nil
    end

    it 'should be restorable' do
      @post.restore
      @post.reload
      @post.deleted_at.should be_nil
    end

    it 'should be invisible to searches' do
      ParanoidPost.count.should == 0
    end

    it 'should be found overriding default deleted_at scoping' do
      ParanoidPost.where(:deleted_at.ne => nil).count.should == 1
    end

    it 'should be hard-destroyable' do
      @post.destroy!
      ParanoidPost.where(:deleted_at.ne => nil).count.should == 0
    end
  end
end
