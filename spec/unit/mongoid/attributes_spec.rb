require "spec_helper"

describe Mongoid::Attributes do

  describe "\#{attribute}" do

    context "when setting the value in the getter" do

      let(:account) do
        Account.new
      end

      it "does not cause an infinite loop" do
        account.overridden.should eq("not recommended")
      end
    end
  end

  describe "#[]" do

    context "when the document is a new record" do

      let(:person) do
        Person.new
      end

      context "when attribute does not exist" do

        it "returns the default value" do
          person[:age].should == 100
        end
      end

      context "when attribute is not accessible" do

        before do
          person.owner_id = 5
        end

        it "returns the value" do
          person[:owner_id].should == 5
        end
      end
    end

    context "when the document is an existing record" do

      let(:person) do
        Person.create(:ssn => "123-11-4412")
      end

      context "when the attribute does not exist" do

        before do
          person.collection.update({:_id => person.id}, {'$unset' => {:age => 1}})
        end

        context "when found" do

          let(:found) do
            Person.find(person.id)
          end

          it "returns the default value" do
            found[:age].should == 100
          end
        end

        context "when reloaded" do

          before do
            Mongoid.raise_not_found_error = false
            person.reload
            Mongoid.raise_not_found_error = true
          end

          it "returns the default value" do
            person[:age].should == 100
          end
        end
      end
    end
  end

  describe "#[]=" do

    let(:person) do
      Person.new
    end

    context "when setting the attribute to nil" do

      before do
        person[:age] = nil
      end

      it "does not use the default value" do
        person.age.should be_nil
      end
    end

    context "when field has a default value" do

      before do
        person[:terms] = true
      end

      it "should allow overwriting of the default value" do
        person.terms.should be_true
      end
    end
  end

  describe ".attr_accessible" do

    context "when the field is not _id" do

      let(:account) do
        Account.new(:number => 999999)
      end

      it "prevents setting via mass assignment" do
        account.number.should be_nil
      end
    end

    context "when the field is _id" do

      let(:account) do
        Account.new(:_id => "ABBA")
      end

      it "prevents setting via mass assignment" do
        account._id.should_not == "ABBA"
      end
    end

    context "when using instantiate" do

      let(:account) do
        Account.instantiate("_id" => "1", "balance" => "ABBA")
      end

      it "ignores any protected attribute" do
        account.balance.should == "ABBA"
      end
    end

    context "when using override" do
      let(:account) do
        Account.new
      end

      it "ignores any protected attribute" do
        account.write_attributes({:balance => "ABBA"}, false)
        account.balance.should == "ABBA"
      end
    end
  end

  describe ".attr_protected" do

    context "when the field is not _id" do

      let(:person) do
        Person.new(:security_code => "ABBA")
      end

      it "prevents setting via mass assignment" do
        person.security_code.should be_nil
      end
    end

    context "when the field is _id" do

      let(:game) do
        Game.new(:_id => "ABBA")
      end

      it "prevents setting via mass assignment" do
        game._id.should_not == "ABBA"
      end
    end

    context "when using instantiate" do

      let(:person) do
        Person.instantiate("_id" => "1", "security_code" => "ABBA")
      end

      it "ignores any protected attribute" do
        person.security_code.should == "ABBA"
      end
    end

    context "when using override" do
      let(:person) do
        Person.new
      end

      it "ignores any protected attribute" do
        person.write_attributes({:security_code => "ABBA"}, false)
        person.security_code.should == "ABBA"
      end
    end
  end

  describe "#_id" do

    let(:person) do
      Person.new
    end

    it "delegates to #id" do
      person._id.should == person.id
    end
  end

  describe "#_id=" do

    after(:all) do
      Person.identity :type => BSON::ObjectId
    end

    context "when using object ids" do

      before(:all) do
        Person.identity :type => BSON::ObjectId
      end

      let(:person) do
        Person.new
      end

      let(:bson_id) do
        BSON::ObjectId.new
      end

      context "when providing an object id" do

        before do
          person._id = bson_id
        end

        it "sets the id as the object id" do
          person.id.should == bson_id
        end
      end

      context "when providing a string" do

        before do
          person._id = bson_id.to_s
        end

        it "sets the id as the object id" do
          person.id.should == bson_id
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value to_s" do
          person.id.should == 2
        end
      end
    end

    context "when using string ids" do

      before(:all) do
        Person.identity :type => String
      end

      let(:person) do
        Person.new
      end

      let(:bson_id) do
        BSON::ObjectId.new
      end

      context "when providing an object id" do

        before do
          person._id = bson_id
        end

        it "sets the id as the string of the object id" do
          person.id.should == bson_id.to_s
        end
      end

      context "when providing a string" do

        before do
          person._id = bson_id.to_s
        end

        it "sets the id as the string" do
          person.id.should == bson_id.to_s
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value to_s" do
          person.id.should == "2"
        end
      end
    end

    context "when using integer ids" do

      before(:all) do
        Person.identity :type => Integer
      end

      let(:person) do
        Person.new
      end

      context "when providing a string" do

        before do
          person._id = 1.to_s
        end

        it "sets the id as the integer" do
          person.id.should == 1
        end
      end

      context "when providing an integer" do

        before do
          person._id = 2
        end

        it "sets the id as the supplied value" do
          person.id.should == 2
        end
      end
    end
  end

  describe "#method_missing" do

    let(:attributes) do
      { :testing => "Testing" }
    end

    let(:person) do
      Person.new(attributes)
    end

    before do
      Mongoid.configure.allow_dynamic_fields = true
    end

    context "when an attribute exists" do

      it "allows the getter" do
        person.testing.should == "Testing"
      end

      it "allows the setter" do
        person.testing = "Test"
        person.testing.should == "Test"
      end

      it "returns true for respond_to?" do
        person.respond_to?(:testing).should == true
      end
    end
  end

  describe "#process" do

    context "when passing non accessible fields" do

      let(:person) do
        Person.new(:owner_id => 6)
      end

      it "does not set the value" do
        person.owner_id.should be_nil
      end
    end

    context "when attributes dont have fields defined" do

      let(:attributes) do
        {
          :nofieldstring => "Testing",
          :nofieldint => 5,
          :employer => Employer.new
        }
      end

      context "when allowing dynamic fields" do

        let!(:person) do
          Person.new(attributes)
        end

        before do
          Mongoid.configure.allow_dynamic_fields = true
        end

        context "when attribute is a string" do

          it "adds the string to the attributes" do
            person.attributes["nofieldstring"].should == "Testing"
          end
        end

        context "when attribute is not a string" do

          it "adds a cast value to the attributes" do
            person.attributes["nofieldint"].should == 5
          end
        end
      end

      context "when not allowing dynamic fields" do

        let!(:attributes) do
          { :nofieldstring => "Testing" }
        end

        before do
          Mongoid.configure.allow_dynamic_fields = false
          Person.fields.delete(:nofieldstring)
        end

        after do
          Mongoid.configure.allow_dynamic_fields = true
        end

        it "raises an error" do
          lambda { Person.new({ :anothernew => "Test" }) }.should raise_error
        end
      end
    end

    context "when supplied hash has string values" do

      let(:bson_id) do
        BSON::ObjectId.new
      end

      let!(:attributes) do
        {
          :_id => bson_id,
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

      let!(:person) do
        Person.new(attributes)
      end

      it "casts integers" do
        person[:age].should == 30
      end

      it "casts booleans" do
        person[:terms].should == true
      end

      it "casts ids" do
        person[:_id].should == bson_id
      end

      it "sets empty strings to nil" do
        person[:score].should be_nil
      end
    end

    context "when associations provided in the attributes" do

      context "when association is a has_one" do

        let(:name) do
          Name.new(:first_name => "Testy")
        end

        let(:attributes) do
          { :name => name }
        end

        let(:person) do
          Person.new(attributes)
        end

        it "sets the associations" do
          person.name.should eq(name)
        end
      end

      context "when association is a references_one" do

        let(:game) do
          Game.new(:score => 100)
        end

        let(:attributes) do
          { :game => game }
        end

        let!(:person) do
          Person.new(attributes)
        end

        it "sets the parent association" do
          person.game.should == game
        end

        it "sets the inverse association" do
          game.person.should == person
        end
      end

      context "when association is a embedded_in" do

        let(:person) do
          Person.new
        end

        let(:name) do
          Name.new(:first_name => "Tyler", :person => person)
        end

        it "sets the association" do
          name.person.should == person
        end
      end
    end

    context "when non-associations provided in the attributes" do

      let(:employer) do
        Employer.new
      end

      let(:attributes) do
        { :employer_id => employer.id, :title => "Sir" }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "calls the setter for the association" do
        person.employer_id.should == "1"
      end
    end

    context "when an empty array is provided in the attributes" do

      let(:attributes) do
        { :aliases => [] }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "sets the empty array" do
        person.aliases.should == []
      end
    end

    context "when an empty hash is provided in the attributes" do

      let(:attributes) do
        { :map => {} }
      end

      let(:person) do
        Person.new(attributes)
      end

      it "sets the empty hash" do
        person.map.should == {}
      end
    end
  end

  context "updating when attributes already exist" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    let(:attributes) do
      { :dob => "2000-01-01" }
    end

    before do
      person.process(attributes)
    end

    it "only overwrites supplied attributes" do
      person.title.should == "Sir"
    end
  end

  describe "#read_attribute" do

    context "when the document is a new record" do

      let(:person) do
        Person.new
      end

      context "when attribute does not exist" do

        it "returns the default value" do
          person.age.should == 100
          person.pets.should == false
        end

      end

      context "when attribute is not accessible" do

        before do
          person.owner_id = 5
        end

        it "returns the value" do
          person.read_attribute(:owner_id).should == 5
        end
      end
    end

    context "when the document is an existing record" do

      let(:person) do
        Person.create
      end

      context "when the attribute does not exist" do

        before do
          person.collection.update({:_id => person.id}, {'$unset' => {:age => 1}})
          Mongoid.raise_not_found_error = false
          person.reload
          Mongoid.raise_not_found_error = true
        end

        it "returns the default value" do
          person.age.should == 100
        end
      end
    end
  end

  [ :attribute_present?, :has_attribute? ].each do |method|

    describe "##{method}" do

      context "when document is a new record" do

        let(:person) do
          Person.new
        end

        context "when attribute does not exist" do
          it "returns false" do
            person.send(method, :owner_id).should be_false
          end
        end

        context "when attribute does exist" do
          before do
            person.owner_id = 5
          end

          it "returns true" do
            person.send(method, :owner_id).should be_true
          end
        end
      end

      context "when the document is an existing record" do

        let(:person) do
          Person.create
        end

        context "when the attribute does not exist" do

          before do
            person.collection.update({:_id => person.id}, {'$unset' => {:age => 1}})
            Mongoid.raise_not_found_error = false
            person.reload
            Mongoid.raise_not_found_error = true
          end

          it "returns true" do
            person.send(method, :age).should be_true
          end
        end
      end

      context "when the value is boolean" do
        let(:person) do
          Person.new
        end

        context "when attribute does not exist" do
          context "when the value is true" do

            it "return true"  do
              person.terms = false
              person.send(method, :terms).should be_true
            end
          end

          context "when the value is false" do
            it "return true"  do
              person.terms = false
              person.send(method, :terms).should be_true
            end
          end
        end
      end

      context "when the value is blank string" do
        let(:person) do
          Person.new(:title => '')
        end

        it "return false" do
          person.send(method, :title).should be_false
        end
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

      let(:person) do
        Person.new
      end

      it "returns the default value" do
        person.age.should == 100
      end
    end

    context "when setting the attribute to nil" do

      let(:person) do
        Person.new(:age => nil)
      end

      it "does not use the default value" do
        person.age.should be_nil
      end
    end

    context "when field has a default value" do

      let(:person) do
        Person.new
      end

      before do
        person.terms = true
      end

      it "should allow overwriting of the default value" do
        person.terms.should be_true
      end
    end
  end

  describe "#typed_value_for" do

    let(:person) { Person.new }

    context "when the key has been specified as a field" do

      before do
        person.stubs(:fields).returns(
          { "age" => Mongoid::Fields::Serializable::Integer.instantiate(:age) }
        )
      end

      it "retuns the typed value" do
        person.fields["age"].expects(:serialize).with("51")
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

  describe "#apply_default_attributes" do

    let(:person) { Person.new }

    it "typecasts proc values" do
      person.age.should eq(100)
    end
  end

  [:attributes=, :write_attributes].each do |method|

    describe "##{method}" do

      context "when nested" do

        let(:person) do
          Person.new
        end

        before do
          person.send(method, { :videos => [{:title => "Fight Club"}] })
        end

        it "should set nested documents" do
          person.videos.first.title.should eq("Fight Club")
        end
      end

      context "typecasting" do

        let(:person) do
          Person.new
        end

        let(:attributes) do
          { :age => "50" }
        end

        context "when passing a hash" do

          before do
            person.send(method, attributes)
          end

          it "properly casts values" do
            person.age.should eq(50)
          end
        end

        context "when passing nil" do

          before do
            person.send(method, nil)
          end

          it "does not set anything" do
            person.age.should eq(100)
          end
        end
      end

      context "on a parent document" do

        context "when the parent has a has many through a has one" do

          let(:owner) do
            PetOwner.new(:title => "Mr")
          end

          let(:pet) do
            Pet.new(:name => "Fido")
          end

          let(:vet_visit) do
            VetVisit.new(:date => Date.today)
          end

          before do
            owner.pet = pet
            pet.vet_visits = [ vet_visit ]
            owner.send(method, { :pet => { :name => "Bingo" } })
          end

          it "does not overwrite child attributes if not in the hash" do
            owner.pet.name.should == "Bingo"
            owner.pet.vet_visits.size.should == 1
          end
        end

        context "when the parent has an empty embeds_many" do

          let(:person) do
            Person.new
          end

          let(:attributes) do
            { :services => [] }
          end

          it "does not raise an error" do
            person.send(method, attributes)
          end
        end
      end

      context "on a child document" do

        context "when child is part of a has one" do

          let(:person) do
            Person.new(:title => "Sir", :age => 30)
          end

          let(:name) do
            Name.new(:first_name => "Test", :last_name => "User")
          end

          before do
            person.name = name
            name.send(method, :first_name => "Test2", :last_name => "User2")
          end

          it "sets the child attributes on the parent" do
            name.attributes.should ==
              { "_id" => "test-user", "first_name" => "Test2", "last_name" => "User2" }
          end
        end

        context "when child is part of a has many" do

          let(:person) do
            Person.new(:title => "Sir")
          end

          let(:address) do
            Address.new(:street => "Test")
          end

          before do
            person.addresses << address
            address.send(method, "street" => "Test2")
          end

          it "updates the child attributes on the parent" do
            address.attributes.should ==
              { "_id" => "test", "street" => "Test2" }
          end
        end
      end
    end
  end

  describe "#alias_attribute" do

    let(:product) do
      Product.new
    end

    context "when checking against the alias" do

      before do
        product.cost = 500
      end

      it "aliases the getter" do
        product.cost.should eq(500)
      end

      it "aliases the existance check" do
        product.cost?.should be_true
      end

      it "aliases *_changed?" do
        product.cost_changed?.should be_true
      end

      it "aliases *_change" do
        product.cost_change.should eq([ nil, 500 ])
      end

      it "aliases *_will_change!" do
        product.should respond_to(:cost_will_change!)
      end

      it "aliases *_was" do
        product.cost_was.should be_nil
      end

      it "aliases reset_*!" do
        product.reset_cost!
        product.cost.should be_nil
      end
    end

    context "when checking against the original" do

      before do
        product.price = 500
      end

      it "aliases the getter" do
        product.price.should eq(500)
      end

      it "aliases the existance check" do
        product.price?.should be_true
      end

      it "aliases *_changed?" do
        product.price_changed?.should be_true
      end

      it "aliases *_change" do
        product.price_change.should eq([ nil, 500 ])
      end

      it "aliases *_will_change!" do
        product.should respond_to(:price_will_change!)
      end

      it "aliases *_was" do
        product.price_was.should be_nil
      end

      it "aliases reset_*!" do
        product.reset_price!
        product.price.should be_nil
      end
    end
  end
end
