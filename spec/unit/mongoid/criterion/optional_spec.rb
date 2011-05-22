require "spec_helper"

describe Mongoid::Criterion::Optional do

  let(:base) do
    Mongoid::Criteria.new(Person)
  end

  describe "#ascending" do

    context "when providing a field" do

      let(:criteria) do
        base.ascending(:title)
      end

      it "adds the ascending sort criteria" do
        criteria.options[:sort].should == [[ :title, :asc ]]
      end
    end

    context "when providing nothing" do

      let(:criteria) do
        base.ascending
      end

      it "does not modify the sort criteria" do
        criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#asc" do

    context "when providing a field" do

      let(:criteria) do
        base.asc(:title, :dob)
      end

      it "adds the ascending sort criteria" do
        criteria.options[:sort].should == [[ :title, :asc ], [ :dob, :asc ]]
      end
    end

    context "when providing nothing" do

      let(:criteria) do
        base.asc
      end

      it "does not modify the sort criteria" do
        criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#cache" do

    let(:criteria) do
      base.cache
    end

    it "sets the cache option on the criteria" do
      criteria.options[:cache].should be_true
    end

    it "returns a copy" do
      base.cache.should_not eql(base)
    end
  end

  describe "#cached?" do

    context "when the criteria has a cache option" do

      let(:criteria) do
        base.cache
      end

      it "returns true" do
        criteria.cached?.should be_true
      end
    end

    context "when the criteria has no cache option" do

      it "returns false" do
        base.cached?.should be_false
      end
    end
  end

  context "when chaining sort criteria" do

    let(:criteria) do
      base.asc(:title).desc(:dob, :name).order_by(:score.asc)
    end

    it "does not overwrite any previous criteria" do
      criteria.options[:sort].should ==
        [[ :title, :asc ], [ :dob, :desc ], [ :name, :desc ], [ :score, :asc ]]
    end
  end

  describe "#descending" do

    context "when providing a field" do

      let(:criteria) do
        base.descending(:title)
      end

      it "adds the descending sort criteria" do
        criteria.options[:sort].should == [[ :title, :desc ]]
      end
    end

    context "when providing nothing" do

      let(:criteria) do
        base.descending
      end

      it "does not modify the sort criteria" do
        criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#desc" do

    context "when providing a field" do

      let(:criteria) do
        base.desc(:title, :dob)
      end

      it "adds the descending sort criteria" do
        criteria.options[:sort].should == [[ :title, :desc ], [ :dob, :desc ]]
      end
    end

    context "when providing nothing" do

      let(:criteria) do
        base.desc
      end

      it "does not modify the sort criteria" do
        criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#extras" do

    context "filtering" do
      context "when extras are provided" do

        let(:criteria) do
          base.limit(10).extras({ :skip => 10 })
        end

        it "adds the extras to the options" do
          criteria.options.should == { :skip => 10, :limit => 10 }
        end
      end
    end

    it "returns a copy" do
      base.extras({}).should_not eql(base)
    end
  end

  describe "#id" do

    context "with not using object ids" do

      before do
        @previous_id_type = Person.fields["_id"].type
        Person.identity :type => String
      end

      after do
        Person.identity :type => @previous_id_type
      end

      context "when passing a single id" do

        context "when the id is a string" do

          let(:id) do
            BSON::ObjectId.new.to_s
          end

          let(:criteria) do
            base.for_ids(id)
          end

          it "adds the _id query to the selector" do
            criteria.selector.should == { :_id => id }
          end

          it "returns a copy" do
            criteria.for_ids(id).should_not eql(criteria)
          end
        end

        context "when the id is an object id" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:criteria) do
            base.for_ids(id)
          end

          it "adds the _id query to the selector" do
            criteria.selector.should == { :_id => id }
          end

          it "returns a copy" do
            criteria.for_ids(id).should_not eql(criteria)
          end
        end
      end

      context "when passing in an array of ids" do

        let(:ids) do
          3.times.map { BSON::ObjectId.new.to_s }
        end

        let(:criteria) do
          base.for_ids(ids)
        end

        it "adds the _id query to the selector" do
          criteria.selector.should ==
            { :_id => { "$in" => ids } }
        end
      end

      context "when passing in an array with only one id" do

        let(:ids) do
          [ BSON::ObjectId.new ]
        end

        it "adds the _id query to the selector" do
          base.for_ids(ids).selector.should == { :_id => ids.first }
        end
      end
    end

    context "when using object ids" do

      before do
        @previous_id_type = Person.fields["_id"].type
        Person.identity :type => BSON::ObjectId
      end

      after do
        Person.identity :type => @previous_id_type
      end

      context "when passing a single id" do

        let(:id) do
          BSON::ObjectId.new.to_s
        end

        context "when the id is a string" do

          let(:criteria) do
            base.for_ids(id)
          end

          it "adds the _id query to the selector convert like BSON::ObjectId" do
            criteria.selector.should == { :_id => BSON::ObjectId(id) }
          end

          it "returns a copy" do
            criteria.for_ids(id).should_not eql(criteria)
          end
        end

        context "when the id is an object id" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:criteria) do
            base.for_ids(id)
          end

          it "adds the _id query to the selector without cast" do
            criteria.selector.should == { :_id => id }
          end

          it "returns a copy" do
            criteria.for_ids(id).should_not eql(criteria)
          end
        end
      end

      context "when passing in an array of ids" do

        let(:ids) do
          3.times.map { BSON::ObjectId.new.to_s }
        end

        let(:criteria) do
          base.for_ids(ids)
        end

        it "adds the _id query to the selector with all ids like BSON::ObjectId" do
          criteria.selector.should ==
            { :_id => { "$in" => ids.map { |i| BSON::ObjectId(i) } } }
        end
      end
    end
  end

  describe "#limit" do

    context "when value provided" do

      let(:criteria) do
        base.limit(100)
      end

      it "adds the limit to the options" do
        criteria.options.should == { :limit => 100 }
      end
    end

    context "when value not provided" do

      let(:criteria) do
        base.limit
      end

      it "defaults to 20" do
        criteria.options.should == { :limit => 20 }
      end
    end

    it "returns a copy" do
      base.limit.should_not eql(base)
    end
  end

  describe "#offset" do

    context "when the skip option exists" do

      let(:criteria) do
        base.extras({ :skip => 20 })
      end

      it "returns the skip option" do
        criteria.offset.should == 20
      end
    end

    context "when an argument is provided" do

      let(:criteria) do
        base.offset(40)
      end

      it "delegates to skip" do
        criteria.options[:skip].should == 40
      end
    end

    context "when no option exists" do
      it "returns nil" do
        base.offset.should be_nil
        base.options[:skip].should be_nil
      end
    end
  end

  describe "#order_by" do

    context "when field names and direction specified" do

      let(:criteria) do
        base.order_by([[:title, :asc]]).order_by([[:text, :desc]])
      end

      it "adds the sort to the options" do
        criteria.options.should == { :sort => [[:title, :asc], [:text, :desc]] }
      end
    end

    context "when providing a hash of options" do

      let(:criteria) do
        base.order_by(:title => :asc, :text => :desc)
      end

      it "adds the sort to the options" do
        criteria.options[:sort].should include([:title, :asc], [:text, :desc])
      end
    end

    context "when providing multiple symbols" do

      let(:criteria) do
        base.order_by(:title.asc, :text.desc)
      end

      it "adds the sort to the options" do
        criteria.options.should == { :sort => [[:title, :asc], [:text, :desc]] }
      end
    end

    it "returns a copy" do
      base.order_by.should_not eql(base)
    end
  end

  describe "#skip" do

    context "when value provided" do

      let(:criteria) do
        base.skip(20)
      end

      it "adds the skip value to the options" do
        criteria.options.should == { :skip => 20 }
      end
    end

    context "when value not provided" do

      let(:criteria) do
        base.skip
      end

      it "defaults to zero" do
        criteria.options.should == { :skip => 0 }
      end
    end

    it "returns a copy" do
      base.skip.should_not eql(base)
    end
  end

  describe "#type" do

    context "when the type is a string" do

      let(:criteria) do
        base.type('Browser')
      end

      it "adds the _type query to the selector" do
        criteria.selector.should == { :_type => { '$in' => ['Browser'] } }
      end

      it "returns a copy" do
        base.type('Browser').should_not eql(base)
      end
    end

    context "when the type is an Array of type" do

      let(:criteria) do
        base.type(['Browser', 'Firefox'])
      end

      it "adds the _type query to the selector" do
        criteria.selector.should == { :_type => { '$in' => ['Browser', 'Firefox'] } }
      end

      it "returns a copy" do
        base.type(['Browser', 'Firefox']).should_not eql(base)
      end
    end
  end
end
