require "spec_helper"

# describe Mongoid::Associations do

  # before do
    # @collection = stub(:name => "people")
    # @database = stub(:collection => @collection)
    # Mongoid.stubs(:database).returns(@database)
    # Mongoid.autocreate_indexes = true
  # end

  # after do
    # Mongoid.autocreate_indexes = false
  # end

  # describe "#association=" do

    # context "when child is a has one" do

      # before do
        # @person = Person.new(:title => "Sir", :age => 30)
        # @name = Name.new(:first_name => "Test", :last_name => "User")
        # @person.name = @name
      # end

      # it "parentizes the association" do
        # @name._parent.should == @person
      # end

      # it "sets the child attributes on the parent" do
        # @person.attributes[:name].should ==
          # { "_id" => "test-user", "first_name" => "Test", "last_name" => "User" }
      # end

      # context "when child is nil" do

        # it "makes the association nil" do
          # @person.game.should be_nil
        # end

        # it "makes the association false" do
          # (!!@person.game).should == false
        # end
      # end
    # end

    # context "when child and parent are namespaced" do

      # before do
        # @patient = Medical::Patient.new(:name => "Ridley")
        # @prescription = Medical::Prescription.new(:name => "Zoloft")
        # @patient.prescriptions << @prescription
        # @second = @patient.prescriptions.build(:name => "Codeine")
      # end

      # it "sets the correct association classes" do
        # @patient.prescriptions.first.should == @prescription
        # @patient.prescriptions.last.should == @second
      # end

    # end

    # context "when setting a parent" do

      # context "when the child is one level deep" do

        # before do
          # @person = Person.new(:title => "Mr")
          # @address = Address.new(:street => "Picadilly Circus")
          # @address.addressable = @person
        # end

        # it "re-parentizes the association" do
          # @address._parent.should == @person
        # end

        # it "adds the child attributes to the parent" do
          # @person.attributes[:addresses].should ==
            # [{ "_id" => "picadilly-circus", "street" => "Picadilly Circus" }]
        # end

      # end

      # context "when the child is multiple levels deep" do

        # before do
          # @person = Person.new(:title => "Mr")
          # @phone = Phone.new(:number => "415-555-1212")
          # @person.phone_numbers = [@phone]
          # @country_code = CountryCode.new(:code => 1)
          # @phone.country_code = @country_code
        # end

        # it "properly decorates all parent references" do
          # @country_code.phone_number.should == @phone
          # @phone.person.should == @person
          # @country_code.phone_number.person.should == @person
        # end

      # end

    # end

  # end

  # describe "#associations" do

    # before do
      # @person = Person.new
    # end

    # it "is a hash with name keys and meta data values" do
      # @person.associations["addresses"].should be_a_kind_of(Mongoid::Associations::MetaData)
    # end
  # end

  # describe ".embedded?" do

    # context "when the class is embedded" do

      # it "returns true" do
        # Address.embedded?.should be_true
      # end
    # end

    # context "when the class is not embedded" do

      # it "returns false" do
        # Person.embedded?.should be_false
      # end
    # end
  # end

  # describe "#embedded?" do

    # context "when the class is embedded" do

      # it "returns true" do
        # Address.new.embedded?.should be_true
      # end
    # end

    # context "when the class is not embedded" do

      # it "returns false" do
        # Person.new.embedded?.should be_false
      # end
    # end
  # end

  # describe "#embedded_many?" do
    # context "when the class is embedded" do

      # context "within an embeds_many" do
        # it "returns true" do
          # Address.new(:addressable => Person.new).embedded_many?.should be_true
        # end
      # end

      # context "within an embeds_one" do
        # it "returns false" do
          # Name.new(:namable => Person.new).embedded_many?.should be_false
        # end
      # end
    # end

    # context "when the class is not embedded" do

      # it "returns false" do
        # Person.new.embedded_many?.should be_false
      # end
    # end

  # end

  # describe ".embedded_in" do

    # it "creates a reader for the association" do
      # address = Address.new
      # address.should respond_to(:addressable)
    # end

    # it "creates a writer for the association" do
      # address = Address.new
      # address.should respond_to(:addressable=)
    # end

    # it "allows the parent to be any type of class" do
      # phone_number = Phone.new(:number => "415-555-1212")
      # code = CountryCode.new(:code => 1)
      # phone_number.country_code = code
      # code.phone_number.should == phone_number
    # end

    # context "when adding an anonymous extension" do

      # before do
        # @person = Person.new(:title => "Dr")
        # @address = Address.new(:street => "Clarkenwell Road")
        # @person.addresses << @address
      # end

      # it "defines the method on the association" do
        # @address.addressable.extension.should == "Testing"
      # end

    # end

    # context "when inverse_of not supplied" do

      # it "raises an error" do
        # lambda { Person.class_eval { embedded_in :nothing } }.should raise_error
      # end

    # end

    # context "when navigating the graph" do

      # before do
        # @person = Person.new(:title => "Mr")
        # @name = Name.new(:first_name => "Mason")
        # @address = Address.new(:street => "King St.")
        # @person.name = @name
        # @person.addresses << @address
      # end

      # it "allows referencing another child through the parent" do
        # @name.namable.addresses.first.should == @address
      # end

    # end

  # end

  # describe "#build_*" do

    # context "embeds_one" do

      # before do
        # @canvas = Canvas.new
      # end

      # context "when type is passed in" do

        # before do
          # @writer = @canvas.build_writer(:speed => 250, :_type => "HtmlWriter")
        # end

        # it "returns a new document" do
          # @writer.should_not be_nil
        # end

        # it "returns the properly typed document" do
          # @writer.should be_a_kind_of(HtmlWriter)
        # end

        # it "sets the appropriate attributes" do
          # @writer.speed.should == 250
        # end

      # end

      # context "when type is not passed in" do

        # before do
          # @writer = @canvas.build_writer(:speed => 250)
        # end

        # it "returns a new document" do
          # @writer.should_not be_nil
        # end

        # it "returns the properly typed document" do
          # @writer.should be_a_kind_of(Writer)
        # end

        # it "sets the appropriate attributes" do
          # @writer.speed.should == 250
        # end

      # end

      # context "when attributes are nil" do

        # before do
          # @writer = @canvas.build_writer(nil)
        # end

        # it "defaults them to empty" do
          # @writer.should be_a_kind_of(Writer)
        # end

      # end

    # end

    # context "references_one" do

      # before do
        # @person = Person.new
        # @game = @person.build_game(:score => 100)
      # end

      # it "returns a new document" do
        # @game.should_not be_nil
      # end

      # it "returns the properly typed document" do
        # @game.should be_a_kind_of(Game)
      # end

      # it "sets the appropriate attributes" do
        # @game.score.should == 100
      # end

    # end

  # end

  # describe "#create_*" do

    # context "embeds_one" do

      # before do
        # @canvas = Canvas.new
      # end

      # context "when type is passed in" do

        # before do
          # @insert = stub
          # Mongoid::Persistence::Insert.expects(:new).returns(@insert)
          # @insert.expects(:persist).returns(HtmlWriter.new(:speed => 250))
          # @writer = @canvas.create_writer(:speed => 250, :_type => "HtmlWriter")
        # end

        # it "returns a new document" do
          # @writer.should_not be_nil
        # end

        # it "returns the properly typed document" do
          # @writer.should be_a_kind_of(HtmlWriter)
        # end

        # it "sets the appropriate attributes" do
          # @writer.speed.should == 250
        # end

      # end

      # context "when type is not passed in" do

        # before do
          # @insert = stub
          # Mongoid::Persistence::Insert.expects(:new).returns(@insert)
          # @insert.expects(:persist).returns(HtmlWriter.new(:speed => 250))
          # @writer = @canvas.create_writer(:speed => 250, :_type => "HtmlWriter")
        # end

        # it "returns a new document" do
          # @writer.should_not be_nil
        # end

        # it "returns the properly typed document" do
          # @writer.should be_a_kind_of(Writer)
        # end

        # it "sets the appropriate attributes" do
          # @writer.speed.should == 250
        # end

      # end

    # end

    # context "references_one" do

      # before do
        # @person = Person.new
        # @insert = stub
        # Mongoid::Persistence::Insert.expects(:new).returns(@insert)
        # @insert.expects(:persist).returns(Game.new(:score => 100))
        # @game = @person.create_game(:score => 100)
      # end

      # it "returns a new document" do
        # @game.should_not be_nil
      # end

      # it "returns the properly typed document" do
        # @game.should be_a_kind_of(Game)
      # end

      # it "sets the appropriate attributes" do
        # @game.score.should == 100
      # end

    # end

  # end

  # describe ".embeds_many" do

    # it "adds a new Association to the collection" do
      # person = Person.new
      # person.addresses.should_not be_nil
    # end

    # it "creates a reader for the association" do
      # person = Person.new
      # person.should respond_to(:addresses)
    # end

    # it "creates a writer for the association" do
      # person = Person.new
      # person.should respond_to(:addresses=)
    # end

    # context "when adding an anonymous extension" do

      # it "defines the method on the association" do
        # person = Person.new
        # person.addresses.extension.should == "Testing"
      # end

    # end

    # context "when setting the association directly" do

      # before do
        # @attributes = { :title => "Sir",
          # :addresses => [
            # { :street => "Street 1" },
            # { :street => "Street 2" } ] }
        # @person = Person.new(@attributes)
      # end

      # it "sets the attributes for the association" do
        # address = Address.new(:street => "New Street")
        # @person.addresses = [address]
        # @person.addresses.first.street.should == "New Street"
      # end

    # end

    # context "when a class_name is supplied" do

      # before do
        # @attributes = { :title => "Sir",
          # :phone_numbers => [ { :number => "404-555-1212" } ]
        # }
        # @person = Person.new(@attributes)
      # end

      # it "sets the association name" do
        # @person.phone_numbers.first.should == Phone.new(:number => "404-555-1212")
      # end

    # end

    # context "when updating objects internally" do

      # before do
        # @address = Address.new(:street => "Bourke Street")
        # @person = Person.new(:title => "Sir")
        # @person.addresses << @address
        # @person.update_addresses
      # end

      # it "retains its references to the original objects" do
        # @address.street.should == "Updated Address"
      # end

    # end

  # end

  # describe ".embeds_one" do

    # before do
      # @person = Person.new
    # end

    # it "adds a new Association to the document" do
      # @person.name.should be_nil
    # end

    # it "creates a reader for the association" do
      # @person.should respond_to(:name)
    # end

    # it "creates a writer for the association" do
      # @person.should respond_to(:name=)
    # end

    # it "creates a builder for the association" do
      # @person.should respond_to(:build_name)
    # end

    # it "creates a creator for the association" do
      # @person.should respond_to(:create_name)
    # end

    # context "when adding an anonymous extension" do

      # it "defines the method on the association" do
        # @person.name = Name.new(:first_name => "Richard")
        # @person.name.extension.should == "Testing"
      # end

    # end

    # context "when setting the association directly" do

      # before do
        # @attributes = { :title => "Sir",
          # :name => { :first_name => "Test" } }
        # @person = Person.new(@attributes)
      # end

      # it "sets the attributes for the association" do
        # name = Name.new(:first_name => "New Name")
        # @person.name = name
        # @person.name.first_name.should == "New Name"
      # end

    # end

    # context "when a class_name is supplied" do

      # before do
        # @attributes = { :title => "Sir",
          # :pet => { :name => "Fido" }
        # }
        # @person = Person.new(@attributes)
      # end

      # it "sets the association name" do
        # @person.pet.should == Animal.new(:name => "Fido")
      # end

    # end

  # end

  # describe ".reflect_on_association" do

    # it "returns the association meta data for the name" do
      # Person.reflect_on_association(:addresses).macro.should == :embeds_many
    # end

  # end

  # describe ".reflect_on_all_associations" do

    # it "returns all meta data for the supplied type" do
      # associations = Person.reflect_on_all_associations(:embeds_many)
      # associations.size.should == 4
    # end
  # end

  # describe ".referenced_in" do

    # before do
      # @game = Game.new
    # end

    # it "creates an id field for the relationship" do
      # @game.should respond_to(:person_id)
    # end

    # it "creates a getter for the parent" do
      # @game.should respond_to(:person)
    # end

    # it "defaults the foreign_key option to the name_id" do
      # @game.associations["person"].foreign_key.should == "person_id"
    # end

    # context "when document is root level" do

      # context "when index is not set" do

        # it "does not index the foreign_key" do
          # Post.collection.index_information["person_id_1"].should be_nil
        # end
      # end

      # context "when index is set" do

        # it "puts an index on the foreign key" do
          # Game.expects(:index).with("person_id", :background => true)
          # Game.referenced_in :person, :index => true
        # end
      # end
    # end

    # context "when using object ids" do
      # before :all do
        # @previous_id_type = Person._id_type
        # Person.identity :type => BSON::ObjectId
      # end

      # after :all do
        # Person.identity :type => @previous_id_type
      # end

      # it "sets the foreign key as an object id" do
        # Game.expects(:field).with(
          # "person_id",
          # :inverse_class_name => "Person",
          # :identity => true
        # )
        # Game.referenced_in :person
      # end
    # end
  # end

  # describe ".references_one" do

    # before do
      # @person = Person.new
      # @game = Game.new
      # @person.game = @game
    # end

    # it "creates a getter for the relationship" do
      # @person.should respond_to(:game)
    # end

    # it "creates a setter for the relationship" do
      # @person.should respond_to(:game=)
    # end

    # context "when adding an anonymous extension" do

      # it "defines the method on the association" do
        # @person.game.extension.should == "Testing"
      # end
    # end
  # end

  # describe ".references_many" do

    # it "creates a getter for the association" do
      # Person.new.should respond_to(:posts)
    # end

    # it "creates a setter for the association" do
      # Person.new.should respond_to(:posts=)
    # end

    # context "when adding an anonymous extension" do

      # before do
        # @person = Person.new
      # end

      # it "defines the method on the association" do
        # @person.posts.extension.should == "Testing"
      # end
    # end

    # context "with a stored_as option provided" do

      # context "when stored_as is :array" do

        # it "creates a getter for the association" do
          # Person.allocate.should respond_to(:preferences)
        # end

        # it "creates a setter for the association" do
          # Person.allocate.should respond_to(:preferences=)
        # end

        # it "sets the association as a references many as array" do
          # metadata = Person.associations["preferences"]
          # metadata.association.should == Mongoid::Associations::ReferencesManyAsArray
        # end

        # it "creates the association_ids field" do
          # Person.allocate.should respond_to(:preference_ids)
        # end

        # it "creates an array field with identity set to true" do
          # Person.fields["preference_ids"].options[:identity].should be_true
        # end

        # context "when index is set to true" do

          # it "adds an index on the association field" do
            # Person.collection.index_information["preference_ids_1"].should_not be_nil
          # end
        # end
      # end
    # end
  # end

  # describe "#update_foreign_keys" do

    # before do
      # Person.identity :type => BSON::ObjectId
      # @game = Game.new(:score => 1)
      # @person = Person.new(:title => "Sir", :game => @game)
    # end

    # it "updates blank foreign keys" do
      # @game.update_foreign_keys
      # @game.person_id.should == @person.id
    # end

  # end

  # describe "#update_associations" do

    # context "when associations exist" do

      # context "when the document is a new record" do

        # before do
          # @related = stub(:id => "100", :person= => true)
          # @person = Person.new
          # @person.posts = [@related]
        # end

        # it "saves each association" do
          # @related.expects(:save).returns(@related)
          # @person.update_associations(:posts)
        # end

      # end

      # context "when the document is not new" do

        # before do
          # @related = stub(:id => "100", :person= => true)
          # @person = Person.new
          # @person.instance_variable_set(:@new_record, false)
          # @person.posts = [@related]
        # end

        # it "does not save each association" do
          # @person.update_associations(:posts)
        # end

      # end

    # end

    # context "when no associations exist" do

      # before do
        # @person = Person.new
      # end

      # it "does nothing" do
        # Post.expects(:find).returns([])
        # @person.update_associations(:posts)
        # @person.posts.first.should be_nil
      # end

    # end

  # end

  # describe "#update_association" do

    # context "when the association exists" do

      # before do
        # @game = Game.new(:id => "100")
        # @person = Person.new
        # @person.game = @game
      # end

      # it "saves each association" do
        # @game.expects(:save).returns(@game)
        # @person.update_association(:game)
      # end

    # end

  # end

# end
