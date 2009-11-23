require File.expand_path(File.join(File.dirname(__FILE__), "/../../spec_helper.rb"))

describe Mongoid::Document do

  before do
    @collection = stub(:name => "people")
    @database = stub(:collection => @collection)
    Mongoid.stubs(:database).returns(@database)
  end

  after do
    Person.instance_variable_set(:@collection, nil)
    @database = nil
    @collection = nil
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

      it "returns nil" do
        Address.collection.should be_nil
      end

    end

  end

  describe ".defaults" do

    it "returns a hash of all the default values" do
      Game.defaults.should == { "high_score" => 500, "score" => 0 }
    end

  end

  describe "#defaults" do

    before do
      @game = Game.new
    end

    it "returns the class defaults" do
      @game.defaults.should == { "high_score" => 500, "score" => 0 }
    end

  end

  describe ".embedded?" do

    context "when the document is embedded" do

      it "returns true" do
        Address.embedded?.should be_true
      end

    end

    context "when the document is not embedded" do

      it "returns false" do
        Person.embedded?.should be_false
      end

    end

  end

  describe "#embedded?" do

    context "when the document is embedded" do

      it "returns true" do
        address = Address.new
        address.embedded?.should be_true
      end

    end

    context "when the document is not embedded" do

      it "returns false" do
        person = Person.new
        person.embedded?.should be_false
      end

    end

  end

  describe ".field" do

    context "with no options" do

      before do
        Person.field(:testing)
      end

      it "adds a reader for the fields defined" do
        @person = Person.new(:testing => "Test")
        @person.testing.should == "Test"
      end

      it "adds a writer for the fields defined" do
        @person = Person.new(:testing => "Test")
        @person.testing = "Testy"
        @person.testing.should == "Testy"
      end

    end

    context "when type is an object" do

      before do
        @person = Person.new
        @drink = MixedDrink.new(:name => "Jack and Coke")
        @person.mixed_drink = @drink
      end

      it "allows proper access to the object" do
        @person.mixed_drink.should == @drink
        @person.attributes[:mixed_drink].except(:_id).should == { "name" => "Jack and Coke" }
      end

    end

  end

  describe ".human_name" do

    it "returns the class name underscored and humanized" do
      MixedDrink.human_name.should == "Mixed drink"
    end

  end

  describe "#_id" do

    before do
      @person = Person.new
    end

    it "delegates to #id" do
      @person._id.should == @person.id
    end

  end

  describe ".index" do

    context "when unique options are not provided" do

      it "delegates to collection with unique => false" do
        @collection.expects(:create_index).with(:title, :unique => false)
        Person.index :title
      end

    end

    context "when unique option is provided" do

      it "delegates to collection with unique option" do
        @collection.expects(:create_index).with(:title, :unique => true)
        Person.index :title, :unique => true
      end

    end

  end

  describe ".instantiate" do

    context "when document is new" do

      before do
        @attributes = { :_id => "1", :title => "Sir", :age => 30 }
        @person = Person.new(@attributes)
      end

      it "sets the attributes directly" do
        Person.instantiate(@attributes).should == @person
      end

    end

    context "when document is not new" do

      before do
        @attributes = { :title => "Sir", :age => 30 }
        @person = Person.new(@attributes)
      end

      it "instantiates normally" do
        Person.instantiate(@attributes).id.should_not be_nil
      end

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

  end

  describe "#new" do

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

  describe "#parent" do

    before do
      @attributes = { :title => "Sir",
        :addresses => [
          { :street => "Street 1" },
          { :street => "Street 2" } ] }
      @person = Person.new(@attributes)
    end

    context "when document is embedded" do

      it "returns the parent document" do
        @person.addresses.first.parent.should == @person
      end

    end

    context "when document is root" do

      it "returns nil" do
        @person.parent.should be_nil
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
      @child.parent.should == @parent
    end

  end

  describe "#read_attribute" do

    context "when attribute does not exist" do

      before do
        @person = Person.new
      end

      it "returns the default value" do
        @person.age.should == 100
      end

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

  describe "#root" do

    before do
      @person = Person.new(:title => "Mr")
      @phone_number = Phone.new(:number => "415-555-1212")
      @country_code = CountryCode.new(:code => 1)
      @phone_number.country_code = @country_code
      @person.phone_numbers << @phone_number
    end

    context "when document is the root" do

      it "returns self" do
        @person.root.should == @person
      end

    end

    context "when document is embedded one level" do

      it "returns the parent" do
        @phone_number.root.should == @person
      end

    end

    context "when document is embedded multiple levels" do

      it "returns the top level parent" do
        @country_code.root.should == @person
      end

    end

  end

  describe "#to_param" do

    it "returns the id" do
      id = Mongo::ObjectID.new.to_s
      Person.new(:_id => id).to_param.should == id.to_s
    end

  end

  describe "#write_attribute" do

    context "when attribute does not exist" do

      before do
        @person = Person.new
      end

      it "returns the default value" do
        @person.age = nil
        @person.age.should == 100
      end

    end

    context "when field has a default value" do

      before do
        @person = Person.new
      end

      it "should allow overwriting of the default value" do
        @person.terms = true
        @person.terms.should be_true
      end

    end

  end

  describe "#write_attributes" do

    context "typecasting" do

      before do
        @person = Person.new
        @attributes = { :age => "50" }
      end

      it "properly casts values" do
        @person.write_attributes(@attributes)
        @person.age.should == 50
      end

    end

    context "on a parent document" do

      context "when the parent has a has many through a has one" do

        before do
          @owner = PetOwner.new(:title => "Mr")
          @pet = Pet.new(:name => "Fido")
          @owner.pet = @pet
          @vet_visit = VetVisit.new(:date => Date.today)
          @pet.vet_visits = [@vet_visit]
        end

        it "does not overwrite child attributes if not in the hash" do
          @owner.write_attributes({ :pet => { :name => "Bingo" } })
          @owner.pet.name.should == "Bingo"
          @owner.pet.vet_visits.size.should == 1
        end

      end

    end

    context "on a child document" do

      context "when child is part of a has one" do

        before do
          @person = Person.new(:title => "Sir", :age => 30)
          @name = Name.new(:first_name => "Test", :last_name => "User")
          @person.name = @name
        end

        it "sets the child attributes on the parent" do
          @name.write_attributes(:first_name => "Test2", :last_name => "User2")
          @person.attributes[:name].should ==
            { "_id" => "test-user", "first_name" => "Test2", "last_name" => "User2" }
        end

      end

      context "when child is part of a has many" do

        before do
          @person = Person.new(:title => "Sir")
          @address = Address.new(:street => "Test")
          @person.addresses << @address
        end

        it "updates the child attributes on the parent" do
          @address.write_attributes("street" => "Test2")
          @person.attributes[:addresses].should ==
            [ { "_id" => "test", "street" => "Test2" } ]
        end

      end

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
      end

      after do
        Person.validations.clear
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

        it "fails if the field is nil" do
          Person.class_eval do
            validates_presence_of :title
          end
          @person.valid?.should be_false
          @person.errors.on(:title).should_not be_nil
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
