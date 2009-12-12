require "spec_helper"

describe Mongoid::Associations::HasManyRelated do

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
        association = Mongoid::Associations::HasManyRelated.new(@document, @options)
        association.should == @related
      end

    end

  end

  describe ".instantiate" do

    context "when related id has been set" do

      before do
        @document = Person.new
        @options = Mongoid::Associations::Options.new(:name => :posts)
      end

      it "delegates to new" do
        Mongoid::Associations::HasManyRelated.expects(:new).with(@document, @options)
        association = Mongoid::Associations::HasManyRelated.instantiate(@document, @options)
      end

    end

  end

  describe ".macro" do

    it "returns :relates_to_many" do
      Mongoid::Associations::HasManyRelated.macro.should == :relates_to_many
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
      Mongoid::Associations::HasManyRelated.update(@related, @parent, @options)
      @first.person_id.should == @parent.id
      @second.person_id.should == @parent.id
    end

    it "returns the related objects" do
      Mongoid::Associations::HasManyRelated.update(@related, @parent, @options).should == @related
    end

  end

end
