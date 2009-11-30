require "spec_helper"

describe Mongoid::Criteria do

  before do
    @criteria = Mongoid::Criteria.new(Person)
  end

  describe "#aggregate" do

    context "when klass provided" do

      before do
        @reduce = "function(obj, prev) { prev.count++; }"
        @criteria = Mongoid::Criteria.new(Person)
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {}, {:count => 0}, @reduce)
        @criteria.select(:field1).aggregate
      end

    end

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.count++; }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {}, {:count => 0}, @reduce)
        @criteria.select(:field1).aggregate(Person)
      end

    end

  end

  describe "#all" do

    it "adds the $all query to the selector" do
      @criteria.all(:title => ["title1", "title2"])
      @criteria.selector.should == { :title => { "$all" => ["title1", "title2"] } }
    end

    it "returns self" do
      @criteria.all(:title => [ "title1" ]).should == @criteria
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

    context "when type is :first" do


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
        @selector = { :test => "Testing" }
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
        @collection.expects(:find).with({ :title => "Sir" }, {}).returns(@cursor)
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
        @collection.expects(:find).with({ :title => "Sir" }, {}).returns(@cursor)
      end

      it "calls each on the existing results" do
        @criteria.each
        @criteria.each do |person|
          person.should == @person
        end
      end

    end

  end

  describe "#excludes" do

    it "adds the $ne query to the selector" do
      @criteria.excludes(:title => "Bad Title", :text => "Bad Text")
      @criteria.selector.should == { :title => { "$ne" => "Bad Title"}, :text => { "$ne" => "Bad Text" } }
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
      @grouping = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30 }] }]
    end

    context "when klass provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @criteria = Mongoid::Criteria.new(Person)
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {}, {:group => []}, @reduce).returns(@grouping)
        @criteria.select(:field1).group
      end

    end

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {}, {:group => []}, @reduce).returns(@grouping)
        @criteria.select(:field1).group(Person)
      end

    end

  end

  describe "#id" do

    it "adds the _id query to the selector" do
      id = Mongo::ObjectID.new.to_s
      @criteria.id(id)
      @criteria.selector.should == { :_id => id }
    end

    it "returns self" do
      id = Mongo::ObjectID.new.to_s
      @criteria.id(id.to_s).should == @criteria
    end

  end

  describe "#in" do

    it "adds the $in clause to the selector" do
      @criteria.in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == { :title => { "$in" => ["title1", "title2"] }, :text => { "$in" => ["test"] } }
    end

    it "returns self" do
      @criteria.in(:title => ["title1"]).should == @criteria
    end

  end

  describe "#last" do

    context "when documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find_one).with(@criteria.selector, { :sort => [[:title, :desc]] }).returns({ :title => "Sir" })
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
        @collection.expects(:find_one).with(@criteria.selector, { :sort => [[:_id, :desc]] }).returns({ :title => "Sir" })
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

  describe "#merge" do

    before do
      @criteria.where(:title => "Sir", :age => 30).skip(40).limit(20)
    end

    context "with another criteria" do

      context "when the other has a selector and options" do

        before do
          @other = Mongoid::Criteria.new(Person)
          @other.where(:name => "Chloe").order_by([[:name, :asc]])
          @selector = { :title => "Sir", :age => 30, :name => "Chloe" }
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
          @selector = { :title => "Sir", :age => 30 }
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
      @new_criteria.selector.should == { :title => "Sir", :terms => true }
    end

    context "chaining more than one scope" do

      before do
        @criteria = Person.accepted.old.knight
      end

      it "returns the final merged criteria" do
        @criteria.selector.should ==
          { :title => "Sir", :terms => true, :age => { "$gt" => 50 } }
      end

    end

  end

  describe "#not_in" do

    it "adds the exclusion to the selector" do
      @criteria.not_in(:title => ["title1", "title2"], :text => ["test"])
      @criteria.selector.should == { :title => { "$nin" => ["title1", "title2"] }, :text => { "$nin" => ["test"] } }
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
        @collection.expects(:find_one).with(@criteria.selector, @criteria.options).returns({ :title => "Sir" })
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
      @criteria = Person.select.where(:_id => "1").skip(60).limit(20)
      @collection.expects(:find).with({:_id => "1"}, :skip => 60, :limit => 20).returns([])
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

  describe "#select" do

    context "when args are provided" do

      it "adds the options for limiting by fields" do
        @criteria.select(:title, :text)
        @criteria.options.should == { :fields => [ :title, :text ] }
      end

      it "returns self" do
        @criteria.select.should == @criteria
      end

    end

    context "when no args provided" do

      it "does not add the field option" do
        @criteria.select
        @criteria.options[:fields].should be_nil
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

  describe ".translate" do

    context "with a single argument" do

      before do
        @id = Mongo::ObjectID.new.to_s
        @document = stub
        @criteria = mock
        Mongoid::Criteria.expects(:new).returns(@criteria)
        @criteria.expects(:id).with(@id).returns(@criteria)
        @criteria.expects(:one).returns(@document)
      end

      it "creates a criteria for a string" do
        Mongoid::Criteria.translate(Person, @id)
      end

    end

    context "multiple arguments" do

      context "when Person, :conditions => {}" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :title => "Test" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :title => "Test" }
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
          @criteria.selector.should == { :title => "Test" }
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
          @criteria.selector.should == { :title => "Test" }
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
          @criteria.selector.should == { :title => "Test" }
          @criteria.options.should == { :skip => 10 }
        end

      end

    end

  end

  describe "#where" do

    it "adds the clause to the selector" do
      @criteria.where(:title => "Title", :text => "Text")
      @criteria.selector.should == { :title => "Title", :text => "Text" }
    end

    it "returns self" do
      @criteria.where.should == @criteria
    end

  end

end
