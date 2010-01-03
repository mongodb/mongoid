require "spec_helper"

describe Mongoid::Associations::HasManyRelated do

  let(:options) { Mongoid::Associations::Options.new(:name => :posts) }

  describe "#<<" do

    before do
      @child = stub
      @second = stub
      @children = [@child, @second]
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association << @child
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @association << @child
        @association.size.should == 1
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association << [@child, @second]
        @association.size.should == 2
      end

    end

  end

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
      @association.build(:title => "Sassy").title.should == "Sassy"
    end

    it "sets the parent object reference on the child" do
      @association.build(:title => "Sassy")
      @association.first.person.should == @parent
    end

  end

  describe "#concat" do

    before do
      @child = stub
      @second = stub
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association.concat(@child)
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @association.concat(@child)
        @association.size.should == 1
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association.concat([@child, @second])
        @association.size.should == 2
      end

    end

  end

  describe "#create" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Post.expects(:all).returns([])
      Mongoid::Commands::Save.expects(:execute)
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    it "builds and saves the new object" do
      @association.create(:title => "Sassy")
    end

    it "returns the new object" do
      @association.create(:title => "Sassy").should be_a_kind_of(Post)
    end

  end

  describe "#find" do

    before do
      @parent = stub(:id => "5", :class => Person)
      Post.expects(:all).returns([])
      @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
    end

    context "when finding by id" do

      before do
        @post = stub
      end

      it "returns the document in the array with that id" do
        Post.expects(:find).with("5").returns(@post)
        post = @association.find("5")
        post.should == @post
      end

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

    it "returns :has_many_related" do
      Mongoid::Associations::HasManyRelated.macro.should == :has_many_related
    end

  end

  describe "#push" do

    before do
      @child = stub
      @second = stub
    end

    context "when parent document has been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => false, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "saves and appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @child.expects(:save).returns(true)
        @association.push(@child)
        @association.size.should == 1
      end

    end

    context "when parent document has not been saved" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child document" do
        @child.expects(:person_id=).with(@parent.id)
        @association.push(@child)
        @association.size.should == 1
      end

    end

    context "with multiple objects" do

      before do
        @parent = stub(:id => "1", :new_record? => true, :class => Person)
        Post.expects(:all).returns([])
        @association = Mongoid::Associations::HasManyRelated.new(@parent, options)
      end

      it "appends the child documents" do
        @child.expects(:person_id=).with(@parent.id)
        @second.expects(:person_id=).with(@parent.id)
        @association.push(@child, @second)
        @association.size.should == 2
      end

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
