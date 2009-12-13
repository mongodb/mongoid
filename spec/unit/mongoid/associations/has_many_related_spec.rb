require "spec_helper"

describe Mongoid::Associations::HasManyRelated do

  let(:options) { Mongoid::Associations::Options.new(:name => :posts) }

  describe "#build" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Post.expects(:all).returns([])
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    it "adds a new object to the association" do
      @association.build(:title => "Sassy")
      @association.size.should == 1
    end

    it "sets the parent object id on the child" do
      @association.build(:title => "Sassy")
      @association.first.person_id.should == @parent.id
    end

    it "returns the new object" do
      @association.build(:title => "Sassy").should be_a_kind_of(Post)
    end

  end

  describe ".initialize" do

    context "when related id has been set" do

      before do
        @document = Person.new
        @criteria = stub
        @first = stub(:person_id => @document.id)
        @second = stub(:person_id => @document.id)
        @related = [@first, @second]
      end

      it "finds the object by id" do
        Post.expects(:all).with(:conditions => { "person_id" => @document.id }).returns(@related)
        association = Mongoid::Associations::HasManyRelated.new(@document, options)
        association.should == @related
      end

    end

  end

  describe ".instantiate" do

    context "when related id has been set" do

      before do
        @document = Person.new
      end

      it "delegates to new" do
        Mongoid::Associations::HasManyRelated.expects(:new).with(@document, options)
        association = Mongoid::Associations::HasManyRelated.instantiate(@document, options)
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
    end

    it "sets the related object id on the parent" do
      Mongoid::Associations::HasManyRelated.update(@related, @parent, options)
      @first.person_id.should == @parent.id
      @second.person_id.should == @parent.id
    end

    it "returns the related objects" do
      Mongoid::Associations::HasManyRelated.update(@related, @parent, options).should == @related
    end

  end

end
