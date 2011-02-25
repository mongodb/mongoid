require "spec_helper"

describe Mongoid::Criterion::Inclusion do

  before do
    Person.delete_all
  end

  describe "#all_in" do

    context "when providing string ids" do

      let!(:person) do
        Person.create(:ssn => "444-44-4444")
      end

      let(:from_db) do
        Person.all_in(:_id => [ person.id.to_s ])
      end

      it "returns the matching documents" do
        from_db.should == [ person ]
      end
    end
  end

  describe "#any_in" do

    context "when the field value is nil" do

      let!(:person) do
        Person.create(:title => nil)
      end

      context "when searching for any value" do

        let(:from_db) do
          Person.any_in(:title => [ true, false, nil ])
        end

        it "returns the matching documents" do
          from_db.should == [ person ]
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
          from_db.should == [ person ]
        end
      end
    end

    context "when providing string ids" do

      let!(:person) do
        Person.create(:ssn => "444-44-4444")
      end

      let(:from_db) do
        Person.any_in(:_id => [ person.id.to_s ])
      end

      it "returns the matching documents" do
        from_db.should == [ person ]
      end
    end
  end

  describe "#any_of" do

    let!(:person_one) do
      Person.create(:title => "Sir", :age => 5, :ssn => "098-76-5432")
    end

    let!(:person_two) do
      Person.create(:title => "Sir", :age => 7, :ssn => "098-76-5433")
    end

    let!(:person_three) do
      Person.create(:title => "Madam", :age => 1, :ssn => "098-76-5434")
    end

    context "with a single match" do

      let(:from_db) do
        Person.where(:title => "Madam").any_of(:age => 1)
      end

      it "returns any matching documents" do
        from_db.should == [ person_three ]
      end
    end

    context "when chaining for multiple matches" do

      let(:from_db) do
        Person.any_of({ :age => 7 }, { :age.lt => 3 })
      end

      it "returns any matching documents" do
        from_db.should == [ person_two, person_three ]
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
          from_db.should == [ person_one, person_two ]
        end
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
            from_db.should == person
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

      context "when the id is found" do

        let!(:from_db) do
          Person.where(:title => "Sir").find([ person.id ])
        end

        it "returns the matching document" do
          from_db.should == [ person ]
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

    before do
      Bar.create_indexes
    end

    it "returns the documents sorted closest to furthest" do
      bars.should == [ paris, prague, berlin ]
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

    context "when providing string object ids" do

      context "when providing a single id" do

        let(:from_db) do
          Person.where(:_id => person.id.to_s).first
        end

        it "returns the matching documents" do
          from_db.should == person
        end
      end
    end

    context "chaining multiple wheres" do

      context "when chaining on the same key" do

        let(:from_db) do
          Person.where(:title => "Maam").where(:title => "Sir")
        end

        it "overrides the previous key" do
          from_db.should == [ person ]
        end
      end

      context "with different criteria on the same key" do

        it "merges criteria" do
          Person.where(:age.gt => 30).where(:age.lt => 40).should == [person]
        end

        it "typecasts criteria" do
          before_dob = (dob - 1.month).to_s
          after_dob = (dob + 1.month).to_s
          Person.where(:dob.gt => before_dob).and(:dob.lt => after_dob).should == [person]
        end

      end
    end

    context "with untyped criteria" do

      it "typecasts integers" do
        Person.where(:age => "33").should == [ person ]
      end

      it "typecasts datetimes" do
        Person.where(:lunch_time => lunch_time.to_s).should == [ person ]
      end

      it "typecasts dates" do
        Person.where({:dob => dob.to_s}).should == [ person ]
      end

      it "typecasts times with zones" do
        time = lunch_time.in_time_zone("Alaska")
        Person.where(:lunch_time => time).should == [ person ]
      end

      it "typecasts array elements" do
        Person.where(:age.in => [17, "33"]).should == [ person ]
      end

      it "typecasts size criterion to integer" do
        Person.where(:aliases.size => "2").should == [ person ]
      end

      it "typecasts exists criterion to boolean" do
        Person.where(:score.exists => "f").should == [ person ]
      end
    end

    context "with multiple complex criteria" do

      before do
        Person.create(:title => "Mrs", :age => 29)
        Person.create(:title => "Ms", :age => 41)
      end

      it "returns those matching both criteria" do
        Person.where(:age.gt => 30, :age.lt => 40).should == [person]
      end

      it "returns nothing if in and nin clauses cancel each other out" do
        Person.any_in(:title => ["Sir"]).not_in(:title => ["Sir"]).should == []
      end

      it "returns nothing if in and nin clauses cancel each other out ordered the other way" do
        Person.not_in(:title => ["Sir"]).any_in(:title => ["Sir"]).should == []
      end

      it "returns the intersection of in and nin clauses" do
        Person.any_in(:title => ["Sir", "Mrs"]).not_in(:title => ["Mrs"]).should == [person]
      end
    end

    context "with complex criterion" do

      context "#all" do

        it "returns those matching an all clause" do
          Person.where(:aliases.all => ["D", "Durran"]).should == [person]
        end
      end

      context "#exists" do

        it "returns those matching an exists clause" do
          Person.where(:title.exists => true).should == [person]
        end
      end

      context "#gt" do

        it "returns those matching a gt clause" do
          Person.where(:age.gt => 30).should == [person]
        end
      end

      context "#gte" do

        it "returns those matching a gte clause" do
          Person.where(:age.gte => 33).should == [person]
        end
      end

      context "#in" do

        it "returns those matching an in clause" do
          Person.where(:title.in => ["Sir", "Madam"]).should == [person]
        end
      end

      context "#lt" do

        it "returns those matching a lt clause" do
          Person.where(:age.lt => 34).should == [person]
        end
      end

      context "#lte" do

        it "returns those matching a lte clause" do
          Person.where(:age.lte => 33).should == [person]
        end
      end

      context "#ne" do

        it "returns those matching a ne clause" do
          Person.where(:age.ne => 50).should == [person]
        end
      end

      context "#nin" do

        it "returns those matching a nin clause" do
          Person.where(:title.nin => ["Esquire", "Congressman"]).should == [person]
        end
      end

      context "#size" do

        it "returns those matching a size clause" do
          Person.where(:aliases.size => 2).should == [person]
        end
      end

      context "#match" do

        it "returns those matching a partial element in a list" do
          Person.where(:things.matches => { :phone => "HTC Incredible" }).should == [person]
        end
      end
    end
  end
end
