require "spec_helper"

describe Mongoid::Associations do

  before do
    [ Artist, Person, Game, Post, Preference, UserAccount ].each do |klass|
      klass.collection.remove
    end
  end

  context "when setting an array of object ids" do

    let(:person) do
      Person.new
    end

    context "when the values are strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      before do
        person.attributes = { "preference_ids" => [ object_id.to_s ] }
      end

      it "casts back to object ids" do
        person.preference_ids.should == [ object_id ]
      end
    end
  end

  context "when destroying dependent documents" do

    before do
      @person = Person.create(:ssn => "243-79-1122")
      @game = @person.create_game(:score => 450)
    end

    it "deletes the dependent documents from the db" do
      @person.destroy
      Game.count.should == 0
    end
  end

  context "when deleting dependent documents" do

    before do
      @person = Person.create(:ssn => "243-79-1122")
      @post = @person.posts.create(:title => "Testing")
    end

    it "deletes the dependent documents from the db" do
      @person.destroy
      Post.count.should == 0
    end
  end

  context "anonymous extensions" do

    before do
      @person = Person.new(:title => "Dr")
      @address_one = Address.new(:street => "Oxford")
      @address_two = Address.new(:street => "Bond")
      @name = Name.new(:first_name => "Richard", :last_name => "Dawkins")
      @person.addresses << [ @address_one, @address_two ]
      @person.name = @name
      @person.save
    end

    context "when defined on an embeds_many" do

      it "applies the extension" do
        addresses = @person.addresses.find_by_street("Oxford")
        addresses.size.should == 1
        addresses.first.should == @address_one
      end
    end

    context "when defined on a has_one" do

      it "applies the extension" do
        name = @person.name
        name.dawkins?.should be_true
      end
    end

    context "when defined on an embedded_in" do

      it "applies the extension" do
        @address_two.addressable.doctor?.should be_true
      end
    end
  end

  context "creation of an embedded association on a callback" do

    it "allows the use of create!" do
      artist = Artist.create!(:name => "Depeche Mode")
      artist.songs.size.should == 2
      artist.songs.first.title.should == "0"
      artist.songs.last.title.should == "1"
    end
  end

  context "passing a relational child to the parent constructor" do

    before do
      @game = Game.new(:score => 1)
      @person = Person.new(:title => "Sir", :game => @game)
      @person.save
    end

    it "sets the association on save" do
      @from_db = Person.find(@person.id)
      @from_db.game.should == @game
    end

    it "sets the reverse association before save" do
      @game.person.should == @person
    end

    it "sets the reverse association after save" do
      @from_db = Game.find(@game.id)
      @game.person.should == @person
    end
  end

  context "creation of an embedded association via create" do

    context "when passed a parent" do

      before do
        @artist = Artist.new(:name => "Placebo")
        @label = Label.create(:artist => @artist, :name => "Island")
      end

      it "saves the parent and the child" do
        from_db = Artist.find(@artist.id)
        from_db.labels.first.should == @label
      end

      it "does not save the child more than once" do
        from_db = Artist.find(@artist.id)
        from_db.labels.size.should == 1
      end
    end
  end

  context "criteria on has many embedded associations" do

    before do
      @person = Person.new(:title => "Sir")
      @tx_home = Address.new(:street => "Leadbetter Dr", :state => "TX", :address_type => "Home")
      @sf_apartment = Address.new(:street => "Genoa Pl", :state => "CA", :address_type => "Apartment")
      @la_home = Address.new(:street => "Rodeo Dr", :state => "CA", :address_type => "Home")
      @sf_home = Address.new(:street => "Pacific", :state => "CA", :address_type => "Home")
      @person.addresses << [ @tx_home, @sf_apartment, @la_home, @sf_home ]
    end

    it "handles an aggregation method" do
      streets = [ @tx_home, @sf_apartment, @la_home, @sf_home ].map(&:street)
      @person.addresses.streets.should == streets
    end

    it "handles a single criteria" do
      cas = @person.addresses.california
      cas.size.should == 3
      cas.should == [ @sf_apartment, @la_home, @sf_home ]
    end

    it "handles a single criteria and an aggregation method" do
      streets = [ @sf_apartment, @la_home, @sf_home ].map(&:street)
      @person.addresses.california.streets.should == streets
    end

    it "handles chained criteria" do
      ca_homes = @person.addresses.california.homes
      ca_homes.size.should == 2
      ca_homes.should == [ @la_home, @sf_home ]
    end

    it "handles chained criteria with final aggregation method" do
      ca_streets = @person.addresses.california.homes.streets
      ca_streets.should == [ @la_home.street, @sf_home.street ]
    end

    it "handles chained criteria with named scopes" do
      ca_homes = @person.addresses.california.homes.rodeo
      ca_homes.size.should == 1
      ca_homes.should == [ @la_home ]
    end

    it "handles chained criteria with named scopes and final aggregation method" do
      ca_streets = @person.addresses.california.homes.rodeo.streets
      ca_streets.should == [ @la_home.street ]
    end

    it "handles chained criteria with named scope and extension" do
      @person.addresses.california.homes.rodeo.should be_a_mansion
    end
  end

  context "one-to-one relational associations" do

    before do
      @person = Person.new(:title => "Sir")
      @game = Game.new(:score => 1)
      @person.game = @game
      @person.save
    end

    it "sets the association on save" do
      @from_db = Person.find(@person.id)
      @from_db.game.should == @game
    end

    it "sets the reverse association before save" do
      @game.person.should == @person
    end

    it "sets the reverse association after save" do
      @from_db = Game.find(@game.id)
      @game.person.should == @person
    end

    context "when defining a class name and foreign key" do

      before do
        @user = User.new(:name => "Don Julio")
        @account = @user.build_account(:number => "1234567890")
      end

      it "sets the name of the association properly" do
        @account.creator.should == @user
      end
    end

    context "when the parent is nil" do
      before do
        @account = Account.new
        @account.creator = nil
        @account.save!
      end

      it "stores the parent correctly" do
        @account.reload
        @account.creator.should == nil
      end

      it "should say that its nil" do
        @account.creator.nil?.should == true
      end

    end

  end

  context "one-to-many relational associations" do
    [
      ["with default naming scheme", Person, :person],
      ["with custom naming scheme and :inverse_of", User, :author],
      ["with custom naming scheme and no :inverse_of", Agent, :poster]
    ].each do |description, parent_class, association_name|
      context description do
        before do
          @person = parent_class.new(:title => "Sir")
          @post = Post.new(:title => "Testing")
          @person.posts = [@post]
          @person.save
        end

        it "sets the association on save" do
          from_db = parent_class.find(@person.id)
          from_db.posts.should == [@post]
        end

        describe "#build" do

          before do
            @another = @person.posts.build(:title => "Another")
          end

          it "sets new_record to true" do
            @another.new_record?.should == true
          end
        end

        describe "#delete_all" do

          context "without conditions" do

            before do
              @person.posts.delete_all
            end

            it "deletes all the related objects" do
              Post.count.should == 0
              @person.posts.size.should == 0
            end
          end

          context "with conditions" do

            before do
              @person.posts.delete_all(:conditions => { :title => "Testing" })
            end

            it "deletes the appropriate objects" do
              Post.count.should == 0
              @person.posts.size.should == 0
            end
          end
        end

        describe "#destroy_all" do

          context "without conditions" do

            before do
              @person.posts.destroy_all
            end

            it "deletes all the related objects" do
              Post.count.should == 0
              @person.posts.size.should == 0
            end
          end

          context "with conditions" do

            before do
              @person.posts.destroy_all(:conditions => { :title => "Testing" })
            end

            it "deletes the appropriate objects" do
              Post.count.should == 0
              @person.posts.size.should == 0
            end
          end
        end

        context "when adding a new association" do

          before do
            @new_post = Post.new(:title => "New")
            @person.posts << @new_post
          end

          it "rememoizes the new association" do
            @person.posts.should == [ @post, @new_post ]
          end
        end

        context "when building" do

          before do
            @person = parent_class.new(:title => "Mr")
            @post = @person.posts.build(:title => "First")
          end

          it "sets the reverse association" do
            @post.send(association_name).should == @person
          end

        end

        context "finding associated objects" do

          before do
            @extra_post = Post.create(:title => "Orphan")
            @from_db = parent_class.find(@person.id)
          end

          context "finding all" do

            it "returns only those objects scoped to the parent" do
              Post.all.size.should == 2
              @from_db.posts.all.size.should == 1
            end

          end

          context "finding with conditions" do

            context "finding all" do

              it "returns only those objects scoped to the parent" do
                posts = @from_db.posts.find(:all, :conditions => { :title => "Testing" })
                posts.size.should == 1
              end

            end

            context "finding first" do

              it "returns only those objects scoped to the parent" do
                post = @from_db.posts.find(:first, :conditions => { :title => "Testing" })
                post.should == @post
              end

            end

            context "finding last" do

              it "returns only those objects scoped to the parent" do
                post = @from_db.posts.find(:last, :conditions => { :title => "Testing" })
                post.should == @post
              end

            end

            context "using a named scope" do

              before do
                @post.created_at = 15.days.ago
                @post.save
              end

              it "returns only those scoped to the parent plus the named scope" do
                posts = @from_db.posts.recent
                posts.size.should == 1
              end

            end

            context "using a criteria class method" do

              before do
                @post.created_at = 45.days.ago
                @post.save
              end

              it "returns only those scoped to the parent plus the named scope" do
                posts = @from_db.posts.old
                posts.size.should == 1
              end

            end

            context "calling criteria methods" do

              before do
                @post.title = "New Title"
                @post.save
              end

              it "returns the proper object for the criteria" do
                posts = @from_db.posts.where(:title => "New Title")
                posts.size.should == 1
              end

              context "when calling with a new criteria" do

                before do
                  @from_db.posts.create(:title => "Other Title")
                end

                it "does not retain the old criteria" do
                  @from_db.posts.where(:title => "New Title").size.should == 1
                  @from_db.posts.size.should == 2
                  @from_db.posts.where(:title => "Other Title").size.should == 1
                end
              end
            end
          end
        end
      end
    end
  end

  context "nested embedded associations" do

    before do
      @person = Person.create(:title => "Mr")
    end

    context "having an embedded document as both an embeds_one and many" do

      before do
        @agent = Agent.new(:number => "007")
        @person = Person.new(:title => "Dr", :ssn => "123-12-6666")
        @agent_name = Name.new(:first_name => "James")
        @person_name = Name.new(:first_name => "Jack")
        @agent.names << @agent_name
        @person.name = @person_name
        @agent.save
        @person.save
      end

      context "when the document is an embeds_one" do

        it "sets the association_name" do
          @agent_name.namable = @agent
          @agent_name.namable.should == @agent
          @agent_name.association_name.should == "names"
        end
      end

      context "when the document is an embeds_many" do

        it "sets the association_name" do
          @person_name.namable = @person
          @person_name.namable.should == @person
          @person_name.association_name.should == "name"
        end
      end
    end

    context "saving an existing parent document with existing children" do

      before do
        @address = @person.addresses.create(:street => "Oxford St")
        @address.city = "London"
        @person.save
      end

      it "saves all dirty children" do
        from_db = Person.find(@person.id)
        from_db.addresses.first.city.should == "London"
      end
    end

    context "saving an existing parent document with new children" do

      context "when building" do

        before do
          @address = @person.addresses.build(:street => "Oxford St")
          @person.save
        end

        it "saves all new children" do
          from_db = Person.find(@person.id)
          from_db.addresses.first.should == @address
        end
      end

      context "when appending one elements" do

        before do
          @address = Address.new(:street => "Oxford St")
          @person.addresses << @address
          @person.save
        end

        it "saves all new children" do
          from_db = Person.find(@person.id)
          from_db.addresses.first.should == @address
        end
      end

      context "when appending several elements" do

        before do
          @address = Address.new(:street => "Oxford St")
          @address2 = Address.new(:street => "Cambridge St")
          @person.addresses << @address
          @person.addresses << @address2
          @person.save
        end

        it "saves all new children" do
          from_db = Person.find(@person.id)
          from_db.addresses.count.should == 2
          from_db.addresses.first.should == @address
          from_db.addresses.second.should == @address2
        end
      end

      context "when creating" do

        before do
          @address = @person.addresses.create(:street => "Oxford St")
        end

        it "saves all new children" do
          @person.reload.addresses.first.should == @address
        end
      end

      context "when overwriting" do
        before do
          @person.addresses.build(:street => "Oxford St")
          @person.addresses = @person.addresses
        end

        it "still recognizes the embedded document as a new record" do
          @person.addresses.first.should be_new_record
        end
      end

      context "when overwriting with nil" do
        before do
          @person.addresses = nil
        end

        it "sets the association to an empty array" do
          @person.addresses.should == []
        end
      end

      context "when overwriting with empty Array" do
        before do
          @person.addresses << Address.new(:street => 'hello')
          @person.save
          @person.addresses = []
        end

        it "sets the association to an empty array" do
          @person.addresses.should == []
        end
      end

      context "when delete_all" do
        before do
          @person.addresses << Address.new(:street => 'hello')
          @person.addresses << Address.new(:street => 'hello')
          @person.save
          @person.addresses.delete_all
        end

        it "sets the association to an empty array" do
          @person.addresses.should == []
        end
      end

    end

    context "one level nested" do

      before do
        @address = @person.addresses.create(:street => "Oxford St")
        @name = @person.create_name(:first_name => "Gordon")
      end

      it "persists all the associations properly" do
        @name.last_name = "Brown"
        @person.name.last_name.should == "Brown"
      end

      it "sets the new_record values properly" do
        from_db = Person.find(@person.id)
        new_name = from_db.create_name(:first_name => "Flash")
        new_name.new_record?.should be_false
      end

      context "updating embedded arrays" do

        before do
          @person.addresses.create(:street => "Picadilly Circus")
          @from_db = Person.find(@person.id)
          @first = @from_db.addresses[0]
          @second = @from_db.addresses[1]
        end

        it "does not change the internal order of the array" do
          @from_db.addresses.first.update_attributes(:city => "London")
          @from_db.addresses.should == [ @first, @second ]
        end

        it "does not change the internal order of the attributes in the parent" do
          @from_db.addresses.first.update_attributes(:city => "London")
          @from_db.attributes["addresses"].should == [@first.attributes, @second.attributes]
        end

        context "updating an element that is a new record" do
          before do
            @third = Address.new(:street => "Foo")
            @fourth = Address.new(:street => "Bar")
            @from_db.addresses << @third
            @from_db.addresses << @fourth
            @from_db.save!
          end

          it "does not change the internal order of the array" do
            @third.update_attributes(:city => "London")
            @from_db.addresses.should == [ @first, @second, @third, @fourth ]
          end

          it "does not change the internal order of the attributes in the parent" do
            @third.update_attributes(:city => "London")
            @from_db.attributes["addresses"].should == [@first.attributes, @second.attributes, @third.attributes, @fourth.attributes]
          end
        end
      end

      describe "#first" do

        let(:person) do
          Person.create(:ssn => "444-33-7777")
        end

        before do
          @video_id = person.videos.create(:title => "Oldboy").id
        end

        it "does not generate a new id each time" do
          5.times { person.videos.first.id.should == @video_id }
        end
      end

      describe "#delete_all" do

        it "removes the appropriate documents" do
          @person.addresses.delete_all(:conditions => { :street => "Oxford St" }).should == 1
          @person.addresses.size.should == 0
        end
      end

      describe "#destroy_all" do

        it "removes the appropriate documents" do
          @person.addresses.destroy_all(:conditions => { :street => "Oxford St" }).should == 1
          @person.addresses.size.should == 0
        end
      end
    end

    context "embedded_in instantiated and added later to parent" do
      before do
        @address = Address.new
        @person = Person.new
      end

      it "doesn't memoize a nil parent" do
        @address.addressable
        @person.addresses << @address
        @address.addressable.should == @person
      end
    end

    context "multiple levels nested" do

      context "when a has-many to has_one" do

        before do
          @person.phone_numbers.create(:number => "4155551212")
        end

        it "persists all the associations properly" do
          from_db = Person.find(@person.id)
          phone = from_db.phone_numbers.first
          phone.create_country_code(:code => 1)
          from_db.phone_numbers.first.country_code.code.should == 1
        end

      end

      context "when a has-one to has-many" do

        before do
          @person = Person.new(:title => "Sir", :ssn => "1")
          @name = Name.new(:first_name => "Syd")
          @person.name = @name
          @person.save
        end

        it "persists all the associations properly" do
          from_db = Person.find(@person.id)
          translation = Translation.new(:language => "fr")
          from_db.name.translations << translation
          from_db.attributes[:name][:translations].should_not be_nil
        end

      end

      context "when a has-many to has-many" do

        before do
          @address = Address.new(:street => "Upper Street")
          @person.addresses << @address
        end

        it "bubbles the child association up to root" do
          location = Location.new(:name => "Home")
          @address.locations << location
          location.stubs(:valid?).returns(false)
          @person.save
          @person.addresses.first.locations.first.should == location
        end
      end
    end
  end

  context "references many as array" do

    context "when initializing a new document" do
      context "with a references_many association" do
        let(:preference) { Preference.create(:name => "test") }
        let(:person) { Person.new :preferences => [preference] }

        it 'adds the document to the array' do
          person.preferences.first.should == preference
        end
      end
    end

    context "with a saved parent" do
      let(:person) { Person.create!(:ssn => "992-33-1010") }

      describe "#destroy_all" do
        let!(:preference) { person.preferences.create(:name => "Bleak wastelands") }

        context "without conditions" do
          it "clears the association" do
            person.preferences.destroy_all
            person.preferences.should be_empty
          end

          it "returns the count of deleted records" do
            person.preferences.destroy_all.should == 1
          end
        end

        context "with conditions" do
          it "deletes the approriate records" do
            person.preferences.destroy_all(:name => "Sunshine and puppies")
            person.preferences.should == [preference]
          end
        end
      end

      describe "#delete_all" do
        let!(:preference) { person.preferences.create(:name => "Death and despair") }

        context "without conditions" do
          it "clears the association" do
            person.preferences.delete_all
            person.preferences.should be_empty
          end

          it "returns the count of deleted records" do
            person.preferences.delete_all.should == 1
          end
        end

        context "with conditions" do
          it "deletes the approriate records" do
            person.preferences.delete_all(:name => "Rainbows and unicorns")
            person.preferences.should == [preference]
          end
        end
      end
      context "appending a new document" do

        context "with a references_many association" do
          let(:preference) { Preference.new(:name => "test") }
          before { person.preferences << preference }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end

          it "adds the parent document to the reverse association" do
            preference.people.first.should == person
          end
        end

        context "with a referenced_in association" do
          let(:user_account) { UserAccount.new(:username => "johndoe") }
          before { person.user_accounts << user_account }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end

          it "adds the parent document to the reverse association" do
            user_account.person.should == person
          end
        end
      end

      context "building a document" do

        context "with a references_many association" do
          let!(:preference) { person.preferences.build(:name => "test") }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end

          it "adds the parent document to the reverse association" do
            preference.people.first.should == person
          end
        end

        context "with a referenced_in association" do
          let!(:user_account) { person.user_accounts.build(:username => "johndoe") }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end

          it "adds the parent document to the reverse association" do
            user_account.person.should == person
          end
        end
      end

      context "creating a document" do
        context "with a references_many association" do
          let!(:preference) { person.preferences.create(:name => "test") }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end

          it "adds the parent document to the reverse association" do
            preference.people.first.should == person
          end
        end

        context "with a referenced_in association" do
          let!(:user_account) { person.user_accounts.create(:username => "johndoe") }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end

          it "adds the parent document to the reverse association" do
            user_account.person.should == person
          end
        end
      end
    end

    context "with a new parent" do

      let(:person) { Person.new(:ssn => "992-33-1010") }

      context "appending a new document" do

        context "with a references_many association" do
          let(:preference) { Preference.new(:name => "test") }
          before { person.preferences << preference }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end
        end

        context "with a referenced_in association" do
          let(:user_account) { UserAccount.new(:username => "test") }
          before { person.user_accounts << user_account }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end
        end
      end

      context "building a document" do

        context "with a references_many association" do
          let!(:preference) { person.preferences.build(:name => "test") }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end

          it "adds the parent document to the reverse association"
        end

        context "with a referenced_in association" do
          let!(:user_account) { person.user_accounts.build(:username => "test") }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end

          it "adds the parent document to the reverse association"
        end
      end

      context "creating a document" do

        context "with a references_many association" do
          let!(:preference) { person.preferences.create(:name => "test") }

          it "adds the document to the array" do
            person.preferences.first.should == preference
          end

          it "adds the parent document to the reverse association"
        end

        context "with a referenced_in association" do
          let!(:user_account) { person.user_accounts.create(:username => "test") }

          it "adds the document to the array" do
            person.user_accounts.first.should == user_account
          end

          it "adds the parent document to the reverse association"
        end
      end
    end
  end
end
