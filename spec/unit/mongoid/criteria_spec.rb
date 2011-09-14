require "spec_helper"

describe Mongoid::Criteria do

  let(:criteria) do
    Mongoid::Criteria.new(Person)
  end

  let(:canvas_criteria) do
    Mongoid::Criteria.new(Canvas)
  end

  context "===" do

    context "when the other object is a Criteria" do

      let(:other) do
        Mongoid::Criteria.allocate
      end

      it "returns true" do
        Mongoid::Criteria.should === other
      end
    end

    context "when the other object is not compatible" do

      let(:other) do
        []
      end

      it "returns false" do
        Mongoid::Criteria.should_not === other
      end
    end
  end

  describe "#+" do

    let(:sir) do
      Person.new(:title => "Sir")
    end

    let(:canvas) do
      Canvas.new
    end

    let(:collection) do
      stub
    end

    let(:cursor) do
      stub(:count => 1)
    end

    before do
      cursor.expects(:each).yields(sir)
      Person.expects(:collection).returns(collection)
      collection.expects(:find).returns(cursor)
    end

    context "when the criteria has not been executed" do

      it "executes the criteria and concats the results" do
        results = criteria + [ canvas ]
        results.should == [ sir, canvas ]
      end
    end

    context "when the other is a criteria" do

      let(:canvas_collection) do
        stub
      end

      let(:canvas_cursor) do
        stub(:count => 1)
      end

      before do
        canvas_cursor.expects(:each).yields(canvas)
        Canvas.expects(:collection).returns(canvas_collection)
        canvas_collection.expects(:find).returns(canvas_cursor)
      end

      it "concats the results" do
        results = criteria + canvas_criteria
        results.should == [ sir, canvas ]
      end
    end
  end

  describe "#-" do

    let(:sir) do
      Person.new(:title => "Sir")
    end

    let(:madam) do
      Person.new(:title => "Madam")
    end

    let(:collection) do
      stub
    end

    let(:cursor) do
      stub(:count => 1)
    end

    before do
      cursor.expects(:each).yields(madam)
      Person.expects(:collection).returns(collection)
      collection.expects(:find).returns(cursor)
    end

    context "when the criteria has not been executed" do

      it "executes the criteria and returns the difference" do
        results = criteria - [ sir ]
        results.should == [ madam ]
      end
    end
  end

  describe "#[]" do

    let(:collection) do
      stub
    end

    let(:cursor) do
      stub(:count => 10)
    end

    let(:person) do
      Person.new(:title => "Sir")
    end

    let(:new_criteria) do
      criteria.where(:title => "Sir")
    end

    before do
      cursor.expects(:each).yields(person)
        Person.expects(:collection).returns(collection)
    end

    context "when the criteria has not been executed" do

      before do
        collection.expects(:find).with({ :title => "Sir"}, {}).returns(cursor)
      end

      it "executes the criteria and returns the element at the index" do
        new_criteria[0].should == person
      end
    end
  end

  context "when methods delegate to the context" do

    let(:context) do
      stub
    end

    before do
      criteria.instance_variable_set(:@context, context)
    end

    describe "#aggregate" do

      before do
        context.expects(:aggregate)
      end

      it "delegates to the context" do
        criteria.aggregate
      end
    end

    describe "#avg" do

      before do
        context.expects(:avg).with(:age)
      end

      it "delegates to the context" do
        criteria.avg(:age)
      end
    end

    describe "#blank?" do

      context "when the context is blank" do

        before do
          context.expects(:blank?).returns(true)
        end

        it "returns true" do
          criteria.blank?.should be_true
        end
      end

      context "when the context is not blank" do

        before do
          context.expects(:blank?).returns(false)
        end

        it "returns false" do
          criteria.blank?.should be_false
        end
      end
    end

    describe "#distinct" do

      before do
        context.expects(:distinct).with(:title)
      end

      it "delegates to the context" do
        criteria.distinct(:title)
      end
    end

    describe "#count" do

      before do
        context.expects(:count).returns(10)
      end

      it "delegates to the context" do
        criteria.count.should == 10
      end
    end

    describe "#size" do

      before do
        context.expects(:size).returns(10)
      end

      it "delegates to the context" do
        criteria.size.should == 10
      end
    end

    describe "#length" do

      before do
        context.expects(:length).returns(10)
      end

      it "delegates to the context" do
        criteria.length.should == 10
      end
    end

    describe "#exists?" do

      context "when there are documents in the db" do

        before do
          context.expects(:count).returns(10)
        end

        it "call the count context and return true if there are element" do
          criteria.exists?.should be_true
        end
      end

      context "when there are no documents in the db" do

        before do
          context.expects(:count).returns(0)
        end

        it "call the count context and return false if there are no element" do
          criteria.exists?.should be_false
        end
      end
    end

    describe "#first" do

      before do
        context.expects(:first).returns([])
      end

      it "delegates to the context" do
        criteria.first.should == []
      end
    end

    describe "#freeze" do

      context "when the context has been initialized" do

        let(:frozen) do
          described_class.new(Person)
        end

        before do
          frozen.context
          frozen.freeze
        end

        it "does not raise an error on iteration" do
          expect {
            frozen.entries
          }.to_not raise_error
        end
      end

      context "when the context has not been initialized" do

        let(:frozen) do
          described_class.new(Person)
        end

        before do
          frozen.freeze
        end

        it "does not raise an error on iteration" do
          expect {
            frozen.entries
          }.to_not raise_error
        end
      end
    end

    describe "#group" do

      before do
        context.expects(:group).returns({})
      end

      it "delegates to the context" do
        criteria.group.should == {}
      end
    end

    describe "#last" do

      before do
        context.expects(:last).returns([])
      end

      it "delegates to the context" do
        criteria.last.should == []
      end
    end

    describe "#max" do

      before do
        context.expects(:max).with(:field).returns(100)
      end

      it "delegates to the context" do
        criteria.max(:field).should == 100
      end
    end

    describe "#min" do

      before do
        context.expects(:min).with(:field).returns(100)
      end

      it "delegates to the context" do
        criteria.min(:field).should == 100
      end
    end

    describe "#one" do

      before do
        context.expects(:one)
      end

      it "delegates to the context" do
        criteria.one
      end
    end

    describe "#sum" do

      before do
        context.expects(:sum).with(:field).returns(20)
      end

      it "delegates to the context" do
        criteria.sum(:field).should == 20
      end
    end
  end

  describe "#clone" do

    let(:criteria) do
      Person.only(:title).where(:age.gt => 30).skip(10)
    end

    let(:copy) do
      criteria.clone
    end

    it "copies the selector" do
      copy.selector.should == criteria.selector
    end

    it "copies the options" do
      copy.options.should == criteria.options
    end

    it "copies the embedded flag" do
      copy.embedded.should == criteria.embedded
    end

    it "references the class" do
      copy.klass.should eql(criteria.klass)
    end

    it "references the documents" do
      copy.documents.should eql(criteria.documents)
    end
  end

  describe "#context" do

    context "when the context has been set" do

      let(:context) do
        stub
      end

      before do
        criteria.instance_variable_set(:@context, context)
      end

      it "returns the memoized context" do
        criteria.context.should == context
      end
    end

    context "when the context has not been set" do

      let(:context) do
        stub
      end

      it "creates a new context" do
        Mongoid::Contexts::Mongo.expects(:new).with(criteria).returns(context)
        criteria.context.should == context
      end
    end

    context "when the class is embedded" do

      let(:criteria) do
        Mongoid::Criteria.new(Address, true)
      end

      it "returns an enumerable context" do
        criteria.context.should be_a_kind_of(Mongoid::Contexts::Enumerable)
      end
    end

    context "when the class is not embedded" do

      it "returns a mongo context" do
        criteria.context.should be_a_kind_of(Mongoid::Contexts::Mongo)
      end
    end
  end

  describe "#entries" do

    let(:collection) do
      stub
    end

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    before do
      Person.expects(:collection).returns(collection)
    end

    context "when type is :all" do

      let(:cursor) do
        stub(:count => 44)
      end

      before do
        cursor.expects(:each)
        collection.expects(:find).with(criteria.selector, criteria.options).returns(cursor)
        criteria.entries
      end

      it "does not add the count instance variable" do
        criteria.instance_variable_get(:@count).should be_nil
      end
    end

    context "when type is not :first" do

      let(:criteria) do
        Mongoid::Criteria.new(Person)
      end

      it "calls find on the collection with the selector and options" do
        collection.expects(:find).with(criteria.selector, criteria.options).returns([])
        criteria.entries
      end
    end
  end

  describe "#each" do

    let(:collection) do
      stub
    end

    let(:person) do
      Person.new(:title => "Sir")
    end

    let(:cursor) do
      stub(:count => 10)
    end

    let(:context) do
      stub
    end

    let(:new_criteria) do
      criteria.where(:title => "Sir")
    end

    context "when the criteria has not been executed" do

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with({:title => "Sir"}, {}).returns(cursor)
        cursor.expects(:each).yields(person)
      end

      it "executes the criteria" do
        new_criteria.each do |doc|
          doc.should == person
        end
      end
    end

    context "when the criteria has been executed" do

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with({:title => "Sir"}, {}).returns(cursor)
        cursor.expects(:each).yields(person)
      end

      it "calls each on the existing results" do
        new_criteria.each do |person|
          person.should == person
        end
      end
    end

    context "when no block is passed" do

      it "returns self" do
        new_criteria.each.should == new_criteria
      end
    end

    context "when caching" do

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with(
          { :title => "Sir" },
          { :cache => true }
        ).returns(cursor)
        cursor.expects(:each).yields(person)
      end

      it "caches the results of the cursor iteration" do
        new_criteria.cache.each do |doc|
          doc.should == person
        end
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

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

  describe "#merge" do

    before do
      criteria.where(:title => "Sir", :age => 30).skip(40).limit(20)
    end

    context "with another criteria" do

      context "when the other has a selector and options" do

        let(:other) do
          criteria.where(:name => "Chloe").order_by([[:name, :asc]])
        end

        let(:selector) do
          { :title => "Sir", :age => 30, :name => "Chloe" }
        end

        let(:options) do
          { :skip => 40, :limit => 20, :sort => [[:name, :asc]] }
        end

        let(:merged) do
          criteria.merge(other)
        end

        before do
          other.selector = selector
          other.options = options
        end

        it "merges the selector" do
          merged.selector.should == selector
        end

        it "merges the options" do
          merged.options.should == options
        end
      end

      context "when the other has no selector or options" do

        let(:other) do
          Mongoid::Criteria.new(Person)
        end

        let(:selector) do
          { :title => "Sir", :age => 30 }
        end

        let(:options) do
          { :skip => 40, :limit => 20 }
        end

        let(:new_criteria) do
          Mongoid::Criteria.new(Person)
        end

        let(:merged) do
          new_criteria.merge(other)
        end

        before do
          new_criteria.selector = selector
          new_criteria.options = options
        end

        it "merges the selector" do
          merged.selector.should == selector
        end

        it "merges the options" do
          merged.options.should == options
        end
      end

      context "when the other has a document collection" do

        let(:other) do
          Mongoid::Criteria.new(Person)
        end

        let(:documents) do
          [ stub ]
        end

        let(:merged) do
          criteria.merge(other)
        end

        before do
          other.documents = documents
        end

        it "merges the documents collection in" do
          merged.documents.should == documents
        end
      end
    end

    context "with a conditions hash" do

      context "when the other has a selector and options" do

        let(:other) do
          { :conditions => { :name => "Chloe" }, :sort => [[ :name, :asc ]] }
        end

        let(:selector) do
          { :title => "Sir", :name => "Chloe" }
        end

        let(:options) do
          { :skip => 40, :sort => [[:name, :asc]] }
        end

        let(:crit) do
          criteria.where(:title => "Sir").skip(40)
        end

        let(:merged) do
          crit.merge(other)
        end

        it "merges the selector" do
          merged.selector.should == selector
        end

        it "merges the options" do
          merged.options.should == options
        end
      end

      context "when the other has no conditions" do

        let(:other) do
          { :sort => [[ :name, :asc ]] }
        end

        let(:selector) do
          { :title => "Sir" }
        end

        let(:options) do
          { :skip => 40, :sort => [[:name, :asc]] }
        end

        let(:crit) do
          criteria.where(:title => "Sir").skip(40)
        end

        let(:merged) do
          crit.merge(other)
        end

        it "merges the selector" do
          merged.selector.should == selector
        end

        it "merges the options" do
          merged.options.should == options
        end
      end
    end
  end

  describe "#method_missing" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    let(:new_criteria) do
      criteria.accepted
    end

    let(:chained) do
      new_criteria.where(:title => "Sir")
    end

    it "merges the criteria with the next one" do
      chained.selector.should == { :title => "Sir", :terms => true }
    end

    context "chaining more than one scope" do

      let(:criteria) do
        Person.accepted.old.knight
      end

      let(:chained) do
        criteria.where(:security_code => "5555")
      end

      it "returns the final merged criteria" do
        criteria.selector.should ==
          { :title => "Sir", :terms => true, :age => { "$gt" => 50 } }
      end

      it "always returns a new criteria" do
        chained.should_not eql(criteria)
      end

    end

    context "when returning a non-criteria object" do

      let(:ages) do
        [ 10, 20 ]
      end

      before do
        Person.stubs(:ages => ages)
      end

      it "does not attempt to merge" do
        expect { criteria.ages }.to_not raise_error(NoMethodError)
      end
    end

    context "when expecting behaviour of an array" do

      let(:array) do
        stub
      end

      let(:document) do
        stub
      end

      describe "#[]" do

        before do
          criteria.expects(:entries).returns([ document ])
        end

        it "collects the criteria and calls []" do
          criteria[0].should == document
        end
      end

      describe "#rand" do

        before do
          criteria.expects(:entries).returns(array)
          array.expects(:send).with(:rand).returns(document)
        end

        it "collects the criteria and call rand" do
          criteria.rand
        end
      end
    end
  end

  describe "#respond_to?" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    before do
      Person.stubs(:ages => [])
    end

    it "is true when asking about a model's class method" do
      criteria.respond_to?(:ages).should be_true
    end

    it "is false when asking about a model's private class method even when including private methods" do
      criteria.respond_to?(:alias_method, true).should be_false
    end

    it "is true when asking about a criteria's entries' instance method" do
      criteria.respond_to?(:join).should be_true
    end

    it "is false when asking about a criteria's entries' private instance methods without including private methods" do
      criteria.respond_to?(:fork).should be_false
    end

    it "is false when asking about a criteria's entries' private instance methods when including private methods" do
      criteria.respond_to?(:fork, true).should be_true
    end

    it "is true when asking about a criteria instance method" do
      criteria.respond_to?(:context).should be_true
    end

    it "is false when asking about a private criteria instance method without including private methods" do
      criteria.respond_to?(:puts).should be_false
    end

    it "is true when asking about a private criteria instance method when including private methods" do
      criteria.respond_to?(:puts, true).should be_true
    end

  end

  describe "#scoped" do

    context "when the options contain sort criteria" do

      let(:criteria) do
        Person.where(:title => "Sir").asc(:score)
      end

      it "changes sort to order_by" do
        criteria.scoped.should == { :where => { :title => "Sir" }, :order_by => [[:score, :asc]] }
      end
    end
  end

  describe "#search" do

    let(:criteria) do
      Person.criteria
    end

    context "with a single argument" do

      context "when the arg is nil" do

        it "adds the id selector" do
          expect {
            criteria.search(nil)
          }.to raise_error(Mongoid::Errors::InvalidFind)
        end
      end

      context "when the arg is a string" do

        let(:id) do
          BSON::ObjectId.new.to_s
        end

        it "adds the id selector" do
          criteria.search(id)[1].selector.should == { :_id => BSON::ObjectId.from_string(id) }
        end
      end

      context "when the arg is an object id" do

        let(:id) do
          BSON::ObjectId.new
        end

        it "adds the id selector" do
          criteria.search(id)[1].selector.should == { :_id => id }
        end
      end
    end

    context "multiple arguments" do

      context "when an array of ids" do

        let(:ids) do
          []
        end

        before do
          3.times do
            ids << BSON::ObjectId.new
          end
        end

        it "delegates to #id_criteria" do
          criteria.search(ids.map(&:to_s))[1].selector.should ==
            { :_id => { "$in" => ids } }
        end
      end

      context "when Person, :conditions => {}" do

        let(:crit) do
          criteria.search(:all, :conditions => { :title => "Test" })[1]
        end

        it "returns a criteria with a selector from the conditions" do
          crit.selector.should == { :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          crit.klass.should == Person
        end
      end

      context "when Person, :conditions => {:id => id}" do

        let(:id) do
          BSON::ObjectId.new
        end

        let(:crit) do
          criteria.search(:all, :conditions => { :id => id })[1]
        end

        it "returns a criteria with a selector from the conditions" do
          crit.selector.should == { :_id => id }
        end

        it "returns a criteria with klass Person" do
          crit.klass.should == Person
        end
      end

      context "when :all, :conditions => {}" do

        let(:crit) do
          criteria.search(:all, :conditions => { :title => "Test" })[1]
        end

        it "returns a criteria with a selector from the conditions" do
          crit.selector.should == { :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          crit.klass.should == Person
        end
      end

      context "when :last, :conditions => {}" do

        let(:crit) do
          criteria.search(:last, :conditions => { :title => "Test" })[1]
        end

        it "returns a criteria with a selector from the conditions" do
          crit.selector.should == { :title => "Test" }
        end

        it "returns a criteria with klass Person" do
          crit.klass.should == Person
        end
      end

      context "when options are provided" do

        let(:crit) do
          criteria.search(
            :all,
            :conditions => { :title => "Test" }, :skip => 10
          )[1]
        end

        it "sets the selector" do
          crit.selector.should == { :title => "Test" }
        end

        it "sets the options" do
          crit.options.should == { :skip => 10 }
        end
      end
    end
  end

  describe "#fuse" do

    context "when providing a selector" do

      let(:result) do
        criteria.fuse(:where => { :title => 'Test' })
      end

      it "adds the selector" do
        result.selector[:title].should == 'Test'
      end
    end

    context "when providing a selector and options" do

      let(:result) do
        criteria.fuse(:where => { :title => 'Test' }, :skip => 10)
      end

      it "adds the selector" do
        result.selector[:title].should == 'Test'
      end

      it "adds the options" do
        result.options.should == { :skip => 10 }
      end
    end
  end

  context "when chaining criteria after an initial execute" do
    it 'should not carry scope to cloned criteria' do
      criteria.first
      criteria.limit(1).context.options[:limit].should == 1
    end
  end
end
