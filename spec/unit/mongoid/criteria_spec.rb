require "spec_helper"

describe Mongoid::Criteria do

  before do
    @criteria = Mongoid::Criteria.new(Person)
    @canvas_criteria = Mongoid::Criteria.new(Canvas)
  end

  describe "#[]" do

    before do
      @criteria.where(:title => "Sir")
      @collection = stub
      @person = Person.new(:title => "Sir")
      @cursor = stub(:count => 10, :collect => [@person])
    end

    context "when the criteria has not been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({ :title => "Sir", :_type => { "$in" => ["Doctor", "Person"] } }, {}).returns(@cursor)
      end

      it "executes the criteria and returns the element at the index" do
        @criteria[0].should == @person
      end

    end

  end

  describe "#aggregate" do

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.count++; }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {:_type => { "$in" => ["Doctor", "Person"] }}, {:count => 0}, @reduce, true)
        @criteria.only(:field1).aggregate
      end

    end

  end

  describe "#all" do

    it "adds the $all query to the selector" do
      @criteria.all(:title => ["title1", "title2"])
      @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$all" => ["title1", "title2"] } }
    end

    it "returns self" do
      @criteria.all(:title => [ "title1" ]).should == @criteria
    end

  end

  describe "#and" do

    context "when provided a hash" do

      it "adds the clause to the selector" do
        @criteria.and(:title => "Title", :text => "Text")
        @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Title", :text => "Text" }
      end

    end

    context "when provided a string" do

      it "adds the $where clause to the selector" do
        @criteria.and("this.date < new Date()")
        @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, "$where" => "this.date < new Date()" }
      end

    end

    it "returns self" do
      @criteria.and.should == @criteria
    end

  end

  describe "#collect" do

    context "filtering" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @criteria = Mongoid::Criteria.new(Person).extras(:page => 1, :per_page => 20)
        @collection.expects(:find).with(@criteria.selector, @criteria.options).returns([])
      end

      it "filters out unused params" do
        @criteria.collect
        @criteria.options[:page].should be_nil
        @criteria.options[:per_page].should be_nil
      end

    end

    context "when type is :all" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @criteria = Mongoid::Criteria.new(Person).extras(:page => 1, :per_page => 20)
        @cursor = stub(:count => 44, :collect => [])
        @collection.expects(:find).with(@criteria.selector, @criteria.options).returns(@cursor)
      end

      it "adds the count instance variable" do
        @criteria.collect.should == []
        @criteria.count.should == 44
      end

    end

    context "when type is not :first" do

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(Person)
        collection = mock
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with(@criteria.selector, @criteria.options).returns([])
        criteria.collect.should == []
      end

    end

  end

  describe "#count" do

    context "when criteria has not been executed" do

      before do
        @criteria.instance_variable_set(:@count, 34)
      end

      it "returns a count from the cursor" do
        @criteria.count.should == 34
      end

    end

    context "when criteria has been executed" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @selector = { :_type => { "$in" => ["Doctor", "Person"] }, :test => "Testing" }
        @criteria.where(@selector)
        @collection = mock
        @cursor = mock
        Person.expects(:collection).returns(@collection)
      end

      it "returns the count from the cursor without creating the documents" do
        @collection.expects(:find).with(@selector, {}).returns(@cursor)
        @cursor.expects(:count).returns(10)
        @criteria.count.should == 10
      end

    end

  end

  describe "#each" do

    before do
      @criteria.where(:title => "Sir")
      @collection = stub
      @person = Person.new(:title => "Sir")
      @cursor = stub(:count => 10, :collect => [@person])
    end

    context "when the criteria has not been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({ :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir" }, {}).returns(@cursor)
      end

      it "executes the criteria" do
        @criteria.each do |person|
          person.should == @person
        end
      end

    end

    context "when the criteria has been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({ :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir" }, {}).returns(@cursor)
      end

      it "calls each on the existing results" do
        @criteria.each
        @criteria.each do |person|
          person.should == @person
        end
      end

    end

    context "when no block is passed" do

      it "returns self" do
        @criteria.each.should == @criteria
      end

    end

  end

  describe "#first" do

    context "when documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.first.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns(nil)
      end

      it "returns nil" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.first.should be_nil
      end

    end

    context "when document is a subclass of the class queried from" do

      before do
        @collection = mock
        Canvas.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@canvas_criteria.selector, @canvas_criteria.options).returns(
          { "name" => "Firefox", "_type" => "Firefox" }
        )
      end

      it "instantiates the subclass" do
        criteria = Mongoid::Criteria.new(Canvas)
        criteria.first.should be_a_kind_of(Firefox)
      end

    end

  end

  describe "#excludes" do

    it "adds the $ne query to the selector" do
      @criteria.excludes(:title => "Bad Title", :text => "Bad Text")
      @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$ne" => "Bad Title"}, :text => { "$ne" => "Bad Text" } }
    end

    it "returns self" do
      @criteria.excludes(:title => "Bad").should == @criteria
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
      @criteria.extras({ :skip => 10 })
      @criteria.options.should == { :skip => 10 }
    end

    it "returns self" do
      @criteria.extras({}).should == @criteria
    end

  end

  describe "#group" do

    before do
      @grouping = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30, "_type" => "Person" }] }]
    end

    context "when klass provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @criteria = Mongoid::Criteria.new(Person)
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {:_type => { "$in" => ["Doctor", "Person"] }}, {:group => []}, @reduce, true).returns(@grouping)
        @criteria.only(:field1).group
      end

    end

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {:_type => { "$in" => ["Doctor", "Person"] }}, {:group => []}, @reduce, true).returns(@grouping)
        @criteria.only(:field1).group
      end

    end

  end

  describe "#id" do

    it "adds the _id query to the selector" do
      id = Mongo::ObjectID.new.to_s
      @criteria.id(id)
      @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :_id => id }
    end

    it "returns self" do
      id = Mongo::ObjectID.new.to_s
      @criteria.id(id.to_s).should == @criteria
    end

  end

  describe "#in" do

    it "adds the $in clause to the selector" do
      @criteria.in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] } }
    end

    it "returns self" do
      @criteria.in(:title => ["title1"]).should == @criteria
    end

  end

  describe "#initialize" do

    context "when class is hereditary" do

      it "sets the _type value on the selector" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] } }
      end

    end

    context "when class is not hereditary" do

      it "sets no _type value on the selector" do
        criteria = Mongoid::Criteria.new(Game)
        criteria.selector.should == {}
      end

    end

  end

  describe "#last" do

    context "when documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, { :sort => [[:title, :desc]] }).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and sort options reversed" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.order_by([[:title, :asc]])
        criteria.last.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, { :sort => [[:_id, :desc]] }).returns(nil)
      end

      it "returns nil" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.last.should be_nil
      end

    end

    context "when no sorting options provided" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, { :sort => [[:_id, :desc]] }).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "defaults to sort by id" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.last
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

  describe "#max" do

    before do
      @reduce = Mongoid::Criteria::MAX_REDUCE.gsub("[field]", "age")
      @collection = mock
      Person.expects(:collection).returns(@collection)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {:_type => { "$in" => ["Doctor", "Person"] } },
        {:max => "start"},
        @reduce,
        true
      ).returns([{"max" => 200.0}])
      @criteria.max(:age).should == 200.0
    end

  end

  describe "#merge" do

    before do
      @criteria.where(:title => "Sir", :age => 30).skip(40).limit(20)
    end

    context "with another criteria" do

      context "when the other has a selector and options" do

        before do
          @other = Mongoid::Criteria.new(Person)
          @other.where(:name => "Chloe").order_by([[:name, :asc]])
          @selector = { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir", :age => 30, :name => "Chloe" }
          @options = { :skip => 40, :limit => 20, :sort => [[:name, :asc]] }
        end

        it "merges the selector and options hashes together" do
          @criteria.merge(@other)
          @criteria.selector.should == @selector
          @criteria.options.should == @options
        end

      end

      context "when the other has no selector or options" do

        before do
          @other = Mongoid::Criteria.new(Person)
          @selector = { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir", :age => 30 }
          @options = { :skip => 40, :limit => 20 }
        end

        it "merges the selector and options hashes together" do
          @criteria.merge(@other)
          @criteria.selector.should == @selector
          @criteria.options.should == @options
        end
      end

    end

  end

  describe "#method_missing" do

    before do
      @criteria = Mongoid::Criteria.new(Person)
      @criteria.where(:title => "Sir")
    end

    it "merges the criteria with the next one" do
      @new_criteria = @criteria.accepted
      @new_criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir", :terms => true }
    end

    context "chaining more than one scope" do

      before do
        @criteria = Person.accepted.old.knight
      end

      it "returns the final merged criteria" do
        @criteria.selector.should ==
          { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Sir", :terms => true, :age => { "$gt" => 50 } }
      end

    end

    context "when expecting behaviour of an array" do

      before do
        @array = mock
        @document = mock
      end

      describe "#[]" do

        it "collects the criteria and calls []" do
          @criteria.expects(:collect).returns([@document])
          @criteria[0].should == @document
        end

      end

      describe "#rand" do

        it "collects the criteria and call rand" do
          @criteria.expects(:collect).returns(@array)
          @array.expects(:send).with(:rand).returns(@document)
          @criteria.rand
        end

      end

    end

  end

  describe "#min" do

    before do
      @reduce = Mongoid::Criteria::MIN_REDUCE.gsub("[field]", "age")
      @collection = mock
      Person.expects(:collection).returns(@collection)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {:_type => { "$in" => ["Doctor", "Person"] } },
        {:min => "start"},
        @reduce,
        true
      ).returns([{"min" => 4.0}])
      @criteria.min(:age).should == 4.0
    end

  end

  describe "#not_in" do

    it "adds the exclusion to the selector" do
      @criteria.not_in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == {
        :_type => { "$in" => ["Doctor", "Person"] },
        :title => { "$nin" => ["title1", "title2"] },
        :text => { "$nin" => ["test"] }
      }
    end

    it "returns self" do
      @criteria.not_in(:title => ["title1"]).should == @criteria
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

  describe "#one" do

    context "when documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns(
          { "title"=> "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.one.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns(nil)
      end

      it "returns nil" do
        criteria = Mongoid::Criteria.new(Person)
        criteria.one.should be_nil
      end

    end

  end

  describe "#order_by" do

    context "when field names and direction specified" do

      it "adds the sort to the options" do
        @criteria.order_by([[:title, :asc], [:text, :desc]])
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

  describe "#paginate" do

    before do
      @collection = mock
      Person.expects(:collection).returns(@collection)
      @criteria = Person.where(:_id => "1").skip(60).limit(20)
      @collection.expects(:find).with({:_type => { "$in" => ["Doctor", "Person"] }, :_id => "1"}, :skip => 60, :limit => 20).returns([])
      @results = @criteria.paginate
    end

    it "executes and paginates the results" do
      @results.current_page.should == 4
      @results.per_page.should == 20
    end

  end

  describe "#per_page" do

    context "when the per_page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :per_page => 10 })
      end

      it "returns the per_page option" do
        @criteria.per_page.should == 10
      end

    end

    context "when the per_page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
      end

      it "returns 1" do
        @criteria.per_page.should == 20
      end

    end

  end

  describe "#only" do

    context "when args are provided" do

      it "adds the options for limiting by fields" do
        @criteria.only(:title, :text)
        @criteria.options.should == { :fields => [ :title, :text ] }
      end

      it "returns self" do
        @criteria.only.should == @criteria
      end

    end

    context "when no args provided" do

      it "does not add the field option" do
        @criteria.only
        @criteria.options[:fields].should be_nil
      end

    end

  end

  describe "#scoped" do

    before do
      @criteria = Person.where(:title => "Sir").skip(20)
    end

    it "returns the selector plus the options" do
      @criteria.scoped.should ==
        { :where => { :title => "Sir", :_type=>{ "$in" => [ "Doctor", "Person" ] } }, :skip => 20 }
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

  describe "#sum" do

    context "when klass not provided" do

      before do
        @reduce = Mongoid::Criteria::SUM_REDUCE.gsub("[field]", "age")
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with(
          nil,
          {:_type => { "$in" => ["Doctor", "Person"] } },
          {:sum => "start"},
          @reduce,
          true
        ).returns([{"sum" => 50.0}])
        @criteria.sum(:age).should == 50.0
      end

    end

  end

  describe ".translate" do

    context "with a single argument" do

      before do
        @id = Mongo::ObjectID.new.to_s
        @document = stub
        @criteria = mock
        Mongoid::Criteria.expects(:new).returns(@criteria)
        @criteria.expects(:id).with(@id).returns(@criteria)
      end

      it "creates a criteria for a string" do
        @criteria.expects(:one).returns(@document)
        Mongoid::Criteria.translate(Person, @id)
      end

      context "when the document is not found" do

        it "raises an error" do
          @criteria.expects(:one).returns(nil)
          lambda { Mongoid::Criteria.translate(Person, @id) }.should raise_error
        end

      end

    end

    context "multiple arguments" do

      context "when Person, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          @criteria.klass.should == Person
        end

      end

      context "when :all, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          @criteria.klass.should == Person
        end

      end

      context "when :last, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          @criteria.klass.should == Person
        end
      end

      context "when options are provided" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :title => "Test" }, :skip => 10)
        end

        it "adds the criteria and the options" do
          @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Test" }
          @criteria.options.should == { :skip => 10 }
        end

      end

    end

  end

  describe "#where" do

    context "when provided a hash" do

      context "with simple hash keys" do

        it "adds the clause to the selector" do
          @criteria.where(:title => "Title", :text => "Text")
          @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => "Title", :text => "Text" }
        end

      end

      context "with complex criterion" do

        context "#all" do

          it "returns those matching an all clause" do
            @criteria.where(:title.all => ["Sir"])
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$all" => ["Sir"] } }
          end

        end

        context "#exists" do

          it "returns those matching an exists clause" do
            @criteria.where(:title.exists => true)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$exists" => true } }
          end

        end

        context "#gt" do

          it "returns those matching a gt clause" do
            @criteria.where(:age.gt => 30)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :age => { "$gt" => 30 } }
          end

        end

        context "#gte" do

          it "returns those matching a gte clause" do
            @criteria.where(:age.gte => 33)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :age => { "$gte" => 33 } }
          end

        end

        context "#in" do

          it "returns those matching an in clause" do
            @criteria.where(:title.in => ["Sir", "Madam"])
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$in" => ["Sir", "Madam"] } }
          end

        end

        context "#lt" do

          it "returns those matching a lt clause" do
            @criteria.where(:age.lt => 34)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :age => { "$lt" => 34 } }
          end

        end

        context "#lte" do

          it "returns those matching a lte clause" do
            @criteria.where(:age.lte => 33)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :age => { "$lte" => 33 } }
          end

        end

        context "#ne" do

          it "returns those matching a ne clause" do
            @criteria.where(:age.ne => 50)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :age => { "$ne" => 50 } }
          end

        end

        context "#nin" do

          it "returns those matching a nin clause" do
            @criteria.where(:title.nin => ["Esquire", "Congressman"])
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :title => { "$nin" => ["Esquire", "Congressman"] } }
          end

        end

        context "#size" do

          it "returns those matching a size clause" do
            @criteria.where(:aliases.size => 2)
            @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, :aliases => { "$size" => 2 } }
          end

        end

      end

    end

    context "when provided a string" do

      it "adds the $where clause to the selector" do
        @criteria.where("this.date < new Date()")
        @criteria.selector.should == { :_type => { "$in" => ["Doctor", "Person"] }, "$where" => "this.date < new Date()" }
      end

    end

    it "returns self" do
      @criteria.where.should == @criteria
    end

  end

  context "#fuse" do

    it ":where => {:title => 'Test'} returns a criteria with the correct selector" do
      @result = @criteria.fuse(:where => { :title => 'Test' })
      @result.selector[:title].should == 'Test'
    end

    it ":where => {:title => 'Test'}, :skip => 10 returns a criteria with the correct selector and options" do
      @result = @criteria.fuse(:where => { :title => 'Test' }, :skip => 10)
      @result.selector[:title].should == 'Test'
      @result.options.should == { :skip => 10 }
    end
  end
end
