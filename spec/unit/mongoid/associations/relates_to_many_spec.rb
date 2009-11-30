require File.expand_path(File.join(File.dirname(__FILE__), "/../../../spec_helper.rb"))

describe Mongoid::Associations::RelatesToMany do

  describe ".initialize" do

    context "when related id has been set" do

      before do
        @document = Person.new
        @options = Mongoid::Associations::Options.new(:name => :posts)
        @criteria = stub
        @first = stub(:person_id => @document.id)
        @second = stub(:person_id => @document.id)
        @related = [@first, @second]
      end

      it "finds the object by id" do
        Post.expects(:all).with(:conditions => { "person_id" => @document.id }).returns(@related)
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
      @first = Post.new
      @second = Post.new
      @related = [@first, @second]
      @parent = Person.new
      @options = Mongoid::Associations::Options.new(:name => :posts)
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::RelatesToMany.update(@related, @parent, @options)
      @first.person_id.should == @parent.id
      @second.person_id.should == @parent.id
    end

  end

end
