require "spec_helper"

describe Mongoid::Document do

  before do
    @database = mock
    @collection = stub(:name => "people")
    @canvas_collection = stub(:name => "canvases")
    Person.stubs(:collection).returns(@collection)
    Canvas.stubs(:collection).returns(@canvas_collection)
    @collection.stubs(:create_index).with(:_type, false)
    @canvas_collection.stubs(:create_index).with(:_type, false)
  end

  it "does not respond to _destroy" do
    Person.new.should_not respond_to(:_destroy)
  end

  describe "#==" do

    context "when other object is a Document" do

      context "when attributes are equal" do

        before do
          @document = Person.new(:_id => 1, :title => "Sir")
          @other = Person.new(:_id => 1, :title => "Sir")
        end

        it "returns true" do
          @document.should == @other
        end
      end

      context "when attributes are not equal" do

        before do
          @document = Person.new(:title => "Sir")
          @other = Person.new(:title => "Madam")
        end

        it "returns false" do
          @document.should_not == @other
        end
      end
    end

    context "when other object is not a Document" do

      it "returns false" do
        Person.new.==("Test").should be_false
      end
    end

    context "when comapring parent to its subclass" do

      it "returns false" do
        Canvas.new.should_not == Firefox.new
      end
    end
  end

  describe "#eql?" do

    context "when other object is a Document" do

      context "when attributes are equal" do

        before do
          @document = Person.new(:_id => 1, :title => "Sir")
          @other = Person.new(:_id => 1, :title => "Sir")
        end

        it "returns true" do
          @document.eql?(@other).should be_true
        end
      end

      context "when attributes are not equal" do

        before do
          @document = Person.new(:title => "Sir")
          @other = Person.new(:title => "Madam")
        end

        it "returns false" do
          @document.eql?(@other).should_not be_true
        end
      end
    end

    context "when other object is not a Document" do

      it "returns false" do
        Person.new.eql?("Test").should be_false
      end
    end

    context "when comapring parent to its subclass" do

      it "returns false" do
        Canvas.new.eql?(Firefox.new).should_not be_true
      end
    end
  end

  describe "#hash" do

    before do
      @document = Person.new(:_id => 1, :title => "Sir")
      @other = Person.new(:_id => 2, :title => "Sir")
    end

    it "deligates to id" do
      @document.hash.should == @document.id.hash
    end

    it "has unique hash per id" do
      @document.hash.should_not == @other.hash
    end
  end

  describe "#alias_method_chain" do

    context "on a field setter" do

      before do
        @person = Person.new
      end

      it "chains the method properly" do
        @person.score = 10
        @person.rescored.should == 30
      end
    end
  end

  describe ".attr_accessor" do

    context "on a root document" do

      let(:person) do
        Person.new
      end

      before do
        person.mode = "testing"
      end

      it "allows access to the instance variable" do
        person.mode.should == "testing"
      end
    end

    context "on an embedded document" do

      let(:address) do
        Address.new
      end

      before do
        address.mode = "test"
      end

      it "allows access to the instance variable" do
        address.mode.should == "test"
      end
    end
  end

  describe ".db" do

    before do
      @db = stub
      @collection.expects(:db).returns(@db)
    end

    it "returns the database from the collection" do
      Person.db.should == @db
    end
  end

  describe "#clone" do

    before do
      @comment = Comment.new(:text => "Woooooo")
      @clone = @comment.clone
    end

    it "returns a new document sans id and versions" do
      @clone.id.should_not == @comment.id
      @clone.versions.should be_empty
    end

  end

  describe ".embedded" do

    context "when the document is embedded" do

      it "returns true" do
        address = Address.new
        address.embedded.should be_true
      end

    end

    context "when the document is not embedded" do

      it "returns false" do
        person = Person.new
        person.embedded.should be_false
      end

    end

    context "when a subclass is embedded" do

      it "returns true" do
        circle = Circle.new
        circle.embedded.should be_true
      end

    end

  end

  describe ".hereditary?" do

    context "when the class is the root of a hierarchy" do

      it "returns false" do
        Canvas.should_not be_hereditary
      end

    end

    context "when the class is a part of a hierarchy" do

      it "returns true" do
        Browser.should be_hereditary
      end

    end

    context "when the class is not part of a hierarchy" do

      it "returns false" do
        Game.should_not be_hereditary
      end

    end

  end

  describe ".human_name" do

    it "returns the class name underscored and humanized" do
      MixedDrink.model_name.human.should == "Mixed drink"
    end

  end

  describe ".initialize" do

    context "when passed a block" do

      it "yields self to the block" do
        person = Person.new do |p|
          p.title = "Sir"
          p.age = 60
        end
        person.title.should == "Sir"
        person.age.should == 60
      end

    end

    context "with no attributes" do

      it "sets default attributes" do
        person = Person.new
        person.attributes.empty?.should be_false
        person.age.should == 100
        person.blood_alcohol_content.should == 0.0
      end

    end

    context "with nil attributes" do

      before do
        @person = Person.new(nil)
      end

      it "sets default attributes" do
        @person.attributes.empty?.should be_false
        @person.age.should == 100
        @person.blood_alcohol_content.should == 0.0
      end

    end

    context "with attributes from another document" do

      let(:person) do
        Person.new(Person.new.attributes)
      end

      it "is a new record with a new id" do
        person.new_record?.should be_true
      end
    end

    context "with attributes" do

      before do
        @attributes = {
          :_id => "1",
          :title => "value",
          :age => "30",
          :terms => "true",
          :name => {
            :_id => "2", :first_name => "Test", :last_name => "User"
          },
          :addresses => [
            { :_id => "3", :street => "First Street" },
            { :_id => "4", :street => "Second Street" }
          ]
        }
      end

      it "sets the attributes hash on the object properly casted" do
        person = Person.new(@attributes)
        person.attributes[:age].should == 30
        person.attributes[:terms].should be_true
      end

      it "is a new record" do
        Person.new(@attributes).new_record?.should == true
      end
    end

    context "with a primary key" do

      context "when the value for the key exists" do

        before do
          Address.key :street
          @address = Address.new(:street => "Test")
        end

        it "sets the primary key" do
          @address.id.should == "test"
        end
      end
    end

    context "without a type specified" do

      it "sets the type" do
        Doctor.new._type.should == "Doctor"
      end
    end
  end

  describe ".instantiate" do

    context "when attributes have an id" do

      before do
        @attributes = { "_id" => "1", "_type" => "Person", "title" => "Sir", "age" => 30 }
      end

      it "sets the attributes directly" do
        person = Person.instantiate(@attributes)
        person._id.should == "1"
        person._type.should == "Person"
        person.title.should == "Sir"
        person.age.should == 30
      end

    end

    context "with nil attributes" do

      it "sets the attributes directly" do
        person = Person.instantiate(nil)
        person.id.should_not be_nil
      end

    end

  end

  describe "#_parent" do

    before do
      @attributes = { :title => "Sir",
        :addresses => [
          { :street => "Street 1" },
          { :street => "Street 2" } ] }
      @person = Person.new(@attributes)
    end

    context "when document is embedded" do

      it "returns the parent document" do
        @person.addresses.first._parent.should == @person
      end

    end

    context "when document is root" do

      it "returns nil" do
        @person._parent.should be_nil
      end

    end

  end

  describe "#parentize" do

    before do
      @parent = Person.new
      @child = Name.new
    end

    it "sets the parent on each element" do
      @child.parentize(@parent)
      @child._parent.should == @parent
    end

  end

  describe "#reload" do

    before do
      @attributes = { "title" => "Herr" }
      @person = Person.new(:_id => BSON::ObjectId.new.to_s)
      @collection.expects(:find_one).with(:_id => @person.id).returns(@attributes)
    end

    it "reloads the object attribtues from the database" do
      @person.reload
      @person.attributes.should == @attributes
    end

    it 'should return a person object' do
      @person.reload.should be_kind_of(Person)
    end

  end

  describe "#_root" do

    before do
      @person = Person.new(:title => "Mr")
      @phone_number = Phone.new(:number => "415-555-1212")
      @country_code = CountryCode.new(:code => 1)
      @phone_number.country_code = @country_code
      @person.phone_numbers << @phone_number
    end

    context "when document is the root" do

      it "returns self" do
        @person._root.should == @person
      end
    end

    context "when document is embedded one level" do

      it "returns the parent" do
        @phone_number._root.should == @person
      end
    end

    context "when document is embedded multiple levels" do

      it "returns the top level parent" do
        @country_code._root.should == @person
      end
    end
  end

  describe "._types" do

    it "returns all subclasses for the class plus the class" do
      types = Canvas._types
      types.size.should == 3
      types.should include("Firefox")
      types.should include("Browser")
      types.should include("Canvas")
    end

    it "does not return parent classes" do
      types = Browser._types
      types.size.should == 2
      types.should include("Firefox")
      types.should include("Browser")
    end

    it 'should return strings' do
      types = Canvas._types
      types.each do |type|
        type.should be_an_instance_of String
      end
    end

  end

  describe "#to_a" do

    it "returns an array with the document in it" do
      person = Person.new
      person.to_a.should == [ person ]
    end

  end

  describe "#to_key" do

    context "when the document is new" do

      before do
        @person = Person.new
      end

      it "returns nil" do
        @person.to_key.should be_nil
      end
    end

    context "when the document is not new" do

      before do
        @id = BSON::ObjectId.new.to_s
        @person = Person.instantiate("_id" => @id)
      end

      it "returns the id in an array" do
        @person.to_key.should == [ @id ]
      end
    end
  end

  describe "#to_param" do

    it "returns the id" do
      id = BSON::ObjectId.new.to_s
      Person.instantiate("_id" => id).to_param.should == id.to_s
    end

  end
end
