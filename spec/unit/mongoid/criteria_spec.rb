require "spec_helper"

describe Mongoid::Criteria do

  before do
    @criteria = Mongoid::Criteria.new(Person)
    @canvas_criteria = Mongoid::Criteria.new(Canvas)
  end

  describe "#+" do

    before do
      @sir = Person.new(:title => "Sir")
      @canvas = Canvas.new
    end

    context "when the criteria has not been executed" do

      before do
        @collection = mock
        @cursor = stub(:count => 1)
        @cursor.expects(:each).at_least_once.yields(@sir)
        Person.expects(:collection).at_least_once.returns(@collection)
        @collection.expects(:find).at_least_once.returns(@cursor)
      end

      it "executes the criteria and concats the results" do
        results = @criteria + [ @canvas ]
        results.should == [ @sir, @canvas ]
      end

    end

    context "when the other is a criteria" do

      before do
        @collection = mock
        @canvas_collection = mock
        @cursor = stub(:count => 1)
        @canvas_cursor = stub(:count => 1)
        @cursor.expects(:each).at_least_once.yields(@sir)
        @canvas_cursor.expects(:each).at_least_once.yields(@canvas)
        Person.expects(:collection).at_least_once.returns(@collection)
        @collection.expects(:find).at_least_once.returns(@cursor)
        Canvas.expects(:collection).at_least_once.returns(@canvas_collection)
        @canvas_collection.expects(:find).at_least_once.returns(@canvas_cursor)
      end

      it "concats the results" do
        results = @criteria + @canvas_criteria
        results.should == [ @sir, @canvas ]
      end

    end

  end

  describe "#-" do

    before do
      @sir = Person.new(:title => "Sir")
      @madam = Person.new(:title => "Madam")
    end

    context "when the criteria has not been executed" do

      before do
        @collection = mock
        @cursor = stub(:count => 1)
        @cursor.expects(:each).yields(@madam)
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).returns(@cursor)
      end

      it "executes the criteria and returns the difference" do
        results = @criteria - [ @sir ]
        results.should == [ @madam ]
      end

    end

  end

  describe "#[]" do

    before do
      @criteria.where(:title => "Sir")
      @collection = stub
      @person = Person.new(:title => "Sir")
      @cursor = stub(:count => 10)
      @cursor.expects(:each).yields(@person)
    end

    context "when the criteria has not been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({ :title => "Sir"}, {}).returns(@cursor)
      end

      it "executes the criteria and returns the element at the index" do
        @criteria[0].should == @person
      end

    end

  end

  describe "#aggregate" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:aggregate)
      @criteria.aggregate
    end

  end

  describe "#avg" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:avg).with(:age)
      @criteria.avg(:age)
    end
  end

  describe "#blank?" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    context "when the context is blank" do

      before do
        @context.expects(:blank?).returns(true)
      end

      it "returns true" do
        @criteria.blank?.should be_true
      end
    end

    context "when the context is not blank" do

      before do
        @context.expects(:blank?).returns(false)
      end

      it "returns false" do
        @criteria.blank?.should be_false
      end
    end
  end

  describe "#context" do

    context "when the context has been set" do

      before do
        @context = stub
        @criteria.instance_variable_set(:@context, @context)
      end

      it "returns the memoized context" do
        @criteria.context.should == @context
      end

    end

    context "when the context has not been set" do

      before do
        @context = stub
      end

      it "creates a new context" do
        Mongoid::Contexts::Mongo.expects(:new).with(@criteria).returns(@context)
        @criteria.context.should == @context
      end

    end

    context "when the class is embedded" do

      before do
        @criteria = Mongoid::Criteria.new(Address)
      end

      it "returns an enumerable context" do
        @criteria.context.should be_a_kind_of(Mongoid::Contexts::Enumerable)
      end

    end

    context "when the class is not embedded" do

      it "returns a mongo context" do
        @criteria.context.should be_a_kind_of(Mongoid::Contexts::Mongo)
      end

    end

  end

  describe "#distinct" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:distinct).with(:title)
      @criteria.distinct(:title)
    end
  end

  describe "#entries" do

    context "filtering" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @criteria = Mongoid::Criteria.new(Person).extras(:page => 1, :per_page => 20)
        @collection.expects(:find).with(@criteria.selector, @criteria.options).returns([])
      end

      it "filters out unused params" do
        @criteria.entries
        @criteria.options[:page].should be_nil
        @criteria.options[:per_page].should be_nil
      end

    end

    context "when type is :all" do

      before do
        @collection = mock
        Person.expects(:collection).returns(@collection)
        @criteria = Mongoid::Criteria.new(Person).extras(:page => 1, :per_page => 20)
        @cursor = stub(:count => 44)
        @cursor.expects(:each)
        @collection.expects(:find).with(@criteria.selector, @criteria.options).returns(@cursor)
      end

      it "does not add the count instance variable" do
        @criteria.entries.should == []
        @criteria.instance_variable_get(:@count).should be_nil
      end

    end

    context "when type is not :first" do

      it "calls find on the collection with the selector and options" do
        criteria = Mongoid::Criteria.new(Person)
        collection = mock
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with(criteria.selector, criteria.options).returns([])
        criteria.entries.should == []
      end

    end

  end

  describe "#count" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:count).returns(10)
      @criteria.count.should == 10
    end

  end

  describe "#exists?" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "call the count context and return true if there are element" do
      @context.expects(:count).returns(10)
      @criteria.exists?.should be_true
    end

    it "call the count context and return false if there are no element" do
      @context.expects(:count).returns(0)
      @criteria.exists?.should be_false
    end

  end

  describe "#each" do

    before do
      @criteria.where(:title => "Sir")
      @collection = stub
      @person = Person.new(:title => "Sir")
      @cursor = stub(:count => 10)
    end

    it "delegates to the context#iterate" do
      @context = stub('context')
      @criteria.stubs(:context).returns(@context)
      @context.expects(:iterate)
      @criteria.each
    end

    context "when the criteria has not been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({:title => "Sir"}, {}).returns(@cursor)
        @cursor.expects(:each).yields(@person)
      end

      it "executes the criteria" do
        @criteria.each do |doc|
          doc.should == @person
        end
      end

    end

    context "when the criteria has been executed" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with({:title => "Sir"}, {}).returns(@cursor)
        @cursor.expects(:each).yields(@person)
      end

      it "calls each on the existing results" do
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

    context "when caching" do

      before do
        Person.expects(:collection).returns(@collection)
        @collection.expects(:find).with(
          { :title => "Sir" },
          { :cache => true }
        ).returns(@cursor)
        @cursor.expects(:each).yields(@person)
        @criteria.cache
        @criteria.each do |doc|
          doc.should == @person
        end
      end

      it "caches the results of the cursor iteration" do
        @criteria.each do |doc|
          doc.should == @person
        end
        # Do it again for sanity's sake.
        @criteria.each do |doc|
          doc.should == @person
        end
      end

    end

  end

  describe "#first" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:first).returns([])
      @criteria.first.should == []
    end

  end

  describe "#group" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:group).returns({})
      @criteria.group.should == {}
    end

  end

  describe "#initialize" do

    let(:criteria) { Mongoid::Criteria.new(Person) }

    it "sets the selector to an empty hash" do
      criteria.selector.should == {}
    end

    it "sets the options to an empty hash" do
      criteria.options.should == {}
    end

    it "sets the documents to an empty array" do
      criteria.documents.should == []
    end

    it "sets the klass to the given class" do
      criteria.klass.should == Person
    end

  end

  describe "#last" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:last).returns([])
      @criteria.last.should == []
    end

  end

  describe "#max" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:max).with(:field).returns(100)
      @criteria.max(:field).should == 100
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

      context "when the other has a document collection" do

        before do
          @documents = [ stub ]
          @other = Mongoid::Criteria.new(Person)
          @other.documents = @documents
        end

        it "merges the documents collection in" do
          @criteria.merge(@other)
          @criteria.documents.should == @documents
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
        @criteria.selector.should == { :title => "Sir", :terms => true, :age => { "$gt" => 50 } }
      end

    end

    context "when returning a non-criteria object" do
      let(:ages) { [10, 20] }
      it "does not attempt to merge" do
        Person.stubs(:ages => ages)
        expect { @criteria.ages }.to_not raise_error(NoMethodError)
      end
    end

    context "when expecting behaviour of an array" do

      before do
        @array = mock
        @document = mock
      end

      describe "#[]" do

        it "collects the criteria and calls []" do
          @criteria.expects(:entries).returns([@document])
          @criteria[0].should == @document
        end

      end

      describe "#rand" do

        it "collects the criteria and call rand" do
          @criteria.expects(:entries).returns(@array)
          @array.expects(:send).with(:rand).returns(@document)
          @criteria.rand
        end

      end

    end

  end

  describe "#min" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:min).with(:field).returns(100)
      @criteria.min(:field).should == 100
    end

  end

  describe "#offset" do

  end

  describe "#one" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:one)
      @criteria.one
    end

  end

  describe "#page" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:page).returns(1)
      @criteria.page.should == 1
    end

  end

  describe "#paginate" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:paginate).returns([])
      @criteria.paginate.should == []
    end

  end

  describe "#per_page" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:per_page).returns(20)
      @criteria.per_page.should == 20
    end

  end

  describe "#scoped" do

    context "when the options contain sort criteria" do

      before do
        @criteria = Person.where(:title => "Sir").asc(:score)
      end

      it "changes sort to order_by" do
        @criteria.scoped.should == { :where => { :title => "Sir" }, :order_by => [[:score, :asc]] }
      end
    end

  end

  describe "#sum" do

    before do
      @context = stub.quacks_like(Mongoid::Contexts::Mongo.allocate)
      @criteria.instance_variable_set(:@context, @context)
    end

    it "delegates to the context" do
      @context.expects(:sum).with(:field).returns(20)
      @criteria.sum(:field).should == 20
    end

  end

  describe ".translate" do

    context "with a single argument" do

      context "when the arg is a string" do

        before do
          @id = BSON::ObjectId.new.to_s
          @document = stub
          @criteria = mock
          Person.expects(:criteria).returns(@criteria)
        end

        it "delegates to #id_criteria" do
          @criteria.expects(:id_criteria).with(@id).returns(@document)
          Mongoid::Criteria.translate(Person, @id).should == @document
        end
      end

      context "when the arg is an object id" do

        before do
          @id = BSON::ObjectId.new
          @document = stub
          @criteria = mock
          Person.expects(:criteria).returns(@criteria)
        end

        it "delegates to #id_criteria" do
          @criteria.expects(:id_criteria).with(@id).returns(@document)
          Mongoid::Criteria.translate(Person, @id).should == @document
        end
      end
    end

    context "multiple arguments" do

      context "when an array of ids" do

        before do
          @ids = []
          @documents = []
          3.times do
            @ids << BSON::ObjectId.new.to_s
            @documents << stub
          end
          @criteria = mock
          Person.expects(:criteria).returns(@criteria)
        end

        it "delegates to #id_criteria" do
          @criteria.expects(:id_criteria).with(@ids).returns(@documents)
          Mongoid::Criteria.translate(Person, @ids).should == @documents
        end

      end

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

      context "when Person, :conditions => {:id => id}" do

        before do
          @criteria = Mongoid::Criteria.translate(Person, :conditions => { :id => "1234e567" })
        end

        it "returns a criteria with a selector from the conditions" do
          @criteria.selector.should == { :_id => "1234e567" }
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

  context "===" do

    context "when the other object is a Criteria" do
      subject { Mongoid::Criteria === Mongoid::Criteria.allocate }
      it { should be_true }
    end

    context "when the other object is not compatible" do
      subject { Mongoid::Criteria === [] }
      it { should be_false }
    end

  end

end
