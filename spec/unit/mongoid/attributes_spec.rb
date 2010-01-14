require "spec_helper"

describe Mongoid::Attributes do

  describe ".accepts_nested_attributes_for" do

    before do
      @person = Person.new
    end

    it "adds a setter for the association attributes" do
      @person.should respond_to(:addresses_attributes=)
    end

    describe "#association_attributes=" do

      context "on a has many association" do

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
            @person.addresses.size.should == 2
          end

        end

      end

      context "on a has one association" do

        before do
          @person = Person.new
          @attributes = {
            "first_name" => "Fernando", "last_name" => "Torres"
          }
          @person.name_attributes = @attributes
        end

        it "replaces the document on the association" do
          name = @person.name
          name.first_name.should == "Fernando"
          name.last_name.should == "Torres"
        end

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
      @id = Mongo::ObjectID.new.to_s
      @person._id = @id
      @person.id.should == @id
    end

  end

  describe "#method_missing" do

    before do
      Mongoid.allow_dynamic_fields = true
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

    end

  end

  describe "#process" do

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
          Mongoid.allow_dynamic_fields = true
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
          Mongoid.allow_dynamic_fields = false
          Person.fields.delete(:nofieldstring)
          @attributes = {
            :nofieldstring => "Testing"
          }
        end

        after do
          Mongoid.allow_dynamic_fields = true
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
        attrs[:score].should == ""
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

      context "when association is a belongs_to" do

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

      it "allows passing of nil" do
        @person.write_attributes(nil)
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
            { "_id" => "test-user", "first_name" => "Test2", "last_name" => "User2", "_type" => "Name" }
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
            [ { "_id" => "test", "street" => "Test2", "_type" => "Address" } ]
        end

      end

    end

  end

end
