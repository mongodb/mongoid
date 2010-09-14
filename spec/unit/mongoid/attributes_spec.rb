require "spec_helper"

describe Mongoid::Attributes do

  describe "#[]" do

    context "when attribute does not exist" do

      before do
        @person = Person.new
      end

      it "returns the default value" do
        @person[:age].should == 100
        @person[:pets].should == false
      end
    end

    context "when attribute is not accessible" do

      before do
        @person = Person.new
        @person.owner_id = 5
      end

      it "returns the value" do
        @person[:owner_id].should == 5
      end
    end
  end

  describe "#[]=" do

    context "when setting the attribute to nil" do

      before do
        @person = Person.new
      end

      it "does not use the default value" do
        @person[:age] = nil
        @person.age.should be_nil
      end
    end

    context "when field has a default value" do

      before do
        @person = Person.new
      end

      it "should allow overwriting of the default value" do
        @person[:terms] = true
        @person.terms.should be_true
      end
    end
  end

  describe ".accepts_nested_attributes_for" do

    before do
      @person = Person.new
    end

    it "adds a setter for the association attributes" do
      @person.should respond_to(:addresses_attributes=)
    end

    describe "#association_attributes=" do

      context "on a embeds many association" do

        context "when a reject block supplied" do

          before do
            @attributes = {
              "0" => { "city" => "San Francisco" }
            }
            @person.addresses_attributes = @attributes
          end

          it "removes the attributes that match" do
            @person.addresses.should be_empty
          end

        end

        context "when association is empty" do

          before do
            @attributes = {
              "0" => { "street" => "Folsom", "city" => "San Francisco" }
            }
            @person.addresses_attributes = @attributes
          end

          it "adds a new document to the association" do
            pending
            address = @person.addresses.first
            address.street.should == "Folsom"
            address.city.should == "San Francisco"
          end

        end

        context "when association is not empty" do

          before do
            @person = Person.new
            @person.addresses.build(:street => "Broadway", :city => "New York")
            @attributes = {
              "0" => { "street" => "Folsom", "city" => "San Francisco" }
            }
            @person.addresses_attributes = @attributes
          end

          it "updates the existing attributes on the association" do
            @person.addresses.size.should == 1
          end

        end

        context "when :allow_destroy is enabled" do
          before do
            @person = Person.new(:title => "Sir", :ssn => "555-66-9999")
            @person.favorites.build(:title => "Ice Cream")
            @person.favorites.build(:title => "Jello")
            @person.favorites.build(:title => "Ducce de Lecce")
            @attributes = {
              "0" => { "_destroy" => "true" },
              "1" => { "_destroy" => "true" }
            }
            @person.favorites_attributes = @attributes
          end

          it "removes the items that have _destroy => true set" do
            pending
            @person.favorites.class.should == Array
            @person.favorites.size.should == 1
            @person.favorites.first.title.should == "Ducce de Lecce"
          end
        end

        context "when :limit is set to 5" do
          before do
            @person = Person.new
          end

          it "allows adding 5 favorites" do
            pending
            @attributes = {
              "0" => { "title" => "Ice Cream" },
              "1" => { "title" => "Jello" },
              "2" => { "title" => "Sorbet" },
              "3" => { "title" => "Cake" },
              "4" => { "title" => "Tim Tams" }
            }
            @person.favorites_attributes = @attributes
            @person.favorites.size.should == 5
          end

          it "it raises exception when adding more than 5 favorites" do
            @attributes = {
              "0" => { "title" => "Ice Cream" },
              "1" => { "title" => "Jello" },
              "2" => { "title" => "Sorbet" },
              "3" => { "title" => "Cake" },
              "4" => { "title" => "Tim Tams" },
              "5" => { "title" => "Milo" }
            }
            lambda { @person.favorites_attributes = @attributes }.should
              raise_error(Mongoid::Errors::TooManyNestedAttributeRecords)
          end
        end

      end

      context "on a has one association" do

        before do
          @person = Person.new
        end

        it "can be added if :update_only is false" do
          @person.pet_attributes = { "name" => "Darwin" }
          @person.pet.name.should == "Darwin"
        end

        it "can be updated if :update_only is false" do
          @person.pet_attributes = { "name" => "Darwin" }
          @person.pet_attributes = { "name" => "Zulu" }
          @person.pet.name.should == "Zulu"
        end

        it "can not be added if :update_only is true" do
          pending
          @person.name_attributes = { "first_name" => "Fernando", "last_name" => "Torres" }
          @person.name.should be_blank
        end

        it "can be updated if :update_only is true" do
          @person = Person.new(:name => { "first_name" => "Marco", "last_name" => "Polo" })
          @person.name_attributes = { "first_name" => "Fernando", "last_name" => "Torres" }
          @person.name.first_name.should == "Fernando"
          @person.name.last_name.should == "Torres"
        end
      end
    end
  end

  describe ".attr_accessible" do

    context "when the field is not _id" do

      before do
        @account = Account.new(:balance => 999999)
      end

      it "prevents setting via mass assignment" do
        @account.balance.should be_nil
      end
    end

    context "when the field is _id" do

      before do
        @account = Account.new(:_id => "ABBA")
      end

      it "prevents setting via mass assignment" do
        @account._id.should_not == "ABBA"
      end
    end

    context "when using instantiate" do

      before do
        @account = Account.instantiate("_id" => "1", "balance" => "ABBA")
      end

      it "ignores any protected attribute" do
        @account.balance.should == "ABBA"
      end
    end
  end

  describe ".attr_protected" do

    context "when the field is not _id" do

      before do
        @person = Person.new(:security_code => "ABBA")
      end

      it "prevents setting via mass assignment" do
        @person.security_code.should be_nil
      end
    end

    context "when the field is _id" do

      before do
        @game = Game.new(:_id => "ABBA")
      end

      it "prevents setting via mass assignment" do
        @game._id.should_not == "ABBA"
      end
    end

    context "when using instantiate" do

      before do
        @person = Person.instantiate("_id" => "1", "security_code" => "ABBA")
      end

      it "ignores any protected attribute" do
        @person.security_code.should == "ABBA"
      end
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

  describe "#_id=" do

    before do
      @person = Person.new
    end

    it "delegates to #id=" do
      @id = BSON::ObjectId.new.to_s
      @person._id = @id
      @person.id.should == @id
    end

  end

  describe "#method_missing" do

    before do
      Mongoid.configure.allow_dynamic_fields = true
      @attributes = {
        :testing => "Testing"
      }
      @person = Person.new(@attributes)
    end

    context "when an attribute exists" do

      it "allows the getter" do
        @person.testing.should == "Testing"
      end

      it "allows the setter" do
        @person.testing = "Test"
        @person.testing.should == "Test"
      end

      it "returns true for respond_to?" do
        @person.respond_to?(:testing).should == true
      end
    end

  end

  describe "#process" do

    context "when passing non accessible fields" do

      before do
        @person = Person.new(:owner_id => 6)
      end

      it "does not set the value" do
        @person.owner_id.should be_nil
      end
    end

    context "when attributes dont have fields defined" do

      before do
        @attributes = {
          :nofieldstring => "Testing",
          :nofieldint => 5,
          :employer => Employer.new
        }
      end

      context "when allowing dynamic fields" do

        before do
          Mongoid.configure.allow_dynamic_fields = true
          @person = Person.new(@attributes)
        end

        context "when attribute is a string" do

          it "adds the string to the attributes" do
            @person.attributes[:nofieldstring].should == "Testing"
          end

        end

        context "when attribute is not a string" do

          it "adds a cast value to the attributes" do
            @person.attributes[:nofieldint].should == 5
          end

        end

      end

      context "when not allowing dynamic fields" do

        before do
          Mongoid.configure.allow_dynamic_fields = false
          Person.fields.delete(:nofieldstring)
          @attributes = {
            :nofieldstring => "Testing"
          }
        end

        after do
          Mongoid.configure.allow_dynamic_fields = true
        end

        it "raises an error" do
          lambda { Person.new(@attributes) }.should raise_error
        end

      end

    end

    context "when supplied hash has values" do

      before do
        @attributes = {
          :_id => "1",
          :title => "value",
          :age => "30",
          :terms => "true",
          :score => "",
          :name => {
            :_id => "2", :first_name => "Test", :last_name => "User"
          },
          :addresses => [
            { :_id => "3", :street => "First Street" },
            { :_id => "4", :street => "Second Street" }
          ]
        }
      end

      it "returns properly cast attributes" do
        attrs = Person.new(@attributes).attributes
        attrs[:age].should == 30
        attrs[:terms].should == true
        attrs[:_id].should == "1"
        attrs[:score].should be_nil
      end

    end

    context "when associations provided in the attributes" do

      context "when association is a has_one" do

        before do
          @name = Name.new(:first_name => "Testy")
          @attributes = {
            :name => @name
          }
          @person = Person.new(@attributes)
        end

        it "sets the associations" do
          @person.name.should == @name
        end

      end

      context "when association is a references_one" do

        before do
          @game = Game.new(:score => 100)
          @attributes = {
            :game => @game
          }
          @person = Person.new(@attributes)
        end

        it "sets the associations" do
          @person.game.should == @game
          @game.person.should == @person
        end

      end

      context "when association is a embedded_in" do

        before do
          @person = Person.new
          @name = Name.new(:first_name => "Tyler", :person => @person)
        end

        it "sets the association" do
          @name.person.should == @person
        end

      end

    end

    context "when non-associations provided in the attributes" do

      before do
        @employer = Employer.new
        @attributes = { :employer_id => @employer.id, :title => "Sir" }
        @person = Person.new(@attributes)
      end

      it "calls the setter for the association" do
        @person.employer_id.should == "1"
      end

    end

    context "when an empty array is provided in the attributes" do

      before do
        @attributes = {
          :aliases => []
        }
        @person = Person.new(@attributes)
      end

      it "sets the empty array" do
        @person.aliases.should == []
      end

    end

    context "when an empty hash is provided in the attributes" do

      before do
        @attributes = {
          :map => {}
        }
        @person = Person.new(@attributes)
      end

      it "sets the empty hash" do
        @person.map.should == {}
      end

    end

  end

  context "updating when attributes already exist" do

    before do
      @person = Person.new(:title => "Sir")
      @attributes = { :dob => "2000-01-01" }
    end

    it "only overwrites supplied attributes" do
      @person.process(@attributes)
      @person.title.should == "Sir"
    end

  end

  describe "#read_attribute" do

    context "when attribute does not exist" do

      before do
        @person = Person.new
      end

      it "returns the default value" do
        @person.age.should == 100
        @person.pets.should == false
      end

    end

    context "when attribute is not accessible" do

      before do
        @person = Person.new
        @person.owner_id = 5
      end

      it "returns the value" do
        @person.read_attribute(:owner_id).should == 5
      end
    end
  end

  describe "#attribute_present?" do
    context "when attribute does not exist" do
      before do
        @person = Person.new
      end

      it "returns false" do
        @person.attribute_present?(:owner_id).should be_false
      end
    end

    context "when attribute does exist" do
      before do
        @person = Person.new
        @person.owner_id = 5
      end

      it "returns true" do
        @person.attribute_present?(:owner_id).should be_true
      end
    end
  end

  describe "#remove_attribute" do

    context "when the attribute exists" do

      it "removes the attribute" do
        person = Person.new(:title => "Sir")
        person.remove_attribute(:title)
        person.title.should be_nil
      end

    end

    context "when the attribute does not exist" do

      it "does nothing" do
        person = Person.new
        person.remove_attribute(:title)
        person.title.should be_nil
      end

    end

  end

  describe "#write_attribute" do

    context "when attribute does not exist" do

      before do
        @person = Person.new
      end

      it "returns the default value" do
        @person.age.should == 100
      end
    end

    context "when setting the attribute to nil" do

      before do
        @person = Person.new(:age => nil)
      end

      it "does not use the default value" do
        @person.age.should be_nil
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

  describe "#typed_value_for" do

    let(:person) { Person.new }

    context "when the key has been specified as a field" do

      before { person.stubs(:fields).returns({"age" => Integer}) }

      it "retuns the typed value" do
        person.fields["age"].expects(:set).with("51")
        person.send(:typed_value_for, "age", "51")
      end

    end

    context "when the key has not been specified as a field" do

      before { person.stubs(:fields).returns({}) }

      it "returns the value" do
        person.send(:typed_value_for, "age", "51").should == "51"
      end

    end

  end

  describe "#default_attributes" do

    let(:person) { Person.new }

    it "typecasts proc values" do
      person.stubs(:defaults).returns("age" => lambda { "51" })
      person.expects(:typed_value_for).with("age", "51")
      person.send(:default_attributes)
    end

  end

  [:attributes=, :write_attributes].each do |method|
    describe "##{method}" do

      context "typecasting" do

        before do
          @person = Person.new
          @attributes = { :age => "50" }
        end

        it "properly casts values" do
          @person.send(method, @attributes)
          @person.age.should == 50
        end

        it "allows passing of nil" do
          @person.send(method, nil)
          @person.age.should == 100
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
            @owner.send(method, { :pet => { :name => "Bingo" } })
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
            @name.send(method, :first_name => "Test2", :last_name => "User2")
            @name.attributes.should ==
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
            @address.send(method, "street" => "Test2")
            @address.attributes.should ==
              { "_id" => "test", "street" => "Test2" }
          end

        end

      end
    end

  end

end
