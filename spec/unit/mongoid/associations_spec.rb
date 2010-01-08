require "spec_helper"

describe Mongoid::Associations do

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

  describe "#association=" do

    context "when child is a has one" do

      before do
        @person = Person.new(:title => "Sir", :age => 30)
        @name = Name.new(:first_name => "Test", :last_name => "User")
        @person.name = @name
      end

      it "parentizes the association" do
        @name._parent.should == @person
      end

      it "sets the child attributes on the parent" do
        @person.attributes[:name].should ==
          { "_id" => "test-user", "first_name" => "Test", "last_name" => "User", "_type" => "Name" }
      end

    end

    context "when child and parent are namespaced" do

      before do
        @patient = Medical::Patient.new(:name => "Ridley")
        @prescription = Medical::Prescription.new(:name => "Zoloft")
        @patient.prescriptions << @prescription
        @second = @patient.prescriptions.build(:name => "Codeine")
      end

      it "sets the correct association classes" do
        @patient.prescriptions.first.should == @prescription
        @patient.prescriptions.last.should == @second
      end

    end

    context "when setting a parent" do

      context "when the child is one level deep" do

        before do
          @person = Person.new(:title => "Mr")
          @address = Address.new(:street => "Picadilly Circus")
          @address.addressable = @person
        end

        it "re-parentizes the association" do
          @address._parent.should == @person
        end

        it "adds the child attributes to the parent" do
          @person.attributes[:addresses].should ==
            [{ "_id" => "picadilly-circus", "street" => "Picadilly Circus", "_type" => "Address" }]
        end

      end

      context "when the child is multiple levels deep" do

        before do
          @person = Person.new(:title => "Mr")
          @phone = Phone.new(:number => "415-555-1212")
          @person.phone_numbers = [@phone]
          @country_code = CountryCode.new(:code => 1)
          @phone.country_code = @country_code
        end

        it "properly decorates all parent references" do
          @country_code.phone_number.should == @phone
          @phone.person.should == @person
          @country_code.phone_number.person.should == @person
        end

      end

    end

  end

  describe ".belongs_to" do

    it "creates a reader for the association" do
      address = Address.new
      address.should respond_to(:addressable)
    end

    it "creates a writer for the association" do
      address = Address.new
      address.should respond_to(:addressable=)
    end

    it "allows the parent to be any type of class" do
      phone_number = Phone.new(:number => "415-555-1212")
      code = CountryCode.new(:code => 1)
      phone_number.country_code = code
      code.phone_number.should == phone_number
    end

    context "when inverse_of not supplied" do

      it "raises an error" do
        lambda { Person.class_eval { belongs_to :nothing } }.should raise_error
      end

    end

    context "when navigating the graph" do

      before do
        @person = Person.new(:title => "Mr")
        @name = Name.new(:first_name => "Mason")
        @address = Address.new(:street => "King St.")
        @person.name = @name
        @person.addresses << @address
      end

      it "allows referencing another child through the parent" do
        @name.person.addresses.first.should == @address
      end

    end

  end

  describe "#build_*" do

    before do
      @canvas = Canvas.new
    end

    context "when type is passed in" do

      before do
        @writer = @canvas.build_writer(:speed => 250, :_type => "HtmlWriter")
      end

      it "returns a new document" do
        @writer.should_not be_nil
      end

      it "returns the properly typed document" do
        @writer.should be_a_kind_of(HtmlWriter)
      end

      it "sets the appropriate attributes" do
        @writer.speed.should == 250
      end

    end

    context "when type is not passed in" do

      before do
        @writer = @canvas.build_writer(:speed => 250)
      end

      it "returns a new document" do
        @writer.should_not be_nil
      end

      it "returns the properly typed document" do
        @writer.should be_a_kind_of(Writer)
      end

      it "sets the appropriate attributes" do
        @writer.speed.should == 250
      end

    end

  end

  describe "#create_*" do

    before do
      @canvas = Canvas.new
    end

    context "when type is passed in" do

      before do
        Mongoid::Commands::Save.expects(:execute)
        @writer = @canvas.create_writer(:speed => 250, :_type => "HtmlWriter")
      end

      it "returns a new document" do
        @writer.should_not be_nil
      end

      it "returns the properly typed document" do
        @writer.should be_a_kind_of(HtmlWriter)
      end

      it "sets the appropriate attributes" do
        @writer.speed.should == 250
      end

    end

    context "when type is not passed in" do

      before do
        Mongoid::Commands::Save.expects(:execute)
        @writer = @canvas.create_writer(:speed => 250, :_type => "HtmlWriter")
      end

      it "returns a new document" do
        @writer.should_not be_nil
      end

      it "returns the properly typed document" do
        @writer.should be_a_kind_of(Writer)
      end

      it "sets the appropriate attributes" do
        @writer.speed.should == 250
      end

    end

  end

  describe ".has_many" do

    it "adds a new Association to the collection" do
      person = Person.new
      person.addresses.should_not be_nil
    end

    it "creates a reader for the association" do
      person = Person.new
      person.should respond_to(:addresses)
    end

    it "creates a writer for the association" do
      person = Person.new
      person.should respond_to(:addresses=)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :addresses => [
            { :street => "Street 1" },
            { :street => "Street 2" } ] }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        address = Address.new(:street => "New Street")
        @person.addresses = [address]
        @person.addresses.first.street.should == "New Street"
      end

    end

    context "when a class_name is supplied" do

      before do
        @attributes = { :title => "Sir",
          :phone_numbers => [ { :number => "404-555-1212" } ]
        }
        @person = Person.new(@attributes)
      end

      it "sets the association name" do
        @person.phone_numbers.first.should == Phone.new(:number => "404-555-1212")
      end

    end

    context "when updating objects internally" do

      before do
        @address = Address.new(:street => "Bourke Street")
        @person = Person.new(:title => "Sir")
        @person.addresses << @address
        @person.update_addresses
      end

      it "retains its references to the original objects" do
        @address.street.should == "Updated Address"
      end

    end

  end

  describe ".has_one" do

    before do
      @person = Person.new
    end

    it "adds a new Association to the document" do
      @person.name.should be_nil
    end

    it "creates a reader for the association" do
      @person.should respond_to(:name)
    end

    it "creates a writer for the association" do
      @person.should respond_to(:name=)
    end

    it "creates a builder for the association" do
      @person.should respond_to(:build_name)
    end

    it "creates a creator for the association" do
      @person.should respond_to(:create_name)
    end

    context "when setting the association directly" do

      before do
        @attributes = { :title => "Sir",
          :name => { :first_name => "Test" } }
        @person = Person.new(@attributes)
      end

      it "sets the attributes for the association" do
        name = Name.new(:first_name => "New Name")
        @person.name = name
        @person.name.first_name.should == "New Name"
      end

    end

    context "when a class_name is supplied" do

      before do
        @attributes = { :title => "Sir",
          :pet => { :name => "Fido" }
        }
        @person = Person.new(@attributes)
      end

      it "sets the association name" do
        @person.pet.should == Animal.new(:name => "Fido")
      end

    end

  end

  describe ".reflect_on_association" do

    it "returns the association class for the name" do
      Person.reflect_on_association(:addresses).should == :has_many
    end

  end

  describe ".belongs_to_related" do

    before do
      @game = Game.new
    end

    it "creates an id field for the relationship" do
      @game.should respond_to(:person_id)
    end

    it "creates a getter for the parent" do
      @game.should respond_to(:person)
    end

  end

  describe ".has_one_related" do

    before do
      @person = Person.new
    end

    it "creates a getter for the relationship" do
      @person.should respond_to(:game)
    end

    it "creates a setter for the relationship" do
      @person.should respond_to(:game=)
    end

  end

  describe ".has_many_related" do

    it "creates a getter and setter for the relationship" do
      Person.new.should respond_to(:posts)
      Person.new.should respond_to(:posts=)
    end

  end

  describe "#update_associations" do

    context "when associations exist" do

      before do
        @related = stub(:id => "100", :person= => true)
        @person = Person.new
        @person.posts = [@related]
      end

      it "saves each association" do
        @related.expects(:save).returns(@related)
        @person.update_associations(:posts)
      end

    end

    context "when no associations exist" do

      before do
        @person = Person.new
      end

      it "does nothing" do
        Post.expects(:find).returns([])
        @person.update_associations(:posts)
        @person.posts.first.should be_nil
      end

    end

  end

  describe "#update_association" do

    context "when the association exists" do

      before do
        @related = stub(:id => "100", :person= => true)
        @person = Person.new
        @person.game = @related
      end

      it "saves each association" do
        @related.expects(:save).returns(@related)
        @person.update_association(:game)
      end

    end

  end

end
