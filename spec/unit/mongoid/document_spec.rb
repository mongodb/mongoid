require "spec_helper"

describe Mongoid::Document do

  before do
    @database = mock
    Mongoid.stubs(:database).returns(@database)
    @collection = stub(:name => "people")
    @canvas_collection = stub(:name => "canvases")
    @database.stubs(:collection).with("people").returns(@collection)
    @database.stubs(:collection).with("canvases").returns(@canvas_collection)
    @collection.stubs(:create_index).with(:_type, false)
    @canvas_collection.stubs(:create_index).with(:_type, false)
  end

  after do
    Person._collection = nil
    Canvas._collection = nil
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

  describe "#assimilate" do

    before do
      @child = Name.new(:first_name => "Hank", :last_name => "Moody")
      @parent = Person.new(:title => "Mr.")
      @options = Mongoid::Associations::Options.new(:name => :name)
    end

    it "sets up all associations in the object graph" do
      @child.assimilate(@parent, @options)
      @parent.name.should == @child
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

  describe ".collection" do

    before do
      @person = Person.new
    end

    it "sets the collection name to the class pluralized" do
      Person.collection.name.should == "people"
    end

    context "when document is embedded" do

      before do
        @address = Address.new
      end

      it "raises an error" do
        lambda { Address.collection }.should raise_error
      end

    end

  end

  describe ".collection_name=" do

    context "on a parent class" do

      it "sets the collection name on the document class" do
        Patient.collection_name = "pats"
        Patient.collection_name.should == "pats"
      end

    end

    context "on a subclass" do

      after do
        Canvas.collection_name = "canvases"
      end

      it "sets the collection name for the entire hierarchy" do
        Firefox.collection_name = "browsers"
        Canvas.collection_name.should == "browsers"
      end

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

  describe ".hereditary" do

    context "when the class is part of a hierarchy" do

      it "returns true" do
        Canvas.hereditary.should be_true
      end

    end

    context "when the class is not part of a hierarchy" do

      it "returns false" do
        Game.hereditary.should be_false
      end

    end

  end

  describe ".human_name" do

    it "returns the class name underscored and humanized" do
      MixedDrink.human_name.should == "Mixed drink"
    end

  end

  describe ".instantiate" do

    before do
      @attributes = { :_id => "1", :_type => "Person", :title => "Sir", :age => 30 }
      @person = Person.new(@attributes)
    end

    it "sets the attributes directly" do
      Person.instantiate(@attributes).should == @person
    end

  end

  describe ".key" do

    context "when key is single field" do

      before do
        Address.key :street
        @address = Address.new(:street => "Testing Street Name")
        @address.expects(:collection).returns(@collection)
        @collection.expects(:save)
      end

      it "adds the callback for primary key generation" do
        @address.save
        @address.id.should == "testing-street-name"
      end

    end

    context "when key is composite" do

      before do
        Address.key :street, :post_code
        @address = Address.new(:street => "Testing Street Name", :post_code => "94123")
        @address.expects(:collection).returns(@collection)
        @collection.expects(:save)
      end

      it "combines all fields" do
        @address.save
        @address.id.should == "testing-street-name-94123"
      end

    end

    context "when key is on a subclass" do

      before do
        Firefox.key :name
      end

      it "sets the key for the entire hierarchy" do
        Canvas.primary_key.should == [:name]
      end

    end

  end

  describe "#new" do

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
        Person.new._type.should == "Person"
      end

    end

  end

  describe "#new_record?" do

    context "when the object has been saved" do

      before do
        @person = Person.new(:_id => "1")
      end

      it "returns false" do
        @person.new_record?.should be_false
      end

    end

    context "when the object has not been saved" do

      before do
        @person = Person.new
      end

      it "returns true" do
        @person.new_record?.should be_true
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
      @child.parentize(@parent, :child)
      @child._parent.should == @parent
    end

  end

  describe "#reload" do

    before do
      @attributes = { "title" => "Herr" }
      @person = Person.new(:_id => Mongo::ObjectID.new.to_s)
      @collection.expects(:find_one).with(:_id => @person.id).returns(@attributes)
    end

    it "reloads the object attribtues from the database" do
      @person.reload
      @person.attributes.should == @attributes
    end

  end

  describe "#remove" do

    context "when removing an element from a has many" do

      before do
        @person = Person.new
        @address = Address.new(:street => "Testing")
        @person.addresses << @address
      end

      it "removes the child document attributes" do
        @person.remove(@address)
        @person.addresses.size.should == 0
      end

    end

    context "when removing a has one" do

      before do
        @person = Person.new
        @name = Name.new(:first_name => "Neytiri")
        @person.name = @name
      end

      it "removes the child document attributes" do
        @person.remove(@name)
        @person.name.should be_nil
      end

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

  describe ".store_in" do

    context "on a parent class" do

      it "sets the collection name and collection for the document" do
        @database.expects(:collection).with("population").returns(@collection)
        Patient.store_in :population
        Patient.collection_name.should == "population"
      end

    end

    context "on a subclass" do

      after do
        Firefox.store_in :canvases
      end

      it "changes the collection name for the entire hierarchy" do
        @database.expects(:collection).with("browsers").returns(@collection)
        Firefox.store_in :browsers
        Canvas.collection_name.should == "browsers"
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

  end

  describe "#to_a" do

    it "returns an array with the document in it" do
      person = Person.new
      person.to_a.should == [ person ]
    end

  end

  describe "#to_param" do

    it "returns the id" do
      id = Mongo::ObjectID.new.to_s
      Person.new(:_id => id).to_param.should == id.to_s
    end

  end

  context "validations" do

    context "when defining using macros" do

      after do
        Person.validations.clear
      end

      describe "#validates_acceptance_of" do

        it "adds the acceptance validation" do
          Person.class_eval do
            validates_acceptance_of :terms
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesAcceptanceOf)
        end

      end

      describe "#validates_associated" do

        it "adds the associated validation" do
          Person.class_eval do
            validates_associated :name
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesAssociated)
        end

      end

      describe "#validates_format_of" do

        it "adds the format validation" do
          Person.class_eval do
            validates_format_of :title, :with => /[A-Za-z]/
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesFormatOf)
        end

      end

      describe "#validates_length_of" do

        it "adds the length validation" do
          Person.class_eval do
            validates_length_of :title, :minimum => 10
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesLengthOf)
        end

      end

      describe "#validates_numericality_of" do

        it "adds the numericality validation" do
          Person.class_eval do
            validates_numericality_of :age
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesNumericalityOf)
        end

      end

      describe "#validates_presence_of" do

        it "adds the presence validation" do
          Person.class_eval do
            validates_presence_of :title
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesPresenceOf)
        end

      end

      describe "#validates_uniqueness_of" do

        it "adds the uniqueness validation" do
          Person.class_eval do
            validates_uniqueness_of :title
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesUniquenessOf)
        end

      end

      describe "#validates_inclusion_of" do

        it "adds the inclusion validation" do
          Person.class_eval do
            validates_inclusion_of :title, :within => ["test"]
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesInclusionOf)
        end

      end

      describe "#validates_exclusion_of" do

        it "adds the exclusion validation" do
          Person.class_eval do
            validates_exclusion_of :title, :within => ["test"]
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesExclusionOf)
        end

      end

      describe "#validates_true_for" do

        it "adds the true validation" do
          Person.class_eval do
            validates_true_for :title, :logic => lambda { title == "Esquire" }
          end
          Person.validations.first.should be_a_kind_of(Validatable::ValidatesTrueFor)
        end

      end

    end

    context "when running validations" do

      before do
        @person = Person.new
        @canvas = Canvas.new
        @firefox = Firefox.new
      end

      after do
        Person.validations.clear
        Canvas.validations.clear
        Firefox.validations.clear
      end

      describe "#validates_acceptance_of" do

        it "fails if field not accepted" do
          Person.class_eval do
            validates_acceptance_of :terms
          end
          @person.valid?.should be_false
          @person.errors.on(:terms).should_not be_nil
        end

      end

      describe "#validates_associated" do

        context "when association is a has_many" do

          it "fails when any association fails validation" do
            Person.class_eval do
              validates_associated :addresses
            end
            Address.class_eval do
              validates_presence_of :street
            end
            @person.addresses << Address.new
            @person.valid?.should be_false
            @person.errors.on(:addresses).should_not be_nil
          end

        end

        context "when association is a has_one" do

          context "when the associated is not nil" do

            it "fails when the association fails validation" do
              Person.class_eval do
                validates_associated :name
              end
              Name.class_eval do
                validates_presence_of :first_name
              end
              @person.name = Name.new
              @person.valid?.should be_false
              @person.errors.on(:name).should_not be_nil
            end

          end

          context "when the associated is nil" do

            it "returns true" do
              Person.class_eval do
                validates_associated :name
              end
              @person.valid?.should be_true
            end

          end

        end

      end

      describe "#validates_format_of" do

        it "fails if the field is in the wrong format" do
          Person.class_eval do
            validates_format_of :title, :with => /[A-Za-z]/
          end
          @person.title = 10
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

      describe "#validates_length_of" do

        it "fails if the field is the wrong length" do
          Person.class_eval do
            validates_length_of :title, :minimum => 10
          end
          @person.title = "Testing"
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

      describe "#validates_numericality_of" do

        it "fails if the field is not a number" do
          Person.class_eval do
            validates_numericality_of :age
          end
          @person.age = "foo"
          @person.valid?.should be_false
          @person.errors.on(:age).should_not be_nil
        end

      end

      describe "#validates_presence_of" do

        context "on a parent class" do

          it "fails if the field is nil on the parent" do
            Person.class_eval do
              validates_presence_of :title
            end
            @person.valid?.should be_false
            @person.errors.on(:title).should_not be_nil
          end

          it "fails if the field is nil on a subclass" do
            Canvas.class_eval do
              validates_presence_of :name
            end
            @firefox.valid?.should be_false
            @firefox.errors.on(:name).should_not be_nil
          end

        end

        context "on a subclass" do

          it "parent class does not get subclass validations" do
            Firefox.class_eval do
              validates_presence_of :name
            end
            @canvas.valid?.should be_true
          end

        end

      end

      describe "#validates_true_for" do

        it "fails if the logic returns false" do
          Person.class_eval do
            validates_true_for :title, :logic => lambda { title == "Esquire" }
          end
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
        end

      end

    end

  end

end
