require "spec_helper"

describe Mongoid::Persistence do

  before(:all) do
    Mongoid.persist_in_safe_mode = true
  end

  after(:all) do
    Mongoid.persist_in_safe_mode = false
  end

  describe ".create" do

    context "when providing attributes" do

      let(:person) do
        Person.create(title: "Sensei")
      end

      it "it saves the document" do
        person.should be_persisted
      end

      it "returns the document" do
        person.should be_a_kind_of(Person)
      end

      context "when creating an embedded document" do

        let(:address) do
          Address.create(addressable: person)
        end

        it "persists the document" do
          address.should be_persisted
        end
      end

      context "when creating an embedded document with store_as option" do

        let(:user) do
          User.create
        end

        before(:all) do
          User.embeds_many(
            :addresses,
            :class_name => "Address",
            store_as: "user_adresses",
            validate: false
          )
          Address.embedded_in :user
        end

        before do
          user.addresses.create!(:city => "nantes")
        end

        let(:document) do
          user.collection.find(:_id => user.id).first
        end

        it "should not persist in address key on User document" do
          document.keys.should_not include("addresses")
        end

        it "should persist on user_addesses key on User document" do
          document.keys.should include("user_adresses")
        end
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        person.ssn.should eq("666-66-6666")
      end

      it "persists the document" do
        person.should be_persisted
      end
    end

    context "when mass assignment role is indicated" do

      context "when attributes assigned from default role" do

        let(:item) do
          Item.create(
            title: "Some Title",
            is_rss: true,
            user_login: "SomeLogin"
          )
        end

        it "sets the field for the default role" do
          item.is_rss.should be_true
        end

        it "does not set the field for non default role title" do
          item.title.should be_nil
        end

        it "does not set the field for non default role user login" do
          item.user_login.should be_nil
        end
      end

      context "when attributes assigned from parser role" do

        let(:item) do
          Item.create(
            { title: "Some Title",
              is_rss: true,
              user_login: "SomeLogin" }, as: :parser
          )
        end

        it "sets the user login field for parser role" do
          item.user_login.should eq("SomeLogin")
        end

        it "sets the is rss field for parse role" do
          item.is_rss.should be_false
        end

        it "does not set the title field" do
          item.title.should be_nil
        end
      end

      context "when attributes assigned without protection" do

        let(:item) do
          Item.create(
            { title: "Some Title",
              is_rss: true,
              user_login: "SomeLogin"
            }, without_protection: true
          )
        end

        it "sets the title attribute" do
          item.title.should eq("Some Title")
        end

        it "sets the user login attribute" do
          item.user_login.should eq("SomeLogin")
        end

        it "sets the rss attribute" do
          item.is_rss.should be_true
        end
      end
    end
  end

  describe ".create!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        before do
          Person.create_indexes
        end

        let!(:person) do
          Person.create!(ssn: "555-55-9999")
        end

        it "raises an error" do
          expect {
            Person.create!(ssn: "555-55-9999")
          }.to raise_error
        end
      end
    end

    context "when passing in a block" do

      let(:person) do
        Person.create! do |peep|
          peep.ssn = "666-66-6666"
        end
      end

      it "sets the attributes" do
        person.ssn.should eq("666-66-6666")
      end

      it "persists the document" do
        person.should be_persisted
      end
    end

    context "when setting the composite key" do

      let(:account) do
        Account.create!(name: "Hello")
      end

      it "saves the document" do
        account.should be_persisted
      end
    end

    context "when a callback returns false" do

      it "raises a callback error" do
        expect { Oscar.create! }.to raise_error(Mongoid::Errors::Callback)
      end
    end

    context "when mass assignment role is indicated" do

      context "when attributes assigned from default role" do

        let(:item) do
          Item.create!(
            title: "Some Title",
            is_rss: true,
            user_login: "SomeLogin"
          )
        end

        it "sets the field for the default role" do
          item.is_rss.should be_true
        end

        it "does not set the field for non default role title" do
          item.title.should be_nil
        end

        it "does not set the field for non default role user login" do
          item.user_login.should be_nil
        end
      end

      context "when attributes assigned from parser role" do

        let(:item) do
          Item.create!(
            { title: "Some Title",
              is_rss: true,
              user_login: "SomeLogin" }, as: :parser
          )
        end

        it "sets the user login field for parser role" do
          item.user_login.should eq("SomeLogin")
        end

        it "sets the is rss field for parse role" do
          item.is_rss.should be_false
        end

        it "does not set the title field" do
          item.title.should be_nil
        end
      end

      context "when attributes assigned without protection" do

        let(:item) do
          Item.create!(
            { title: "Some Title",
              is_rss: true,
              user_login: "SomeLogin"
            }, without_protection: true
          )
        end

        it "sets the title attribute" do
          item.title.should eq("Some Title")
        end

        it "sets the user login attribute" do
          item.user_login.should eq("SomeLogin")
        end

        it "sets the rss attribute" do
          item.is_rss.should be_true
        end
      end
    end
  end

  [ :delete, :destroy ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create
      end

      context "when removing a root document" do

        let!(:deleted) do
          person.send(method)
        end

        it "deletes the document from the collection" do
          expect {
            Person.find(person.id)
          }.to raise_error
        end

        it "returns true" do
          deleted.should be_true
        end

        it "resets the flagged for destroy flag" do
          person.should_not be_flagged_for_destroy
        end
      end

      context "when removing an embedded document" do

        let(:address) do
          person.addresses.build(street: "Bond Street")
        end

        context "when the document is not yet saved" do

          before do
            address.send(method)
          end

          it "removes the document from the parent" do
            person.addresses.should be_empty
          end

          it "removes the attributes from the parent" do
            person.raw_attributes["addresses"].should be_nil
          end

          it "resets the flagged for destroy flag" do
            address.should_not be_flagged_for_destroy
          end
        end

        context "when the document has been saved" do

          before do
            address.save
            address.send(method)
          end

          let(:from_db) do
            Person.find(person.id)
          end

          it "removes the object from the parent and database" do
            from_db.addresses.should be_empty
          end
        end
      end

      context "when removing deeply embedded documents" do

        context "when the document has been saved" do

          let(:address) do
            person.addresses.create(street: "Bond Street")
          end

          let(:location) do
            address.locations.create(name: "Home")
          end

          let(:from_db) do
            Person.find(person.id)
          end

          before do
            location.send(method)
          end

          it "removes the object from the parent and database" do
            from_db.addresses.first.locations.should be_empty
          end

          it "resets the flagged for destroy flag" do
            location.should_not be_flagged_for_destroy
          end
        end
      end
    end
  end

  describe "#save" do

    let(:person) do
      Person.new
    end

    context "when the document has been instantiated with limited fields" do

      before do
        person.age = 20
        person.save
      end

      context "when a default is excluded" do

        let(:limited) do
          Person.only(:_id).find(person.id)
        end

        it "does not flag the excluded fields as dirty" do
          limited.changes.should be_empty
        end

        it "does not overwrite with the default" do
          limited.save
          limited.reload.age.should eq(20)
        end
      end

      context "when iterating over the documents" do

        let(:limited) do
          Person.only(:_id)
        end

        it "does not flag any changes" do
          limited.each do |person|
            person.changes.should be_empty
          end
        end
      end
    end

    context "when validation passes" do

      it "returns true" do
        person.save.should be_true
      end
    end

    context "when validation fails" do

      let(:address) do
        person.addresses.create(city: "London")
      end

      before do
        address.save
      end

      it "has the appropriate errors" do
        address.errors[:street].should eq(["can't be blank"])
      end
    end

    context "when modifying the entire hierarchy" do

      context "when performing modification and insert ops" do

        let(:person) do
          Person.create(title: "Blah")
        end

        let!(:address) do
          person.addresses.build(street: "Bond St")
        end

        let!(:name) do
          person.create_name(first_name: "Tony")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.title = "King"
          name.first_name = "Ryan"
        end

        it "persists with proper set and push modifiers" do
          person.atomic_updates.should eq({
            "$set" => {
              "title" => "King",
              "name.first_name" => "Ryan"
            },
            "$pushAll"=> {
              "addresses" => [ { "_id" => address.id, "street" => "Bond St" } ]
            }
          })
        end

        context "when saving the document" do

          it "saves the root document" do
            person.title.should eq("King")
          end

          it "saves embedded many relations" do
            person.addresses.first.street.should eq("Bond St")
          end

          it "saves embedded one relations" do
            person.name.first_name.should eq("Ryan")
          end
        end
      end

      context "when combining modifications and pushes" do

        let!(:location) do
          Location.new(name: 'Work')
        end

        let!(:address) do
          Address.new(
            number: 101,
            street: 'South St',
            locations: [ location ]
          )
        end

        let!(:person) do
          Person.create(
            title: "Blah",
            addresses: [ address ]
          )
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          address.number = 102
          person.addresses << Address.new(street: "North Ave")
          person.save
        end

        it "saves modifications to existing embedded docs" do
          from_db.addresses[0].number.should eq(102)
        end

        it "saves modifications to new embedded docs" do
          from_db.addresses[1].street.should eq('North Ave')
        end

        it "saves modifications to deeply embedded docs" do
          from_db.addresses[0].locations.first.name.should eq('Work')
        end
      end

      context "when removing elements without using delete or destroy" do

        let!(:person) do
          Person.create!(title: "Blah")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          person.create_name(first_name: "Tony")
          person.name = nil
          person.save
        end

        it "saves the hierarchy" do
          person.name.should be_nil
        end
      end
    end
  end

  describe "save!" do

    context "inserting with a field that is not unique" do

      context "when a unique index exists" do

        let(:person) do
          Person.new(ssn: "555-55-9999")
        end

        before do
          Person.create_indexes
          Person.create!(ssn: "555-55-9999")
        end

        it "raises an error" do
          expect { person.save! }.to raise_error
        end
      end
    end

    context "with a validation error" do

      let(:person) do
        Person.new
      end

      let!(:service) do
        Service.new(person: person, sid: "a")
      end

      it "raises an error with multiple save attempts" do
        expect { subject.save! }.should raise_error
        expect { subject.save! }.should raise_error
      end
    end

    context "when a callback returns false" do

      let(:oscar) do
        Oscar.new
      end

      it "raises a callback error" do
        expect { oscar.save! }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#update_attribute" do

    let(:post) do
      Post.new
    end

    context "when setting an array field" do

      let(:person) do
        Person.create(aliases: [])
      end

      before do
        person.update_attribute(:aliases, person.aliases << "Bond")
      end

      it "sets the new value in the document" do
        person.aliases.should eq([ "Bond" ])
      end

      it "persists the changes" do
        person.reload.aliases.should eq([ "Bond" ])
      end
    end

    context "when setting a boolean field" do

      context "when the field is true" do

        let(:person) do
          Person.new(terms: true)
        end

        context "when setting to false" do

          before do
            person.update_attribute(:terms, false)
          end

          it "persists the document" do
            person.should be_persisted
          end

          it "changes the attribute value" do
            person.terms.should be_false
          end

          it "persists the changes" do
            person.reload.terms.should be_false
          end
        end
      end
    end

    context "when provided a symbol attribute name" do

      context "when the document is valid" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "sets the attribute" do
          post.title.should eq("Testing")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when updating to the same value" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "returns true" do
          post.update_attribute(:title, "Testing").should be_true
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute(:title, "$invalid")
        end

        it "sets the attribute" do
          post.title.should eq("$invalid")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when the document has been destroyed" do

        before do
          post.delete
        end

        it "raises an error" do
          expect {
            post.update_attribute(:title, "something")
          }.to raise_error
        end
      end
    end

    context "when provided a string attribute name" do

      context "when the document is valid" do

        before do
          post.update_attribute("title", "Testing")
        end

        it "sets the attribute" do
          post.title.should eq("Testing")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute("title", "$invalid")
        end

        it "sets the attribute" do
          post.title.should eq("$invalid")
        end

        it "saves the document" do
          post.should be_persisted
        end
      end
    end

    context "when persisting a localized field" do

      let!(:product) do
        Product.create(description: "The bomb")
      end

      before do
        ::I18n.locale = :de
        product.update_attribute(:description, "Die Bombe")
      end

      after do
        ::I18n.locale = :en
      end

      let(:attributes) do
        product.attributes["description"]
      end

      it "persists the en locale" do
        attributes["en"].should eq("The bomb")
      end

      it "persists the de locale" do
        attributes["de"].should eq("Die Bombe")
      end
    end

    context "when updating a deeply embedded document" do

      let!(:person) do
        Person.create
      end

      let!(:address) do
        person.addresses.create(street: "Winterfeldtstr")
      end

      let!(:location) do
        address.locations.create(name: "work")
      end

      let(:from_db) do
        Person.last.addresses.last.locations.last
      end

      before do
        from_db.update_attribute(:name, "home")
      end

      it "updates the attribute" do
        from_db.name.should eq("home")
      end

      it "persists the changes" do
        from_db.reload.name.should eq("home")
      end
    end
  end

  describe "#update_attributes" do

    context "when providing options" do

      let(:person) do
        Person.create
      end

      let(:params) do
        [{ pets: false }, { as: :default }]
      end

      it "accepts the additional parameter" do
        expect {
          person.update_attributes(*params)
        }.to_not raise_error(ArgumentError)
      end

      it "calls assign_attributes" do
        person.expects(:assign_attributes).with(*params)
        person.update_attributes(*params)
      end

    end

    context "when saving with a hash field with invalid keys" do

      let(:person) do
        Person.create
      end

      it "raises an error" do
        expect {
          person.update_attributes(map: { "bad.key" => "value" })
        }.to raise_error(Moped::Errors::OperationFailure)
      end
    end

    context "when validation passes" do

      let(:person) do
        Person.create
      end

      let!(:saved) do
        person.update_attributes(pets: false)
      end

      let(:from_db) do
        Person.find(person.id)
      end

      it "returns true" do
        saved.should be_true
      end

      it "saves the attributes" do
        from_db.pets.should be_false
      end
    end

    context "when the document has been destroyed" do

      let!(:person) do
        Person.create
      end

      before do
        person.delete
      end

      it "raises an error" do
        expect {
          person.update_attributes(title: "something")
        }.to raise_error
      end
    end

    context "when updating through a one-to-one relation" do

      let(:person) do
        Person.create!
      end

      let(:game) do
        Game.create(person: person)
      end

      before do
        person.update_attributes!(ssn: "444-44-4444")
        game.person.update_attributes!(ssn: "555-66-7777")
      end

      let(:from_db) do
        Person.find(person.id)
      end

      it "saves the attributes" do
        person.ssn.should eq("555-66-7777")
      end
    end

    context "on a new record" do

      let(:person) do
        Person.new
      end

      before do
        person.update_attributes(pets: false, title: nil)
      end

      it "saves the new record" do
        Person.find(person.id).should_not be_nil
      end
    end

    context "when passing in a relation" do

      context "when providing a parent to a referenced in" do

        let!(:person) do
          Person.create
        end

        let!(:post) do
          Post.create(title: "Testing")
        end

        context "when the relation has not yet been touched" do

          before do
            post.update_attributes(person: person)
          end

          it "sets the instance of the relation" do
            person.posts.should eq([ post ])
          end

          it "sets properly through method_missing" do
            person.posts.to_a.should eq([ post ])
          end

          it "persists the reference" do
            person.posts(true).should eq([ post ])
          end
        end

        context "when the relation has been touched" do

          before do
            person.posts
            post.update_attributes(person: person)
          end

          it "sets the instance of the relation" do
            person.posts.should eq([ post ])
          end

          it "sets properly through method_missing" do
            person.posts.to_a.should eq([ post ])
          end

          it "persists the reference" do
            person.posts(true).should eq([ post ])
          end
        end
      end
    end

    context "when in a deeply nested hierarchy" do

      let!(:person) do
        Person.new(title: "The Boss")
      end

      let!(:phone_number) do
        Phone.new(number: "123-456-7890")
      end

      let!(:country_code) do
        CountryCode.new(code: 1)
      end

      before do
        phone_number.country_code = country_code
        person.phone_numbers << phone_number
        person.save
      end

      it "sets the first level document" do
        person.phone_numbers.first.should eq(phone_number)
      end

      it "sets the second level document" do
        person.phone_numbers.first.country_code.should eq(country_code)
      end

      context "when updating the first level document" do

        let(:phone) do
          person.phone_numbers.first
        end

        before do
          phone.number = "098-765-4321"
          phone.update_attributes(number: "098-765-4321")
        end

        it "sets the new attributes" do
          phone.number.should eq("098-765-4321")
        end

        context "when reloading the root" do

          let(:reloaded) do
            person.reload
          end

          it "saves the new attributes" do
            reloaded.phone_numbers.first.number.should eq("098-765-4321")
          end
        end
      end
    end
  end

  describe "#update_attributes!" do

    context "when providing options" do

      let(:person) do
        Person.create
      end

      let(:params) do
        [{ pets: false }, { as: :default }]
      end

      it "accepts the additional parameter" do
        expect {
          person.update_attributes!(*params)
        }.to_not raise_error(ArgumentError)
      end

      it "calls assign_attributes" do
        person.expects(:assign_attributes).with(*params)
        person.update_attributes!(*params)
      end

    end

    context "when a callback returns false" do

      let(:oscar) do
        Oscar.new
      end

      it "raises a callback error" do
        expect {
          oscar.update_attributes!(title: "The Grouch")
        }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:person) do
        Person.create(title: "sir")
      end

      context "when no conditions are provided" do

        let!(:removed) do
          Person.send(method)
        end

        it "removes all the documents" do
          Person.count.should eq(0)
        end

        it "returns the number of documents removed" do
          removed.should eq(1)
        end
      end

      context "when conditions are provided" do

        let!(:person_two) do
          Person.create
        end

        context "when in a conditions attribute" do

          let!(:removed) do
            Person.send(method, conditions: { title: "sir" })
          end

          it "removes the matching documents" do
            Person.count.should eq(1)
          end

          it "returns the number of documents removed" do
            removed.should eq(1)
          end
        end

        context "when no conditions attribute provided" do

          let!(:removed) do
            Person.send(method, title: "sir")
          end

          it "removes the matching documents" do
            Person.count.should eq(1)
          end

          it "returns the number of documents removed" do
            removed.should eq(1)
          end
        end
      end
    end
  end

  context "when a DateTime attribute is updated and persisted" do

    let(:user) do
      User.create!(last_login: 2.days.ago).tap do |u|
        u.last_login = DateTime.now
      end
    end

    it "reads for persistance as a UTC Time" do
      user.changes["last_login"].last.class.should eq(Time)
    end

    it "persists with no exceptions thrown" do
      user.save!
    end
  end

  context "when a Date attribute is persisted" do

    let(:user) do
      User.create!(account_expires: 2.years.from_now).tap do |u|
        u.account_expires = "2/2/2002".to_date
      end
    end

    it "reads for persistance as a UTC Time" do
      user.changes["account_expires"].last.class.should eq(Time)
    end

    it "persists with no exceptions thrown" do
      user.save!
    end
  end

  context "when setting floating point numbers" do

    context "when value is an empty string" do

      let(:person) do
        Person.new
      end

      before do
        Person.validates_numericality_of :blood_alcohol_content, allow_blank: true
      end

      it "does not set the value" do
        person.save.should be_true
      end
    end
  end

  context "when setting association foreign keys" do

    let(:game) do
      Game.new
    end

    let(:person) do
      Person.create
    end

    context "when value is an empty string" do

      before do
        game.person_id = ""
        game.save
      end

      it "sets the foreign key to empty" do
        game.reload.person_id.should be_blank
      end
    end

    context "when value is a populated string" do

      before do
        game.person_id = person.id.to_s
        game.save
      end

      it "sets the foreign key as ObjectID" do
        game.reload.person_id.should eq(person.id)
      end
    end

    context "when value is a ObjectID" do

      before do
        game.person_id = person.id
        game.save
      end

      it "keeps the the foreign key as ObjectID" do
        game.reload.person_id.should eq(person.id)
      end
    end
  end

  context "when the document is a subclass of a root class" do

    let!(:browser) do
      Browser.create(version: 3, name: "Test")
    end

    let(:collection) do
      Canvas.collection
    end

    let(:attributes) do
      collection.find({ name: "Test"}).first
    end

    it "persists the versions" do
      attributes["version"].should eq(3)
    end

    it "persists the type" do
      attributes["_type"].should eq("Browser")
    end

    it "persists the attributes" do
      attributes["name"].should eq("Test")
    end
  end

  context "when the document is a subclass of a subclass" do

    let!(:firefox) do
      Firefox.create(version: 2, name: "Testy")
    end

    let(:collection) do
      Canvas.collection
    end

    let(:attributes) do
      collection.find({ name: "Testy"}).first
    end

    before do
      Browser.create(name: 'Safari', version: '4.0.0')
    end

    it "persists the versions" do
      attributes["version"].should eq(2)
    end

    it "persists the type" do
      attributes["_type"].should eq("Firefox")
    end

    it "persists the attributes" do
      attributes["name"].should eq("Testy")
    end

    it "returns the document when querying for superclass" do
      Browser.where(name: "Testy").first.should eq(firefox)
    end

    it "returns the document when querying for root class" do
      Canvas.where(name: "Testy").first.should eq(firefox)
    end

    it 'returnss on of this subclasses if you find by _type' do
      Canvas.where(:_type.in => ['Firefox']).count.should eq(1)
    end
  end

  context "when the document has associations" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    let!(:writer) do
      HtmlWriter.new(speed: 100)
    end

    let!(:circle) do
      Circle.new(radius: 50)
    end

    let!(:square) do
      Square.new(width: 300, height: 150)
    end

    let(:from_db) do
      Firefox.find(firefox.id)
    end

    before do
      firefox.writer = writer
      firefox.shapes << [ circle, square ]
      firefox.save!
    end

    it "properly persists the one-to-one type" do
      from_db.should be_a_kind_of(Firefox)
    end

    it "properly persists the one-to-one relations" do
      from_db.writer.should eq(writer)
    end

    it "properly persists the one-to-many type" do
      from_db.shapes.first.should eq(circle)
    end

    it "properly persists the one-to-many relations" do
      from_db.shapes.last.should eq(square)
    end

    it "properly sets up the parent relation" do
      from_db.shapes.first.should eq(circle)
    end

    it "properly sets up the entire hierarchy" do
      from_db.shapes.first.canvas.should eq(firefox)
    end
  end

  context "when the document is subclassed" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    it "finds the document with String args" do
      Firefox.find(firefox.id.to_s).should eq(firefox)
    end

    context "when querying for parent documents" do

      let(:canvas) do
        Canvas.where(name: "firefox").first
      end

      it "returns matching subclasses" do
        canvas.should eq(firefox)
      end
    end
  end

  context "when deleting subclasses" do

    let!(:firefox) do
      Firefox.create(name: "firefox")
    end

    let!(:firefox2) do
      Firefox.create(name: "firefox 2")
    end

    let!(:browser) do
      Browser.create(name: "browser")
    end

    let!(:canvas) do
      Canvas.create(name: "canvas")
    end

    context "when deleting a single document" do

      before do
        firefox.delete
      end

      it "deletes from the parent class collection" do
        Canvas.count.should eq(3)
      end

      it "returns correct counts for child classes" do
        Firefox.count.should eq(1)
      end

      it "returns correct counts for root subclasses" do
        Browser.count.should eq(2)
      end
    end

    context "when deleting all documents" do

      before do
        Firefox.delete_all
      end

      it "deletes from the parent class collection" do
        Canvas.count.should eq(2)
      end

      it "returns correct counts for child classes" do
        Firefox.count.should eq(0)
      end

      it "returns correct counts for root subclasses" do
        Browser.count.should eq(1)
      end
    end
  end

  context "when document is a subclass and its parent is an embedded document" do

    let!(:canvas) do
      Canvas.create(name: "canvas")
    end

    before do
      canvas.create_palette
      canvas.palette.tools << Pencil.new
      canvas.palette.tools << Eraser.new
    end

    let(:from_db) do
      Canvas.find(canvas.id)
    end

    it "properly saves the subclasses" do
      from_db.palette.tools.map(&:class).should eq([Pencil, Eraser])
    end
  end

  context "Creating references_many documents from a parent association" do

    let!(:container) do
      ShippingContainer.create
    end

    let(:driver) do
      Driver.create
    end

    it "does not bleed relations from one subclass to another" do
      Truck.relations.keys.should =~ %w/ shipping_container driver bed /
      Car.relations.keys.should =~ %w/ shipping_container driver /
    end

    context "when appending new documents" do

      before do
        container.vehicles << Car.new
        container.vehicles << Truck.new
      end

      it "allows STI from << using model.new" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when appending persisted documents" do

      before do
        container.vehicles << Car.create
        container.vehicles << Truck.create
      end

      it "allows STI from << using model.create" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when building related documents" do

      before do
        container.vehicles.build({}, Car).save
        container.vehicles.build({}, Truck).save
      end

      it "allows STI from the build call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when building with a type attribute" do

      before do
        container.vehicles.build({ "_type" => "Car" })
        container.vehicles.build({ "_type" => "Truck" })
      end

      it "respects the _type attribute from the build call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when creating related documents" do

      before do
        container.vehicles.create({}, Car)
        container.vehicles.create({}, Truck)
      end

      it "allows STI from the create call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "when creating with a type attribute" do

      before do
        container.vehicles.create({ "_type" => "Car" })
        container.vehicles.create({ "_type" => "Truck" })
      end

      it "respects the _type attribute from the create call" do
        container.vehicles.map(&:class).should eq([ Car, Truck ])
      end
    end

    context "#find_or_initialize_by" do

      before do
        container.vehicles.find_or_initialize_by({ driver_id: driver.id }, Car)
      end

      it "initializes the given type document" do
        container.vehicles.map(&:class).should eq([ Car ])
      end

      it "initializes with the given attributes" do
        container.vehicles.map(&:driver).should eq([ driver ])
      end
    end

    context "#find_or_create_by" do

      before do
        container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
      end

      it "creates the given type document" do
        container.vehicles.map(&:class).should eq([ Car ])
      end

      it "creates with the given attributes" do
        container.vehicles.map(&:driver).should eq([ driver ])
      end

      it "creates the correct number of documents" do
        container.vehicles.size.should eq(1)
      end

      context "when executing with a found document" do

        before do
          container.vehicles.find_or_create_by({ driver_id: driver.id }, Car)
        end

        it "does not create an additional document" do
          container.vehicles.size.should eq(1)
        end
      end

      context "when executing with an additional new document" do

        before do
          container.vehicles.find_or_create_by({ driver_id: driver.id }, Truck)
        end

        it "creates the new additional document" do
          container.vehicles.size.should eq(2)
        end
      end
    end
  end
end
