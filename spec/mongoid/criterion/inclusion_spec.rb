require "spec_helper"

describe Mongoid::Criterion::Inclusion do

  let(:base) do
    Mongoid::Criteria.new(Person)
  end

  describe "#all" do

    let(:criteria) do
      base.all(:title => ["title1", "title2"])
    end

    it "adds the $all query to the selector" do
      criteria.selector.should eq(
        { :title => { "$all" => ["title1", "title2"] }}
      )
    end

    it "returns a copy" do
      criteria.all(:title => [ "title1" ]).should_not eql(criteria)
    end

    context "when all criteria exists" do

      let(:criteria) do
        base.
          all(:title => ["title1", "title2"]).
          all(:title => ["title3"], :another => ["value"])
      end

      it "appends to the existing criteria" do
        criteria.selector.should eq(
          {
            :title => { "$all" => [ "title1", "title2", "title3" ] },
            :another => { "$all" => [ "value" ] }
          }
        )
      end
    end
  end

  describe "#all_in" do

    context "when providing string ids" do

      let!(:person) do
        Person.create
      end

      let(:from_db) do
        Person.all_in(:_id => [ person.id.to_s ])
      end

      it "returns the matching documents" do
        from_db.should eq([ person ])
      end
    end
  end

  describe "#and" do

    context "when provided a hash" do

      let(:criteria) do
        base.and(:title => "Title", :text => "Text")
      end

      it "adds the clause to the selector" do
        criteria.selector.should eq(
          {
            :title => "Title",
            :text => "Text"
          }
        )
      end
    end

    context "when provided a string" do

      let(:criteria) do
        base.and("this.date < new Date()")
      end

      it "adds the $where clause to the selector" do
        criteria.selector.should eq(
          { "$where" => "this.date < new Date()" }
        )
      end
    end

    it "returns a copy" do
      base.and.should_not eql(base)
    end
  end

  describe "#any_in" do

    context "when querying a set field" do

      let(:time) do
        Time.now
      end

      let(:criteria) do
        Video.any_in(:release_dates => [ time ])
      end

      it "converts the selector properly" do
        criteria.selector.should eq({ :release_dates => { "$in" => [ time ] }})
      end
    end

    context "when providing multiple fields" do

      let(:criteria) do
        base.any_in(:title => ["title1", "title2"], :text => ["test"])
      end

      it "aliases to #in" do
        criteria.selector.should eq({
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        })
      end
    end

    context "when chaining on the same field" do

      let(:criteria) do
        base.
          any_in(:title => [ "test", "test2" ]).
          any_in(:title => [ "test2", "test3" ])
      end

      it "intersects the selector" do
        criteria.selector.should eq({
          :title => { "$in" => [ "test2" ] }
        })
      end
    end

    context "when querying on foreign keys" do

      context "when not using object ids" do

        before(:all) do
          Person.field(
            :_id,
            type: String,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new.to_s }
          )
        end

        after(:all) do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new }
          )
        end

        let!(:person) do
          Person.safely.create!(:ssn => "123-11-1111")
        end

        let!(:account) do
          person.safely.create_account(:name => "test")
        end

        let(:from_db) do
          Account.any_in(:person_id => [ person.id ])
        end

        it "returns the correct results" do
          from_db.should eq([ account ])
        end
      end
    end

    context "when chaining after a where" do

      let!(:person) do
        Person.create(:title => "sir")
      end

      let(:criteria) do
        Person.where(:title => "sir")
      end

      let(:from_db) do
        criteria.any_in(:title => [ "sir", "madam" ])
      end

      it "returns the correct documents" do
        from_db.should eq([ person ])
      end

      it "contains the overridden selector" do
        from_db.selector.should eq({ :title => { "$in" => [ "sir", "madam" ] } })
      end
    end

    context "when the field value is nil" do

      let!(:person) do
        Person.create(:title => nil)
      end

      context "when searching for any value" do

        let(:from_db) do
          Person.any_in(:title => [ true, false, nil ])
        end

        it "returns the matching documents" do
          from_db.should eq([ person ])
        end
      end
    end

    context "when the field value is false" do

      let!(:person) do
        Person.create(:terms => false)
      end

      context "when searching for any value" do

        let(:from_db) do
          Person.any_in(:terms => [ true, false, nil ])
        end

        it "returns the matching documents" do
          from_db.should eq([ person ])
        end
      end
    end

    context "when providing string ids" do

      let!(:person) do
        Person.create
      end

      let(:from_db) do
        Person.any_in(:_id => [ person.id.to_s ])
      end

      it "returns the matching documents" do
        from_db.should eq([ person ])
      end
    end
  end

  describe "#any_of" do

    let!(:person_one) do
      Person.create(:title => "Sir", :age => 5)
    end

    let!(:person_two) do
      Person.create(:title => "Sir", :age => 7)
    end

    let!(:person_three) do
      Person.create(:title => "Madam", :age => 1)
    end

    context "when provided a hash" do

      context "on different fields" do

        let(:criteria) do
          base.any_of({ :field1 => "test" }, { :field2 => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should eq(
            { "$or" => [ { :field1 => "test" }, { :field2 => "testy" } ] }
          )
        end
      end

      context "on the same fields" do

        let(:criteria) do
          base.any_of({:field1 => "test" }, { :field1.lt => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should eq(
            { "$or" => [ { :field1 => "test" }, { :field1 => { "$lt" => "testy" } } ] }
          )
        end
      end

      context "when supplying an array" do

        let(:criteria) do
          base.any_of([{:field1 => "test" }, { :field1.lt => "testy" }])
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should eq(
            { "$or" => [ { :field1 => "test" }, { :field1 => { "$lt" => "testy" } } ] }
          )
        end
      end
    end

    context "with a single match" do

      let(:from_db) do
        Person.where(:title => "Madam").any_of(:age => 1)
      end

      it "returns any matching documents" do
        from_db.should eq([ person_three ])
      end
    end

    context "when chaining for multiple matches" do

      let(:from_db) do
        Person.any_of({ :age => 7 }, { :age.lt => 3 })
      end

      it "returns any matching documents" do
        from_db.should eq([ person_two, person_three ])
      end
    end

    context "when using object ids" do

      context "when provided strings as params" do

        let(:from_db) do
          Person.any_of(
            { :_id => person_one.id.to_s },
            { :_id => person_two.id.to_s }
          )
        end

        it "returns the matching documents" do
          from_db.should eq([ person_one, person_two ])
        end
      end
    end
  end

  describe "#all_of" do

    let!(:person_one) do
      Person.safely.create!
    end

    let!(:person_two) do
      Person.safely.create!
    end

    context "when providing object ids" do

      let!(:from_db) do
        Person.all_of(
          { :_id.in => [ person_one.id, person_two.id ] },
          { :_id => person_two.id }
        )
      end

      it "returns the matching documents" do
        from_db.should eq([ person_two ])
      end
    end

    context "when providing string ids" do

      let!(:from_db) do
        Person.all_of(
          { :_id.in => [ person_one.id.to_s, person_two.id.to_s ] },
          { :_id => person_two.id.to_s }
        )
      end

      it "returns the matching documents" do
        from_db.should eq([ person_two ])
      end
    end

    context "when providing no expressions" do

      let!(:from_db) do
        Person.all_of
      end

      it "returns the first document" do
        from_db.should include(person_one)
      end

      it "returns the second document" do
        from_db.should include(person_two)
      end

      it "returns only the matching documents" do
        from_db.count.should eq(2)
      end
    end
  end

  describe "#also_in" do

    let(:criteria) do
      base.also_in(:title => ["title1", "title2"], :text => ["test"])
    end

    it "adds the $in clause to the selector" do
      criteria.selector.should eq(
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        }
      )
    end

    it "returns a copy" do
      criteria.also_in(:title => ["title1"]).should_not eql(criteria)
    end

    context "when existing in criteria exists" do

      let(:criteria) do
        base.
          in(:title => ["title1", "title2"]).
          also_in(:title => ["title3"], :text => ["test"])
      end

      it "appends to the existing criteria" do
        criteria.selector.should eq(
          {
            :title => {
              "$in" => ["title1", "title2", "title3"] }, :text => { "$in" => ["test"]
            }
          }
        )
      end
    end
  end

  describe "#find" do

    let!(:person) do
      Person.create(:title => "Sir")
    end

    context "when finding by an id" do

      context "when the id is found" do

        context "when the additional criteria matches" do

          let!(:from_db) do
            Person.where(:title => "Sir").find(person.id)
          end

          it "returns the matching document" do
            from_db.should eq(person)
          end
        end

        context "when the additional criteria does not match" do

          let(:from_db) do
            Person.where(:title => "Madam").find(person.id)
          end

          it "raises a not found error" do
            expect { from_db }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end
      end

      context "when the id is not found" do

        context "when raising a not found error" do

          it "raises an error" do
            expect {
              Person.where(:title => "Sir").find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when not raising a not found error" do

          before do
            Mongoid.raise_not_found_error = false
          end

          after do
            Mongoid.raise_not_found_error = true
          end

          let!(:from_db) do
            Person.where(:title => "Sir").find(BSON::ObjectId.new)
          end

          it "returns nil" do
            from_db.should be_nil
          end
        end
      end
    end

    context "when finding by an array of ids" do

      context "when ids are not object ids" do

        let!(:jar_one) do
          Jar.create(:_id => 114869287646134350)
        end

        let!(:jar_two) do
          Jar.create(:_id => 114869287646134388)
        end

        let!(:jar_three) do
          Jar.create(:_id => 114869287646134398)
        end

        context "when the documents are found" do

          let(:jars) do
            Jar.find([ jar_one.id, jar_two.id, jar_three.id ])
          end

          it "returns the documents from the database" do
            jars.should eq([ jar_one, jar_two, jar_three ])
          end
        end
      end

      context "when the id is found" do

        let!(:from_db) do
          Person.where(:title => "Sir").find([ person.id ])
        end

        it "returns the matching document" do
          from_db.should eq([ person ])
        end
      end

      context "when the id is not found" do

        context "when raising a not found error" do

          it "raises an error" do
            expect {
              Person.where(:title => "Sir").find([ BSON::ObjectId.new ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when not raising a not found error" do

          before do
            Mongoid.raise_not_found_error = false
          end

          after do
            Mongoid.raise_not_found_error = true
          end

          let!(:from_db) do
            Person.where(:title => "Sir").find([ BSON::ObjectId.new ])
          end

          it "returns an empty array" do
            from_db.should be_empty
          end
        end
      end
    end
  end

  describe "#in" do

    let(:criteria) do
      base.in(:title => ["title1", "title2"], :text => ["test"], :ssn => [nil, "1"])
    end

    it "adds the $in clause to the selector" do
      criteria.selector.should eq(
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }, :ssn => { "$in" => [nil, "1"] }
        }
      )
    end

    it "returns a copy" do
      criteria.in(:title => ["title1"]).should_not eql(criteria)
    end

    context "when existing in criteria exists" do

      let(:criteria) do
        base.
          in(:title => ["title1", "title2"]).
          in(:title => ["title2", "title3"], :text => ["test"])
      end

      it "intersects the existing criteria" do
        criteria.selector.should eq(
          {
            :title => {
              "$in" => ["title2"] }, :text => { "$in" => ["test"]
            }
          }
        )
      end
    end
  end

  describe "#includes" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    let!(:person) do
      Person.create
    end

    context "when including a has and belongs to many" do

      let!(:preference_one) do
        person.preferences.create(:name => "one")
      end

      let!(:preference_two) do
        person.preferences.create(:name => "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:preferences).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:preference_three) do
          person_two.preferences.create(:name => "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:preferences).asc(:_id).limit(1).entries
        end

        let(:preference_map) do
          Mongoid::IdentityMap[Preference.collection_name]
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          preference_map[preference_one.id].should eq(preference_one)
        end

        it "inserts the second document into the identity map" do
          preference_map[preference_two.id].should eq(preference_two)
        end

        it "does not insert the third preference into the identity map" do
          preference_map[preference_three.id].should be_nil
        end
      end
    end

    context "when including a has many" do

      let!(:post_one) do
        person.posts.create(:title => "one")
      end

      let!(:post_two) do
        person.posts.create(:title => "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling first on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).first
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when calling last on the criteria" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:from_db) do
          Person.includes(:posts).last
        end

        it "returns the correct documents" do
          from_db.should eq(person)
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:post_three) do
          person_two.posts.create(:title => "three")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:posts).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
        end

        it "does not insert the third post into the identity map" do
          Mongoid::IdentityMap[Post.collection_name][post_three.id].should be_nil
        end
      end
    end

    context "when including a has one" do

      let!(:game_one) do
        person.create_game(:name => "one")
      end

      let!(:game_two) do
        person.create_game(:name => "two")
      end

      context "when the criteria has no options" do

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "deletes the replaced document from the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        context "when asking from map or db" do

          let(:in_map) do
            Mongoid::IdentityMap[Game.collection_name][game_two.id]
          end

          let(:game) do
            Game.where("person_id" => person.id).from_map_or_db
          end

          it "returns the document from the map" do
            game.should equal(in_map)
          end
        end
      end

      context "when the criteria has limiting options" do

        let!(:person_two) do
          Person.create
        end

        let!(:game_three) do
          person_two.create_game(:name => "Skyrim")
        end

        before do
          Mongoid::IdentityMap.clear
        end

        let!(:criteria) do
          Person.includes(:game).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ person ])
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
        end

        it "does not load the extra child into the map" do
          Mongoid::IdentityMap[Game.collection_name][game_three.id].should be_nil
        end
      end
    end

    context "when including a belongs to" do

      let(:person_two) do
        Person.create
      end

      let!(:game_one) do
        person.create_game(:name => "one")
      end

      let!(:game_two) do
        person_two.create_game(:name => "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      context "when providing no options" do

        let!(:criteria) do
          Game.includes(:person).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one, game_two ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "inserts the second document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should eq(person_two)
        end
      end

      context "when the criteria has limiting options" do

        let!(:criteria) do
          Game.includes(:person).asc(:_id).limit(1).entries
        end

        it "returns the correct documents" do
          criteria.should eq([ game_one ])
        end

        it "inserts the first document into the identity map" do
          Mongoid::IdentityMap[Person.collection_name][person.id].should eq(person)
        end

        it "does not load the documents outside of the limit" do
          Mongoid::IdentityMap[Person.collection_name][person_two.id].should be_nil
        end
      end
    end

    context "when including multiples in the same criteria" do

      let!(:post_one) do
        person.posts.create(:title => "one")
      end

      let!(:post_two) do
        person.posts.create(:title => "two")
      end

      let!(:game_one) do
        person.create_game(:name => "one")
      end

      let!(:game_two) do
        person.create_game(:name => "two")
      end

      before do
        Mongoid::IdentityMap.clear
      end

      let!(:criteria) do
        Person.includes(:posts, :game).entries
      end

      it "returns the correct documents" do
        criteria.should eq([ person ])
      end

      it "inserts the first has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_one.id].should eq(post_one)
      end

      it "inserts the second has many document into the identity map" do
        Mongoid::IdentityMap[Post.collection_name][post_two.id].should eq(post_two)
      end

      it "removes the first has one document from the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_one.id].should be_nil
      end

      it "inserts the second has one document into the identity map" do
        Mongoid::IdentityMap[Game.collection_name][game_two.id].should eq(game_two)
      end
    end
  end

  describe "#near" do

    let!(:berlin) do
      Bar.create(:location => [ 52.30, 13.25 ])
    end

    let!(:prague) do
      Bar.create(:location => [ 50.5, 14.26 ])
    end

    let!(:paris) do
      Bar.create(:location => [ 48.48, 2.20 ])
    end

    let(:bars) do
      Bar.near(:location => [ 41.23, 2.9 ])
    end

    let(:criteria) do
      base.near(:field => [ 72, -44 ])
    end

    before do
      Bar.create_indexes
    end

    it "adds the $near modifier to the selector" do
      criteria.selector.should eq(
        { :field => { "$near" => [ 72, -44 ] } }
      )
    end

    it "returns the documents sorted closest to furthest" do
      bars.should eq([ paris, prague, berlin ])
    end
  end

  describe "#where" do

    let(:dob) do
      33.years.ago.to_date
    end

    let(:lunch_time) do
      30.minutes.ago
    end

    let!(:person) do
      Person.create(
        :title => "Sir",
        :dob => dob,
        :lunch_time => lunch_time,
        :age => 33,
        :aliases => [ "D", "Durran" ],
        :things => [ { :phone => 'HTC Incredible' } ]
      )
    end

    context "when passing in a range" do

      let!(:baby) do
        Person.create(:dob => Date.new(2011, 1, 1))
      end

      let!(:adult) do
        Person.create(:dob => Date.new(1980, 1, 1))
      end

      context "when the range matches documents" do

        let(:range) do
          Date.new(1970, 1, 1)..Date.new(2012, 1, 1)
        end

        let(:criteria) do
          Person.where(:dob => range)
        end

        it "includes the lower range value" do
          criteria.should include(baby)
        end

        it "includes the higher range value" do
          criteria.should include(adult)
        end
      end

      context "when the range does not match documents" do

        let(:range) do
          Date.new(2012, 1, 1)..Date.new(2014, 1, 1)
        end

        let(:criteria) do
          Person.where(:dob => range)
        end

        it "returns an empty result" do
          criteria.should be_empty
        end
      end
    end

    context "when searching for localized fields" do

      let!(:soda) do
        Product.create(:description => "sweet")
      end

      let!(:beer) do
        Product.create(:description => "hoppy")
      end

      before do
        ::I18n.locale = :de
        soda.update_attribute(:description, "suss")
        beer.update_attribute(:description, "hopfig")
      end

      let(:results) do
        Product.where(:description => "hopfig")
      end

      after do
        ::I18n.locale = :en
      end

      it "returns the results matching the correct locale" do
        results.should eq([ beer ])
      end
    end

    context "when providing 24 character strings" do

      context "when the field is not an id field" do

        let(:string) do
          BSON::ObjectId.new.to_s
        end

        let!(:person) do
          Person.create(:title => string)
        end

        let(:from_db) do
          Person.where(:title => string)
        end

        it "does not convert the field to a bson id" do
          from_db.should eq([ person ])
        end
      end
    end

    context "when providing string object ids" do

      context "when providing a single id" do

        let(:from_db) do
          Person.where(:_id => person.id.to_s).first
        end

        it "returns the matching documents" do
          from_db.should eq(person)
        end
      end
    end

    context "chaining multiple wheres" do

      context "when chaining on the same key" do

        let(:from_db) do
          Person.where(:title => "Maam").where(:title => "Sir")
        end

        it "overrides the previous key" do
          from_db.should eq([ person ])
        end
      end

      context "with different criteria on the same key" do

        it "merges criteria" do
          Person.where(:age.gt => 30).where(:age.lt => 40).should eq([person])
        end

        it "typecasts criteria" do
          before_dob = (dob - 1.month).to_s
          after_dob = (dob + 1.month).to_s
          Person.where(:dob.gt => before_dob).and(:dob.lt => after_dob).should eq([person])
        end

      end
    end

    context "with untyped criteria" do

      it "typecasts integers" do
        Person.where(:age => "33").should eq([ person ])
      end

      it "typecasts dates" do
        Person.where({:dob => dob.to_s}).should eq([ person ])
      end

      it "typecasts times with zones" do
        time = lunch_time.in_time_zone("Alaska")
        Person.where(:lunch_time => time).should eq([ person ])
      end

      it "typecasts array elements" do
        Person.where(:age.in => [17, "33"]).should eq([ person ])
      end

      it "typecasts size criterion to integer" do
        Person.where(:aliases.count => "2").should eq([ person ])
      end

      it "typecasts exists criterion to boolean" do
        Person.where(:score.exists => "f").should eq([ person ])
      end
    end

    context "with multiple complex criteria" do

      before do
        Person.create(:title => "Mrs", :age => 29)
        Person.create(:title => "Ms", :age => 41)
      end

      it "returns those matching both criteria" do
        Person.where(:age.gt => 30, :age.lt => 40).should eq([person])
      end

      it "returns nothing if in and nin clauses cancel each other out" do
        Person.any_in(:title => ["Sir"]).not_in(:title => ["Sir"]).should be_empty
      end

      it "returns nothing if in and nin clauses cancel each other out ordered the other way" do
        Person.not_in(:title => ["Sir"]).any_in(:title => ["Sir"]).should be_empty
      end

      it "returns the intersection of in and nin clauses" do
        Person.any_in(:title => ["Sir", "Mrs"]).not_in(:title => ["Mrs"]).should eq([person])
      end

      it "returns the intersection of two in clauses" do
        Person.where(:title.in => ["Sir", "Mrs"]).where(:title.in => ["Sir", "Ms"]).should eq([person])
      end
    end

    context "with complex criterion" do

      context "#all" do

        it "returns those matching an all clause" do
          Person.where(:aliases.all => ["D", "Durran"]).should eq([person])
        end
      end

      context "#exists" do

        it "returns those matching an exists clause" do
          Person.where(:title.exists => true).should eq([person])
        end
      end

      context "#gt" do

        it "returns those matching a gt clause" do
          Person.where(:age.gt => 30).should eq([person])
        end
      end

      context "#gte" do

        it "returns those matching a gte clause" do
          Person.where(:age.gte => 33).should eq([person])
        end
      end

      context "#in" do

        it "returns those matching an in clause" do
          Person.where(:title.in => ["Sir", "Madam"]).should eq([person])
        end

        it "allows nil" do
          Person.where(:ssn.in => [nil]).should eq([person])
        end
      end

      context "#lt" do

        it "returns those matching a lt clause" do
          Person.where(:age.lt => 34).should eq([person])
        end
      end

      context "#lte" do

        it "returns those matching a lte clause" do
          Person.where(:age.lte => 33).should eq([person])
        end
      end

      context "#ne" do

        it "returns those matching a ne clause" do
          Person.where(:age.ne => 50).should eq([person])
        end
      end

      context "#nin" do

        it "returns those matching a nin clause" do
          Person.where(:title.nin => ["Esquire", "Congressman"]).should eq([person])
        end
      end

      context "#size" do

        it "returns those matching a size clause" do
          Person.where(:aliases.count => 2).should eq([person])
        end
      end

      context "#match" do

        it "returns those matching a partial element in a list" do
          Person.where(:things.matches => { :phone => "HTC Incredible" }).should eq([person])
        end
      end
    end

    context "when searching on a custom type" do

      let(:criteria) do
        Bar.where(:lat_lng => {
          "$nearSphere" => [ 20, 20 ],
          "$maxDistance" => 1.5
        })
      end

      it "does not convert the selector" do
        criteria.selector.should eq({
          :lat_lng => {
            "$nearSphere" => [ 20, 20 ],
            "$maxDistance" => 1.5
          }
        })
      end
    end

    context "when providing a complex criteria with a boolean" do

      context "when the field is not defined" do

        let(:criteria) do
          Person.where(:service_area => { "$ne" => true })
        end

        it "creates the proper selector" do
          criteria.selector.should eq({ :service_area => { "$ne" => true }})
        end
      end

      context "when using matches on an existing field" do

        context "when the field is an array" do

          let(:criteria) do
            Person.where(:aliases.matches => {
              :verified => { "$ne" => true }
            })
          end

          it "properly typecasts the boolean values" do
            criteria.selector.should eq(
              { :aliases => { "$elemMatch" => { :verified => { "$ne" => true }}}}
            )
          end
        end
      end
    end

    context "when provided a hash" do

      context "with simple hash keys" do

        context "when no existing selector exists" do

          let(:criteria) do
            base.where(:title => "Title", :text => "Text")
          end

          it "adds the clause to the selector" do
            criteria.selector.should eq(
              { :title => "Title", :text => "Text" }
            )
          end
        end

        context "when an existing id selector exists" do

          let(:criteria) do
            base.where(:_id.in => [ 1, 2, 3 ]).where(:_id => 4)
          end

          it "adds the clause to the selector" do
            criteria.selector.should eq(
              { "$and" => [{ :_id => { "$in" => [ 1, 2, 3 ] } }, { :_id => 4 }] }
            )
          end
        end

        context "when field defined as an array" do

          context "when the value is not an array" do

            let(:criteria) do
              base.where(:aliases => "007")
            end

            it "does not convert the value" do
              criteria.selector.should eq({ :aliases => "007" })
            end
          end

          context "when the value is nil" do

            let(:criteria) do
              base.where(:aliases => nil)
            end

            it "does not convert the value" do
              criteria.selector.should eq({ :aliases => nil })
            end
          end

          context "when the value is an empty string" do

            let(:criteria) do
              base.where(:foreign_identity => "")
            end

            it "does not convert the value to nil" do
              criteria.selector.should eq(:foreign_identity => "")
            end
          end
        end
      end

      context "when merging a simple value into a complex one" do

        context "when merging normal fields" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:criteria) do
            base.any_in(:field => [ "test" ])
          end

          let(:merged) do
            criteria.where(:field => "testing")
          end

          it "overwrites the initial value" do
            merged.selector.should eq({ :field => "testing" })
          end
        end

        context "when merging id fields" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:criteria) do
            base.any_in(:_id => [ id ])
          end

          let(:merged) do
            criteria.where(:_id => id)
          end

          it "converts to an $and criteria" do
            merged.selector.should eq(
              { "$and" => [{ :_id => { "$in" => [ id ] }}, { :_id => id }] }
            )
          end
        end
      end

      context "when providing multiple values on the same complex attribute" do

        let(:criteria) do
          base.where(:owner_id.ne => nil).and(:owner_id.ne => 1)
        end

        it "returns a criteria with the combined selector" do
          criteria.selector.should eq(
            { :owner_id => { "$ne" => nil, "$ne" => 1 } }
          )
        end
      end

      context "with complex criterion" do

        context "#all" do

          let(:criteria) do
            base.where(:title.all => ["Sir"])
          end

          it "returns a selector matching an all clause" do
            criteria.selector.should eq(
              { :title => { "$all" => ["Sir"] } }
            )
          end
        end

        context "#exists" do

          let(:criteria) do
            base.where(:title.exists => true)
          end

          it "returns a selector matching an exists clause" do
            criteria.selector.should eq(
              { :title => { "$exists" => true } }
            )
          end
        end

        context "#gt" do

          let(:criteria) do
            base.where(:age.gt => 30)
          end

          it "returns a selector matching a gt clause" do
            criteria.selector.should eq(
              { :age => { "$gt" => 30 } }
            )
          end
        end

        context "#gte" do

          let(:criteria) do
            base.where(:age.gte => 33)
          end

          it "returns a selector matching a gte clause" do
            criteria.selector.should eq(
              { :age => { "$gte" => 33 } }
            )
          end
        end

        context "#in" do

          let(:criteria) do
            base.where(:title.in => ["Sir", "Madam"])
          end

          it "returns a selector matching an in clause" do
            criteria.selector.should eq(
              { :title => { "$in" => ["Sir", "Madam"] } }
            )
          end
        end

        context "#lt" do

          let(:criteria) do
            base.where(:age.lt => 34)
          end

          it "returns a selector matching a lt clause" do
            criteria.selector.should eq({ :age => { "$lt" => 34 }})
          end
        end

        context "#lte" do

          let(:criteria) do
            base.where(:age.lte => 33)
          end

          it "returns a selector matching a lte clause" do
            criteria.selector.should eq({ :age => { "$lte" => 33 }})
          end
        end

        context "#ne" do

          context "when a value is provided" do

            let(:criteria) do
              base.where(:age.ne => 50)
            end

            it "returns a selector matching a ne clause" do
              criteria.selector.should eq({ :age => { "$ne" => 50 }})
            end
          end

          context "when the value is blank" do

            let(:criteria) do
              base.where(:title.ne => "")
            end

            it "returns a selector matching a ne clause" do
              criteria.selector.should eq({ :title => { "$ne" => "" }})
            end
          end
        end

        context "#near" do

          let(:criteria) do
            base.where(:location.near => [ 50, 40 ])
          end

          it "returns a selector matching a ne clause" do
            criteria.selector.should eq(
              { :location => { "$near" => [ 50, 40 ] }}
            )
          end
        end

        context "#nin" do

          let(:criteria) do
            base.where(:title.nin => ["Esquire", "Congressman"])
          end

          it "returns a selector matching a nin clause" do
            criteria.selector.should eq(
              { :title => { "$nin" => ["Esquire", "Congressman"] }}
            )
          end
        end

        context "#size" do

          let(:criteria) do
            base.where(:aliases.count => 2)
          end

          it "returns a selector matching a size clause" do
            criteria.selector.should eq({ :aliases => { "$size" => 2 }})
          end
        end

        context "#near" do

          let(:criteria) do
            base.where(:location.within => { "$center" => [ [ 50, -40 ], 1 ] })
          end

          it "returns a selector matching a ne clause" do
            criteria.selector.should eq(
              { :location => { "$within" => { "$center" => [ [ 50, -40 ], 1 ] }}}
            )
          end
        end
      end
    end

    context "when provided a string" do

      let(:criteria) do
        base.where("this.date < new Date()")
      end

      it "adds the $where clause to the selector" do
        criteria.selector.should eq(
          { "$where" => "this.date < new Date()" }
        )
      end
    end
  end
end
