require "spec_helper"

describe Mongoid::Criterion::Inclusion do

  let(:criteria) do
    Mongoid::Criteria.new(Person)
  end

  describe "#all" do

    it "adds the $all query to the selector" do
      criteria.all(:title => ["title1", "title2"])
      criteria.selector.should ==
        {
          :title => { "$all" => ["title1", "title2"] }
        }
    end

    it "returns self" do
      criteria.all(:title => [ "title1" ]).should == criteria
    end

    context "when all criteria exists" do

      before do
        criteria.all(:title => ["title1", "title2"])
        criteria.all(:title => ["title3"], :another => ["value"])
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

      it "adds the clause to the selector" do
        criteria.and(:title => "Title", :text => "Text")
        criteria.selector.should ==
          {
            :title => "Title",
            :text => "Text"
          }
      end
    end

    context "when provided a string" do

      it "adds the $where clause to the selector" do
        criteria.and("this.date < new Date()")
        criteria.selector.should ==
          {
            "$where" => "this.date < new Date()"
          }
      end
    end

    it "returns self" do
      criteria.and.should == criteria
    end
  end

  describe "#any_of" do

    context "when provided a hash" do

      context "on different fields" do

        before do
          criteria.any_of({ :field1 => "test" }, { :field2 => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should ==
            { "$or" => [ { :field1 => "test" }, { :field2 => "testy" } ] }
        end
      end

      context "on the same fields" do

        before do
          criteria.any_of( {:field1 => "test" }, { :field1.lt => "testy" })
        end

        it "adds the $or criteria to the selector" do
          criteria.selector.should ==
            { "$or" => [ { :field1 => "test" }, { :field1 => { "$lt" => "testy" } } ] }
        end
      end
    end
  end

  describe "#in" do

    it "adds the $in clause to the selector" do
      criteria.in(:title => ["title1", "title2"], :text => ["test"])
      criteria.selector.should ==
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        }
    end

    it "#any_in is aliased to #in" do
      criteria.any_in(:title => ["title1", "title2"], :text => ["test"])
      criteria.selector.should ==
        {
          :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] }
        }
    end

    it "returns self" do
      criteria.in(:title => ["title1"]).should == criteria
    end

    context "when existing in criteria exists" do

      before do
        criteria.in(:title => ["title1", "title2"])
        criteria.in(:title => ["title3"], :text => ["test"])
      end

      it "appends to the existing criteria" do
        criteria.selector.should ==
          {
            :title => { "$in" => ["title1", "title2", "title3"] }, :text => { "$in" => ["test"] }
          }
      end
    end
  end

  describe "#near" do

    it "adds the $near modifier to the selector" do
      criteria.near(:field => [ 72, -44 ])
      criteria.selector.should ==
        { :field => { "$near" => [ 72, -44 ] } }
    end
  end

  describe "#where" do

    context "when provided a hash" do

      context "with simple hash keys" do

        it "adds the clause to the selector" do
          criteria.where(:title => "Title", :text => "Text")
          criteria.selector.should ==
            { :title => "Title", :text => "Text" }
        end

        context "when field defined as an array" do

          before do
            criteria.where(:aliases => "007")
          end

          it "allows a single value to be passed" do
            criteria.selector.should == { :aliases => "007" }
          end
        end
      end

      context "with complex criterion" do

        context "#all" do

          it "returns a selector matching an all clause" do
            criteria.where(:title.all => ["Sir"])
            criteria.selector.should ==
              { :title => { "$all" => ["Sir"] } }
          end
        end

        context "#exists" do

          it "returns a selector matching an exists clause" do
            criteria.where(:title.exists => true)
            criteria.selector.should ==
              { :title => { "$exists" => true } }
          end
        end

        context "#gt" do

          it "returns a selector matching a gt clause" do
            criteria.where(:age.gt => 30)
            criteria.selector.should ==
              { :age => { "$gt" => 30 } }
          end
        end

        context "#gte" do

          it "returns a selector matching a gte clause" do
            criteria.where(:age.gte => 33)
            criteria.selector.should ==
              { :age => { "$gte" => 33 } }
          end
        end

        context "#in" do

          it "returns a selector matching an in clause" do
            criteria.where(:title.in => ["Sir", "Madam"])
            criteria.selector.should ==
              { :title => { "$in" => ["Sir", "Madam"] } }
          end
        end

        context "#lt" do

          it "returns a selector matching a lt clause" do
            criteria.where(:age.lt => 34)
            criteria.selector.should ==
              { :age => { "$lt" => 34 } }
          end
        end

        context "#lte" do

          it "returns a selector matching a lte clause" do
            criteria.where(:age.lte => 33)
            criteria.selector.should ==
              { :age => { "$lte" => 33 } }
          end
        end

        context "#ne" do

          it "returns a selector matching a ne clause" do
            criteria.where(:age.ne => 50)
            criteria.selector.should ==
              { :age => { "$ne" => 50 } }
          end
        end

        context "#near" do

          it "returns a selector matching a ne clause" do
            criteria.where(:location.near => [ 50, 40 ])
            criteria.selector.should ==
              { :location => { "$near" => [ 50, 40 ] } }
          end
        end

        context "#nin" do

          it "returns a selector matching a nin clause" do
            criteria.where(:title.nin => ["Esquire", "Congressman"])
            criteria.selector.should ==
              { :title => { "$nin" => ["Esquire", "Congressman"] } }
          end
        end

        context "#size" do

          it "returns a selector matching a size clause" do
            criteria.where(:aliases.size => 2)
            criteria.selector.should ==
              { :aliases => { "$size" => 2 } }
          end
        end

        context "#near" do

          it "returns a selector matching a ne clause" do
            criteria.where(:location.within => { "$center" => [ [ 50, -40 ], 1 ] })
            criteria.selector.should ==
              { :location => { "$within" => { "$center" => [ [ 50, -40 ], 1 ] } } }
          end
        end
      end
    end

    context "when provided a string" do

      it "adds the $where clause to the selector" do
        criteria.where("this.date < new Date()")
        criteria.selector.should ==
          { "$where" => "this.date < new Date()" }
      end
    end

    it "returns self" do
      criteria.where.should == criteria
    end
  end
end
