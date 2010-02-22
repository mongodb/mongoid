require "spec_helper"

describe Mongoid::Contexts::Mongo do

  describe "#aggregate" do

    before do
      @criteria = Mongoid::Criteria.new(Person)
      @criteria.only(:field1)
      @context = Mongoid::Contexts::Mongo.new(@criteria)
    end

    context "when klass not provided" do

      before do
        @reduce = "function(obj, prev) { prev.count++; }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with([:field1], {:_type => {'$in' => ['Doctor', 'Person']}}, {:count => 0}, @reduce, true)
        @context.aggregate
      end

    end

  end

  describe "#count" do

    before do
      @criteria = Mongoid::Criteria.new(Person)
      @criteria.where(:test => 'Testing')
      @context = Mongoid::Contexts::Mongo.new(@criteria)
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
        @collection.expects(:find).with(@criteria.selector, {}).returns(@cursor)
        @cursor.expects(:count).returns(10)
        @context.count.should == 10
      end

    end

  end

  describe "#execute" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }

    before do
      @cursor = stub(:count => 500)
      @collection = mock
      @klass = stub(
        :collection => @collection,
        :hereditary => false,
        :instantiate => @person,
        :enslaved? => false,
        :cached? => false
      )
      @criteria = Mongoid::Criteria.new(@klass)
      @criteria.where(selector).skip(20)
      @context = Mongoid::Contexts::Mongo.new(@criteria)
    end

    it "calls find on the collection" do
      @collection.expects(:find).with(selector, options).returns(@cursor)
      @context.execute.should == @cursor
    end

    context "when paginating" do

      it "should find the count from the cursor" do
        @collection.expects(:find).with(selector, options).returns(@cursor)
        @context.execute(true).should == @cursor
        @context.count.should == 500
      end

    end

    context "when field options are supplied" do

      context "when _type not in the field list" do

        before do
          @criteria.only(:title)
          @expected_options = { :skip => 20, :fields => [ :title, :_type ] }
        end

        it "adds _type to the fields" do
          @collection.expects(:find).with(selector, @expected_options).returns(@cursor)
          @context.execute.should == @cursor
        end

      end

    end

  end

  describe "#group" do

    before do
      @criteria = Mongoid::Criteria.new(Person)
      @criteria.only(:field1)
      @grouping = [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30, "_type" => "Person" }] }]
      @context = Mongoid::Contexts::Mongo.new(@criteria)
    end

    context "when klass provided" do

      before do
        @reduce = "function(obj, prev) { prev.group.push(obj); }"
        @collection = mock
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with(
          [:field1],
          {:_type => { "$in" => ["Doctor", "Person"] }},
          {:group => []},
          @reduce,
          true
        ).returns(@grouping)
        @context.group
      end

    end

  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:klass) { Person }
    let(:criteria) { Mongoid::Criteria.new(klass) }
    let(:context) { Mongoid::Contexts::Mongo.new(criteria) }

    before do
      criteria.where(selector).skip(20)
    end

    it "sets the selector" do
      context.selector.should == criteria.selector
    end

    it "sets the options" do
      context.options.should == options
    end

    it "sets the klass" do
      context.klass.should == klass
    end

    it "set the selector to query across the _type of the Criteria's klass when it is hereditary" do
      context.selector[:_type].should == {'$in' => Person._types}
    end

    context "enslaved and cached classes" do

      let(:klass) { Game }

      it "enslaves the criteria" do
        context.criteria.should be_enslaved
      end

      it "caches the criteria" do
        context.criteria.should be_cached
      end
    end
  end

  describe "#last" do

    before do
      @collection = mock
      Person.expects(:collection).returns(@collection)
    end

    context "when documents exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @criteria.order_by([[:title, :asc]])
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        @collection.expects(:find_one).with({:_type => {'$in' => ['Doctor', 'Person']}}, { :sort => [[:title, :desc]] }).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and sort options reversed" do
        @context.last.should be_a_kind_of(Person)
      end

    end

    context "when no documents exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @criteria.order_by([[:_id, :asc]])
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        @collection.expects(:find_one).with({:_type => {'$in' => ['Doctor', 'Person']}}, { :sort => [[:_id, :desc]] }).returns(nil)
      end

      it "returns nil" do
        @context.last.should be_nil
      end

    end

    context "when no sorting options provided" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @criteria.order_by([[:_id, :asc]])
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        @collection.expects(:find_one).with({:_type => {'$in' => ['Doctor', 'Person']}}, { :sort => [[:_id, :desc]] }).returns(
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
      @criteria = Mongoid::Criteria.new(Person)
      @context = Mongoid::Contexts::Mongo.new(@criteria)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {:_type => {'$in' => ['Doctor', 'Person']}},
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
      @criteria = Mongoid::Criteria.new(Person)
      @context = Mongoid::Contexts::Mongo.new(@criteria)
    end

    it "calls group on the collection with the aggregate js" do
      @collection.expects(:group).with(
        nil,
        {:_type => {'$in' => ['Doctor', 'Person']}},
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
        Person.expects(:collection).returns(@collection)
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        @collection.expects(:find_one).with({:_type => {'$in' => ['Doctor', 'Person']}}, {}).returns(
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
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        @collection.expects(:find_one).with({:_type => {'$in' => ['Doctor', 'Person']}}, {}).returns(nil)
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
        @context = Mongoid::Contexts::Mongo.new(@criteria)
      end

      it "returns the page option" do
        @context.page.should == 5
      end

    end

    context "when the page option does not exist" do

      before do
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Mongo.new(@criteria)
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
      @context = Mongoid::Contexts::Mongo.new(@criteria)
      @collection.expects(:find).with(
        {:_type => { "$in" => ["Doctor", "Person"] }, :_id => "1"}, :skip => 60, :limit => 20
      ).returns([])
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
        @criteria = Mongoid::Criteria.new(Person)
        @context = Mongoid::Contexts::Mongo.new(@criteria)
        Person.expects(:collection).returns(@collection)
      end

      it "calls group on the collection with the aggregate js" do
        @collection.expects(:group).with(
          nil,
          {:_type => {'$in' => ['Doctor', 'Person']}},
          {:sum => "start"},
          @reduce,
          true
        ).returns([{"sum" => 50.0}])
        @context.sum(:age).should == 50.0
      end

    end

  end

  context "#id_criteria" do

    let(:criteria) { Mongoid::Criteria.new(Person) }
    let(:context) { criteria.context }

    context "with a single argument" do

      let(:id) { Mongo::ObjectID.new.to_s }

      before do
        criteria.expects(:id).with(id).returns(criteria)
      end

      context "when the document is found" do

        let(:document) { stub }

        it "returns a matching document" do
          context.expects(:one).returns(document)
          document.expects(:blank? => false)
          context.id_criteria(id).should == document
        end

      end

      context "when the document is not found" do

        it "raises an error" do
          context.expects(:one).returns(nil)
          lambda { context.id_criteria(id) }.should raise_error
        end

      end

    end

    context "multiple arguments" do

      context "when an array of ids" do

        let(:ids) do
          (0..2).inject([]) { |ary, i| ary << Mongo::ObjectID.new.to_s }
        end

        context "when documents are found" do

          let(:docs) do
            (0..2).inject([]) { |ary, i| ary << stub }
          end

          before do
            criteria.expects(:id).with(ids).returns(criteria)
          end

          it "returns matching documents" do
            context.expects(:execute).returns(docs)
            context.id_criteria(ids).should == docs
          end

        end

        context "when documents are not found" do

          it "raises an error" do
            context.expects(:execute).returns([])
            lambda { context.id_criteria(ids) }.should raise_error
          end

        end

      end

      context "when an array of object ids" do

        let(:ids) do
          (0..2).inject([]) { |ary, i| ary << Mongo::ObjectID.new }
        end

        context "when documents are found" do

          let(:docs) do
            (0..2).inject([]) { |ary, i| ary << stub }
          end

          before do
            criteria.expects(:id).with(ids).returns(criteria)
          end

          it "returns matching documents" do
            context.expects(:execute).returns(docs)
            context.id_criteria(ids).should == docs
          end

        end

        context "when documents are not found" do

          it "raises an error" do
            context.expects(:execute).returns([])
            lambda { context.id_criteria(ids) }.should raise_error
          end

        end

      end
    end

  end

end
