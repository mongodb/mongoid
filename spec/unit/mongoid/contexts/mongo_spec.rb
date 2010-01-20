require "spec_helper"

describe Mongoid::Contexts::Mongo do

  describe "#aggregate" do

    before do
      @selector = {}
      @options = { :fields => [:field1] }
      @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
    end

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.count++; }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {}, {:count => 0}, @reduce, true)
        @context.aggregate
      end

    end

  end

  describe "#count" do

    before do
      @selector = { :_type => { "$in" => ["Doctor", "Person"] }, :test => "Testing" }
      @options = {}
      @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
    end

    context "when criteria has not been executed" do

      before do
        @context.instance_variable_set(:@count, 34)
      end

      it "returns a count from the cursor" do
        @context.count.should == 34
      end

    end

    context "when criteria has been executed" do

      before do
        @collection = mock
        @cursor = mock
        Person.expects(:collection).returns(@collection)
      end

      it "returns the count from the cursor without creating the documents" do
        @collection.expects(:find).with(@selector, {}).returns(@cursor)
        @cursor.expects(:count).returns(10)
        @context.count.should == 10
      end

    end

  end

  describe "#group" do

    before do
      @selector = { :_type => { "$in" => ["Doctor", "Person"] } }
      @options = { :fields => [ :field1 ] }
      @grouping = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30, "_type" => "Person" }] }]
      @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
    end

    context "when klass provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {:_type => { "$in" => ["Doctor", "Person"] }}, {:group => []}, @reduce, true).returns(@grouping)
        @context.group
      end

    end

  end

  describe "#execute" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }

    before do
      @cursor = stub(:count => 500)
      @collection = mock
      @person = mock
      @klass = stub(:collection => @collection, :hereditary => false, :instantiate => @person)
      @context = Mongoid::Contexts::Mongo.new(selector, options, @klass)
    end

    it "calls find on the collection" do
      @collection.expects(:find).with(selector, options).returns(@cursor)
      @cursor.expects(:collect).yields({ :title => "Sir" }).returns([@person])
      @context.execute.should == [@person]
    end

    context "when field options are supplied" do

      context "when _type not in the field list" do

        before do
          options[:fields] = [ :title ]
          @expected_options = { :skip => 20, :fields => [ :title, :_type ] }
        end

        it "adds _type to the fields" do
          @collection.expects(:find).with(selector, @expected_options).returns(@cursor)
          @cursor.expects(:collect).yields({ :title => "Sir" }).returns([@person])
          @context.execute.should == [@person]
        end

      end

    end

  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:klass) { Person }

    before do
      @context = Mongoid::Contexts::Mongo.new(selector, options, klass)
    end

    it "sets the selector" do
      @context.selector.should == selector
    end

    it "sets the options" do
      @context.options.should == options
    end

    it "sets the klass" do
      @context.klass.should == klass
    end

  end

  describe "#last" do

    before do
      @collection = mock
      Person.expects(:collection).returns(@collection)
    end

    context "when documents exist" do

      before do
        @selector = {}
        @options = { :sort => [[:title, :asc]] }
        @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
        @collection.expects(:find_one).with(@selector, { :sort => [[:title, :desc]] }).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and sort options reversed" do
        @context.last.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @selector = {}
        @options = { :sort => [[:_id, :asc]] }
        @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
        @collection.expects(:find_one).with(@selector, { :sort => [[:_id, :desc]] }).returns(nil)
      end

      it "returns nil" do
        @context.last.should be_nil
      end

    end

    context "when no sorting options provided" do

      before do
        @selector = {}
        @options = { :sort => [[:_id, :asc]] }
        @context = Mongoid::Contexts::Mongo.new(@selector, @options, Person)
        @collection.expects(:find_one).with(@selector, { :sort => [[:_id, :desc]] }).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "defaults to sort by id" do
        @context.last
      end

    end

  end

  describe "#max" do

    before do
      @reduce = Mongoid::Contexts::Mongo::MAX_REDUCE.gsub("[field]", "age")
      @collection = mock
      Person.expects(:collection).returns(@collection)
      @context = Mongoid::Contexts::Mongo.new({}, {}, Person)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {},
        {:max => "start"},
        @reduce,
        true
      ).returns([{"max" => 200.0}])
      @context.max(:age).should == 200.0
    end

  end

  describe "#min" do

    before do
      @reduce = Mongoid::Contexts::Mongo::MIN_REDUCE.gsub("[field]", "age")
      @collection = mock
      Person.expects(:collection).returns(@collection)
      @context = Mongoid::Contexts::Mongo.new({}, {}, Person)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {},
        {:min => "start"},
        @reduce,
        true
      ).returns([{"min" => 4.0}])
      @context.min(:age).should == 4.0
    end

  end

  describe "#one" do

    context "when documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @context = Mongoid::Contexts::Mongo.new({}, {}, Person)
        @collection.expects(:find_one).with({}, {}).returns(
          { "title"=> "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and options" do
        @context.one.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @context = Mongoid::Contexts::Mongo.new({}, {}, Person)
        @collection.expects(:find_one).with({}, {}).returns(nil)
      end

      it "returns nil" do
        @context.one.should be_nil
      end

    end

  end

  describe "#page" do

    context "when the page option exists" do

      before do
        @criteria = Mongoid::Criteria.new(Person).extras({ :page => 5 })
        @context = Mongoid::Contexts::Mongo.new({}, @criteria.options, Person)
      end

      it "returns the page option" do
        @context.page.should == 5
      end

    end

    context "when the page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Mongo.new({}, @criteria.options, Person)
      end

      it "returns 1" do
        @context.page.should == 1
      end

    end

  end

  describe "#paginate" do

    before do
      @collection = mock
      Person.expects(:collection).returns(@collection)
      @criteria = Person.where(:_id => "1").skip(60).limit(20)
      @context = Mongoid::Contexts::Mongo.new(@criteria.selector, @criteria.options, Person)
      @collection.expects(:find).with({:_type => { "$in" => ["Doctor", "Person"] }, :_id => "1"}, :skip => 60, :limit => 20).returns([])
      @results = @context.paginate
    end

    it "executes and paginates the results" do
      @results.current_page.should == 4
      @results.per_page.should == 20
    end

  end

  describe "#sum" do

    context "when klass not provided" do

      before do
        @reduce = Mongoid::Contexts::Mongo::SUM_REDUCE.gsub("[field]", "age")
        @collection = mock
        @context = Mongoid::Contexts::Mongo.new({}, {}, Person)
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with(
          nil,
          {},
          {:sum => "start"},
          @reduce,
          true
        ).returns([{"sum" => 50.0}])
        @context.sum(:age).should == 50.0
      end

    end

  end

end
