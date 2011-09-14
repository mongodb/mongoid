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
      criteria.selector.should ==
        {
          :title => { "$all" => ["title1", "title2"] }
        }
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
        criteria.selector.should ==
          {
            :title => { "$all" => [ "title1", "title2", "title3" ] },
            :another => { "$all" => [ "value" ] }
          }
      end
    end
  end

  describe "#and" do

    context "when provided a hash" do

      let(:criteria) do
        base.and(:title => "Title", :text => "Text")
      end

      it "adds the clause to the selector" do
        criteria.selector.should ==
          {
            :title => "Title",
            :text => "Text"
          }
      end
    end

    context "when provided a string" do

      let(:criteria) do
        base.and("this.date < new Date()")
      end

      it "adds the $where clause to the selector" do
        criteria.selector.should ==
          {
            "$where" => "this.date < new Date()"
          }
      end
    end

    it "returns a copy" do
      base.and.should_not eql(base)
    end
  end

  describe "#any_in" do

    let(:criteria) do
      base.any_in(:title => ["title1", "title2"], :text => ["test"])
    end

    it "aliases to #in" do
      criteria.selector.should ==
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        }
    end
  end

  describe "#any_of" do

    context "when provided a hash" do

      context "on different fields" do

        let(:criteria) do
          base.any_of({ :field1 => "test" }, { :field2 => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should ==
            { "$or" => [ { :field1 => "test" }, { :field2 => "testy" } ] }
        end
      end

      context "on the same fields" do

        let(:criteria) do
          base.any_of({:field1 => "test" }, { :field1.lt => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should ==
            { "$or" => [ { :field1 => "test" }, { :field1 => { "$lt" => "testy" } } ] }
        end
      end

      context "when supplying an array" do

        let(:criteria) do
          base.any_of([{:field1 => "test" }, { :field1.lt => "testy" }])
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should ==
            { "$or" => [ { :field1 => "test" }, { :field1 => { "$lt" => "testy" } } ] }
        end
      end
    end
  end

  describe "#in" do

    let(:criteria) do
      base.in(:title => ["title1", "title2"], :text => ["test"], :ssn => [nil, "1"])
    end

    it "adds the $in clause to the selector" do
      criteria.selector.should ==
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }, :ssn => { "$in" => [nil, "1"] }
        }
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
        criteria.selector.should ==
          {
            :title => {
              "$in" => ["title2"] }, :text => { "$in" => ["test"]
            }
          }
      end
    end
  end

  describe "#also_in" do

    let(:criteria) do
      base.also_in(:title => ["title1", "title2"], :text => ["test"])
    end

    it "adds the $in clause to the selector" do
      criteria.selector.should ==
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        }
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
        criteria.selector.should ==
          {
            :title => {
              "$in" => ["title1", "title2", "title3"] }, :text => { "$in" => ["test"]
            }
          }
      end
    end
  end

  describe "#includes" do

    before(:all) do
      Mongoid.identity_map_enabled = true
    end

    after(:all) do
      Mongoid.identity_map_enabled = false
    end

    context "when including a has many" do

      let(:driver) do
        stub
      end

      let(:collection) do
        stub(:driver => driver)
      end

      let(:post_collection) do
        stub
      end

      before do
        Person.stubs(:collection).returns(collection)
        Post.stubs(:collection).returns(post_collection)
      end

      context "when the includes is the first call" do

        let(:criteria) do
          base.includes(:posts)
        end

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "_id" => 1 }}
        end

        let(:ids) do
          [{ "_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          collection.expects(:find).with({}, {}).returns([ person ])
          post_collection.expects(:find).with(
            { "person_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ post ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ person ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Post][{"person_id" => person.id}].should eq([ post ])
        end
      end

      context "when the includes is not the last call" do

        let(:criteria) do
          base.includes(:posts).all
        end

        let(:person) do
          Person.new
        end

        let(:post) do
          Post.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "_id" => 1 }}
        end

        let(:ids) do
          [{ "_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          collection.expects(:find).with({}, {}).returns([ person ])
          post_collection.expects(:find).with(
            { "person_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ post ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ person ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Post][{"person_id" => person.id}].should eq([ post ])
        end
      end
    end

    context "when including a has one" do

      let(:driver) do
        stub
      end

      let(:collection) do
        stub(:driver => driver)
      end

      let(:game_collection) do
        stub
      end

      before do
        Person.stubs(:collection).returns(collection)
        Game.stubs(:collection).returns(game_collection)
      end

      context "when the includes is the first call" do

        let(:criteria) do
          base.includes(:game)
        end

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "_id" => 1 }}
        end

        let(:ids) do
          [{ "_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          collection.expects(:find).with({}, {}).returns([ person ])
          game_collection.expects(:find).with(
            { "person_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ game ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ person ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Game][{"person_id" => person.id}].should eq(game)
        end
      end

      context "when the includes is not the last call" do

        let(:criteria) do
          base.includes(:game).all
        end

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "_id" => 1 }}
        end

        let(:ids) do
          [{ "_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          collection.expects(:find).with({}, {}).returns([ person ])
          game_collection.expects(:find).with(
            { "person_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ game ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ person ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Game][{"person_id" => person.id}].should eq(game)
        end
      end
    end

    context "when including a belongs to" do

      let(:driver) do
        stub
      end

      let(:collection) do
        stub
      end

      let(:game_collection) do
        stub(:driver => driver)
      end

      before do
        Game.stubs(:collection).returns(game_collection)
        Person.stubs(:collection).returns(collection)
      end

      context "when the includes is the first call" do

        let(:criteria) do
          Mongoid::Criteria.new(Game).includes(:person)
        end

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "person_id" => 1 }}
        end

        let(:ids) do
          [{ "person_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          game_collection.expects(:find).with({}, {}).returns([ game ])
          collection.expects(:find).with(
            { "_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ person ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ game ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Person][person.id].should eq(person)
        end
      end

      context "when the includes is not the last call" do

        let(:criteria) do
          Mongoid::Criteria.new(Game).includes(:person).all
        end

        let(:person) do
          Person.new
        end

        let(:game) do
          Game.new(:person_id => person.id)
        end

        let(:fields) do
          { :fields => { "person_id" => 1 }}
        end

        let(:ids) do
          [{ "person_id" => person.id }]
        end

        let(:map) do
          Mongoid::IdentityMap
        end

        before do
          driver.expects(:find).with({}, fields).returns(ids)
          game_collection.expects(:find).with({}, {}).returns([ game ])
          collection.expects(:find).with(
            { "_id" => { "$in" => [ person.id ] }}, {}
          ).returns([ person ])
        end

        it "returns the documents" do
          criteria.entries.should eq([ game ])
        end

        it "puts the related documents in the identity map" do
          criteria.entries
          map[Person][person.id].should eq(person)
        end
      end
    end
  end

  describe "#near" do

    let(:criteria) do
      base.near(:field => [ 72, -44 ])
    end

    it "adds the $near modifier to the selector" do
      criteria.selector.should ==
        { :field => { "$near" => [ 72, -44 ] } }
    end
  end

  describe "#where" do

    context "when provided a hash" do

      context "with simple hash keys" do

        let(:criteria) do
          base.where(:title => "Title", :text => "Text")
        end

        it "adds the clause to the selector" do
          criteria.selector.should ==
            { :title => "Title", :text => "Text" }
        end

        context "when field defined as an array" do

          context "when the value is not an array" do

            let(:criteria) do
              base.where(:aliases => "007")
            end

            it "does not convert the value" do
              criteria.selector.should == { :aliases => "007" }
            end
          end

          context "when the value is nil" do

            let(:criteria) do
              base.where(:aliases => nil)
            end

            it "does not convert the value" do
              criteria.selector.should == { :aliases => nil }
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

        let(:id) do
          BSON::ObjectId.new
        end

        let(:criteria) do
          base.any_in(:_id => [ id ])
        end

        let(:merged) do
          criteria.where(:_id => id)
        end

        it "overwrites the initial value" do
          merged.selector.should eq({ :_id => id })
        end
      end

      context "when providing multiple values on the same complex attribute" do

        let(:criteria) do
          base.where(:owner_id.ne => nil).and(:owner_id.ne => 1)
        end

        it "returns a criteria with the combined selector" do
          criteria.selector.should ==
            { :owner_id => { "$ne" => nil, "$ne" => 1 } }
        end
      end

      context "with complex criterion" do

        context "#all" do

          let(:criteria) do
            base.where(:title.all => ["Sir"])
          end

          it "returns a selector matching an all clause" do
            criteria.selector.should ==
              { :title => { "$all" => ["Sir"] } }
          end
        end

        context "#exists" do

          let(:criteria) do
            base.where(:title.exists => true)
          end

          it "returns a selector matching an exists clause" do
            criteria.selector.should ==
              { :title => { "$exists" => true } }
          end
        end

        context "#gt" do

          let(:criteria) do
            base.where(:age.gt => 30)
          end

          it "returns a selector matching a gt clause" do
            criteria.selector.should ==
              { :age => { "$gt" => 30 } }
          end
        end

        context "#gte" do

          let(:criteria) do
            base.where(:age.gte => 33)
          end

          it "returns a selector matching a gte clause" do
            criteria.selector.should ==
              { :age => { "$gte" => 33 } }
          end
        end

        context "#in" do

          let(:criteria) do
            base.where(:title.in => ["Sir", "Madam"])
          end

          it "returns a selector matching an in clause" do
            criteria.selector.should ==
              { :title => { "$in" => ["Sir", "Madam"] } }
          end
        end

        context "#lt" do

          let(:criteria) do
            base.where(:age.lt => 34)
          end

          it "returns a selector matching a lt clause" do
            criteria.selector.should ==
              { :age => { "$lt" => 34 } }
          end
        end

        context "#lte" do

          let(:criteria) do
            base.where(:age.lte => 33)
          end

          it "returns a selector matching a lte clause" do
            criteria.selector.should ==
              { :age => { "$lte" => 33 } }
          end
        end

        context "#ne" do

          context "when a value is provided" do

            let(:criteria) do
              base.where(:age.ne => 50)
            end

            it "returns a selector matching a ne clause" do
              criteria.selector.should ==
                { :age => { "$ne" => 50 } }
            end
          end

          context "when the value is blank" do

            let(:criteria) do
              base.where(:title.ne => "")
            end

            it "returns a selector matching a ne clause" do
              criteria.selector.should ==
                { :title => { "$ne" => "" } }
            end
          end
        end

        context "#near" do

          let(:criteria) do
            base.where(:location.near => [ 50, 40 ])
          end

          it "returns a selector matching a ne clause" do
            criteria.selector.should ==
              { :location => { "$near" => [ 50, 40 ] } }
          end
        end

        context "#nin" do

          let(:criteria) do
            base.where(:title.nin => ["Esquire", "Congressman"])
          end

          it "returns a selector matching a nin clause" do
            criteria.selector.should ==
              { :title => { "$nin" => ["Esquire", "Congressman"] } }
          end
        end

        context "#size" do

          let(:criteria) do
            base.where(:aliases.size => 2)
          end

          it "returns a selector matching a size clause" do
            criteria.selector.should ==
              { :aliases => { "$size" => 2 } }
          end
        end

        context "#near" do

          let(:criteria) do
            base.where(:location.within => { "$center" => [ [ 50, -40 ], 1 ] })
          end

          it "returns a selector matching a ne clause" do
            criteria.selector.should ==
              { :location => { "$within" => { "$center" => [ [ 50, -40 ], 1 ] } } }
          end
        end
      end
    end

    context "when provided a string" do

      let(:criteria) do
        base.where("this.date < new Date()")
      end

      it "adds the $where clause to the selector" do
        criteria.selector.should ==
          { "$where" => "this.date < new Date()" }
      end
    end

    it "returns a copy" do
      base.where.should_not eql(base)
    end
  end
end
