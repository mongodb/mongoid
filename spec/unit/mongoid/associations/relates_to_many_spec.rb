require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Associations::RelatesToMany do

  describe ".initialize" do

    context "when related id has been set" do

      before do
        @document = Person.new(:posts_ids => ["4", "5"])
        @options = Mongoid::Associations::Options.new(:name => :posts)
        @criteria = stub
        @first = stub(:id => "4")
        @second = stub(:id => "5")
        @related = [@first, @second]
      end

      it "finds the object by id" do
        Post.expects(:criteria).returns(@criteria)
        @criteria.expects(:in).with(:_id => @document.posts_ids).returns(@related)
        association = Mongoid::Associations::RelatesToMany.new(@document, @options)
        association.should == @related
      end

    end

  end

  describe ".macro" do

    it "returns :relates_to_many" do
      Mongoid::Associations::RelatesToMany.macro.should == :relates_to_many
    end

  end

  describe ".update" do

    before do
      @first = stub(:id => "4")
      @second = stub(:id => "5")
      @related = [@first, @second]
      @parent = Person.new
      @options = Mongoid::Associations::Options.new(:name => :posts)
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::RelatesToMany.update(@related, @parent, @options)
      @parent.posts_ids.should == ["4", "5"]
    end

  end

end
