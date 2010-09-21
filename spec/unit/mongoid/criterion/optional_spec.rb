require "spec_helper"

describe Mongoid::Criterion::Optional do

  before do
    @criteria = Mongoid::Criteria.new(Person)
    @canvas_criteria = Mongoid::Criteria.new(Canvas)
  end

  describe "#ascending" do

    context "when providing a field" do

      before do
        @criteria.ascending(:title)
      end

      it "adds the ascending sort criteria" do
        @criteria.options[:sort].should == [[ :title, :asc ]]
      end
    end

    context "when providing nothing" do

      before do
        @criteria.ascending
      end

      it "does not modify the sort criteria" do
        @criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#asc" do

    context "when providing a field" do

      before do
        @criteria.asc(:title, :dob)
      end

      it "adds the ascending sort criteria" do
        @criteria.options[:sort].should == [[ :title, :asc ], [ :dob, :asc ]]
      end
    end

    context "when providing nothing" do

      before do
        @criteria.asc
      end

      it "does not modify the sort criteria" do
        @criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#cache" do

    it "sets the cache option on the criteria" do
      @criteria.cache
      @criteria.options[:cache].should be_true
    end

    it "returns self" do
      @criteria.cache.should == @criteria
    end
  end

  describe "#cached?" do

    context "when the criteria has a cache option" do

      before do
        @criteria.cache
      end

      it "returns true" do
        @criteria.cached?.should be_true
      end
    end

    context "when the criteria has no cache option" do

      it "returns false" do
        @criteria.cached?.should be_false
      end
    end
  end

  context "when chaining sort criteria" do

    before do
      @criteria.asc(:title).desc(:dob, :name).order_by(:score.asc)
    end

    it "does not overwrite any previous criteria" do
      @criteria.options[:sort].should ==
        [[ :title, :asc ], [ :dob, :desc ], [ :name, :desc ], [ :score, :asc ]]
    end
  end

  describe "#descending" do

    context "when providing a field" do

      before do
        @criteria.descending(:title)
      end

      it "adds the descending sort criteria" do
        @criteria.options[:sort].should == [[ :title, :desc ]]
      end
    end

    context "when providing nothing" do

      before do
        @criteria.descending
      end

      it "does not modify the sort criteria" do
        @criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#desc" do

    context "when providing a field" do

      before do
        @criteria.desc(:title, :dob)
      end

      it "adds the descending sort criteria" do
        @criteria.options[:sort].should == [[ :title, :desc ], [ :dob, :desc ]]
      end
    end

    context "when providing nothing" do

      before do
        @criteria.desc
      end

      it "does not modify the sort criteria" do
        @criteria.options[:sort].should be_nil
      end
    end
  end

  describe "#enslave" do

    it "sets the enslaved option on the criteria" do
      @criteria.enslave
      @criteria.options[:enslave].should be_true
    end

    it "returns self" do
      @criteria.enslave.should == @criteria
    end
  end

  describe "#extras" do

    context "filtering" do

      context "when page is provided" do

        it "sets the limit and skip options" do
          @criteria.extras({ :page => "2" })
          @criteria.page.should == 2
          @criteria.options.should == { :skip => 20, :limit => 20 }
        end

      end

      context "when per_page is provided" do

        it "sets the limit and skip options" do
          @criteria.extras({ :per_page => 45 })
          @criteria.options.should == { :skip => 0, :limit => 45 }
        end

      end

      context "when page and per_page both provided" do

        it "sets the limit and skip options" do
          @criteria.extras({ :per_page => 30, :page => "4" })
          @criteria.options.should == { :skip => 90, :limit => 30 }
          @criteria.page.should == 4
        end

      end

    end

    it "adds the extras to the options" do
      @criteria.limit(10).extras({ :skip => 10 })
      @criteria.options.should == { :skip => 10, :limit => 10 }
    end

    it "returns self" do
      @criteria.extras({}).should == @criteria
    end

  end

  describe "#id" do

    context "with not using object ids" do

      before do
        @previous_id_type = Person._id_type
        Person.identity :type => String
      end

      after do
        Person.identity :type => @previous_id_type
      end

      context "when passing a single id" do

        context "when the id is a string" do

          it "adds the _id query to the selector" do
            id = BSON::ObjectId.new.to_s
            @criteria.id(id)
            @criteria.selector.should == { :_id => id }
          end

          it "returns self" do
            id = BSON::ObjectId.new.to_s
            @criteria.id(id).should == @criteria
          end
        end

        context "when the id is an object id" do

          it "adds the _id query to the selector" do
            id = BSON::ObjectId.new
            @criteria.id(id)
            @criteria.selector.should == { :_id => id }
          end

          it "returns self" do
            id = BSON::ObjectId.new
            @criteria.id(id).should == @criteria
          end
        end

      end

      context "when passing in an array of ids" do

        before do
          @ids = []
          3.times { @ids << BSON::ObjectId.new.to_s }
        end

        it "adds the _id query to the selector" do
          @criteria.id(@ids)
          @criteria.selector.should ==
            { :_id => { "$in" => @ids } }
        end

      end

      context "when passing in an array with only one id" do

        it "adds the _id query to the selector" do
          ids = [BSON::ObjectId.new]
          @criteria.id(ids).selector.should == { :_id => ids.first }
        end

      end

    end

    context "when using object ids" do

      before do
        @previous_id_type = Person._id_type
        Person.identity :type => BSON::ObjectId
      end

      after do
        Person.identity :type => @previous_id_type
      end

      context "when passing a single id" do

        context "when the id is a string" do

          it "adds the _id query to the selector convert like BSON::ObjectId" do
            id = BSON::ObjectId.new.to_s
            @criteria.id(id)
            @criteria.selector.should == { :_id => BSON::ObjectId(id) }
          end

          it "returns self" do
            id = BSON::ObjectId.new.to_s
            @criteria.id(id).should == @criteria
          end
        end

        context "when the id is an object id" do

          it "adds the _id query to the selector without cast" do
            id = BSON::ObjectId.new
            @criteria.id(id)
            @criteria.selector.should == { :_id => id }
          end

          it "returns self" do
            id = BSON::ObjectId.new
            @criteria.id(id).should == @criteria
          end
        end
      end

      context "when passing in an array of ids" do

        before do
          @ids = []
          3.times { @ids << BSON::ObjectId.new.to_s }
        end

        it "adds the _id query to the selector with all ids like BSON::ObjectId" do
          @criteria.id(@ids)
          @criteria.selector.should ==
            { :_id => { "$in" => @ids.map{|i| BSON::ObjectId(i)} } }
        end
      end
    end
  end

  describe "#limit" do

    context "when value provided" do

      it "adds the limit to the options" do
        @criteria.limit(100)
        @criteria.options.should == { :limit => 100 }
      end
    end

    context "when value not provided" do

      it "defaults to 20" do
        @criteria.limit
        @criteria.options.should == { :limit => 20 }
      end

    end

    it "returns self" do
      @criteria.limit.should == @criteria
    end

  end

  describe "#offset" do

    context "when the per_page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :per_page => 20, :page => 3 })
      end

      it "returns the per_page option" do
        @criteria.offset.should == 40
      end

    end

    context "when the skip option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :skip => 20 })
      end

      it "returns the skip option" do
        @criteria.offset.should == 20
      end

    end

    context "when an argument is provided" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @criteria.offset(40)
      end

      it "delegates to skip" do
        @criteria.options[:skip].should == 40
      end

    end

    context "when no option exists" do

      context "when page option exists" do

        before do
          @criteria = Mongoid::Criteria.new(Person).extras({ :page => 2 })
        end

        it "adds the skip option to the options and returns it" do
          @criteria.offset.should == 20
          @criteria.options[:skip].should == 20
        end

      end

      context "when page option does not exist" do

        before do
          @criteria = Mongoid::Criteria.new(Person)
        end

        it "returns nil" do
          @criteria.offset.should be_nil
          @criteria.options[:skip].should be_nil
        end

      end

    end

  end

  describe "#order_by" do

    context "when field names and direction specified" do

      before do
        @criteria.order_by([[:title, :asc]]).order_by([[:text, :desc]])
      end

      it "adds the sort to the options" do
        @criteria.options.should == { :sort => [[:title, :asc], [:text, :desc]] }
      end
    end

    context "when providing a hash of options" do

      before do
        @criteria.order_by(:title => :asc, :text => :desc)
      end

      it "adds the sort to the options" do
        @criteria.options[:sort].should include([:title, :asc], [:text, :desc])
      end
    end

    context "when providing multiple symbols" do

      before do
        @criteria.order_by(:title.asc, :text.desc)
      end

      it "adds the sort to the options" do
        @criteria.options.should == { :sort => [[:title, :asc], [:text, :desc]] }
      end
    end

    it "returns self" do
      @criteria.order_by.should == @criteria
    end

  end

  describe "#page" do

    context "when the page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :page => 5 })
      end

      it "returns the page option" do
        @criteria.page.should == 5
      end

    end

    context "when the page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
      end

      it "returns 1" do
        @criteria.page.should == 1
      end

    end

  end

  describe "#skip" do

    context "when value provided" do

      it "adds the skip value to the options" do
        @criteria.skip(20)
        @criteria.options.should == { :skip => 20 }
      end

    end

    context "when value not provided" do

      it "defaults to zero" do
        @criteria.skip
        @criteria.options.should == { :skip => 0 }
      end

    end

    it "returns self" do
      @criteria.skip.should == @criteria
    end

  end

  describe "#type" do

    context "when the type is a string" do

      it "adds the _type query to the selector" do
        @criteria.type('Browser')
        @criteria.selector.should == { :_type => { '$in' => ['Browser'] } }
      end

      it "returns self" do
        @criteria.type('Browser').should == @criteria
      end
    end

    context "when the type is an Array of type" do

      it "adds the _type query to the selector" do
        @criteria.type(['Browser', 'Firefox'])
        @criteria.selector.should == { :_type => { '$in' => ['Browser', 'Firefox'] } }
      end

      it "returns self" do
        @criteria.type(['Browser', 'Firefox']).should == @criteria
      end
    end

  end
end
