require "spec_helper"

describe Mongoid::Contexts::Mongo do

  before :all do
    Mongoid.raise_not_found_error = true
  end

  let(:criteria) do
    Mongoid::Criteria.new(Person)
  end

  describe "#aggregate" do

    let(:crit) do
      criteria.only(:field1)
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(crit)
    end

    context "when klass not provided" do

      let(:reduce) do
        "function(obj, prev) { prev.count++; }"
      end

      let(:collection) do
        stub
      end

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:group).with(
          :key => [:field1],
          :cond => {},
          :initial => {:count => 0},
          :reduce => reduce
        )
      end

      it "calls group on the collection with the aggregate js" do
        context.aggregate
      end
    end
  end

  describe "#avg" do

    let(:reduce) do
      Mongoid::Javascript.sum.gsub("[field]", "age")
    end

    let(:collection) do
      stub
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(criteria)
    end

    before do
      Person.expects(:collection).twice.returns(collection)
      collection.expects(:group).with(
        :cond => {},
        :initial => {:sum => "start"},
        :reduce => reduce
      ).returns([{"sum" => 100.0}])
      cursor = mock(:count => 10)
      collection.expects(:find).returns(cursor)
    end

    it "calls group on the collection with the aggregate js" do
      context.avg(:age).should eq(10)
    end
  end

  describe "blank?" do

    let(:crit) do
      Mongoid::Criteria.new(Game).where(:test => "Testing")
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(crit)
    end

    let(:doc) do
      stub
    end

    let(:collection) do
      stub
    end

    before do
      Game.expects(:collection).returns(collection)
    end

    context "when a document exists" do

      before do
        collection.expects(:find_one).with({ :test => "Testing" }, { :fields => [ :_id ] }).returns(doc)
      end

      it "returns false" do
        context.blank?.should be_false
      end
    end

    context "when a document does not exist" do

      before do
        collection.expects(:find_one).with({ :test => "Testing" }, { :fields => [ :_id ] }).returns(nil)
      end

      it "returns true" do
        context.blank?.should be_true
      end
    end
  end

  describe "#count" do

    let(:crit) do
      criteria.where(:test => 'Testing')
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(crit)
    end

    context "when criteria has been executed" do

      let(:collection) do
        stub
      end

      let(:cursor) do
        stub
      end

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find).with(crit.selector, {}).returns(cursor)
        cursor.expects(:count).returns(10)
      end

      it "returns the count from the cursor without creating the documents" do
        context.count.should eq(10)
      end
    end
  end

  describe "#distinct" do

    let(:distinct) do
      criteria.where(:test => 'Testing')
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(distinct)
    end

    let(:collection) do
      stub
    end

    before do
      Person.expects(:collection).returns(collection)
      collection.expects(:distinct).with(:title, distinct.selector).returns(["Sir"])
    end

    it "returns delegates to distinct on the collection" do
      context.distinct(:title).should eq(["Sir"])
    end
  end

  describe "#execute" do

    let(:selector) do
      { :field => "value"  }
    end

    let(:options) do
      { :skip => 20 }
    end

    let(:executed) do
      criteria.where(selector).skip(20)
    end

    let(:collection) do
      stub
    end

    let(:cursor) do
      stub(:count => 500)
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(executed)
    end

    before do
      Person.expects(:collection).returns(collection)
    end

    context "with a regular selector" do

      before do
        collection.expects(:find).with(selector, options).returns(cursor)
      end

      it "calls find on the collection" do
        context.execute.should eq(cursor)
      end
    end

    context "when field options are supplied" do

      context "when _type not in the field list" do

        let(:crit) do
          executed.only(:title)
        end

        let(:context) do
          Mongoid::Contexts::Mongo.new(crit)
        end

        let(:expected_options) do
          { :skip => 20, :fields => { :title => 1, :_type => 1} }
        end

        it "adds _type to the fields" do
          collection.expects(:find).with(selector, expected_options).returns(cursor)
          context.execute.should eq(cursor)
        end
      end
    end
  end

  describe "#group" do

    let(:grouped) do
      criteria.only(:field1)
    end

    let(:grouping) do
      [{ "title" => "Sir", "group" => [{ "title" => "Sir", "age" => 30, "_type" => "Person" }] }]
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(grouped)
    end

    context "when klass provided" do

      let(:reduce) do
        "function(obj, prev) { prev.group.push(obj); }"
      end

      let(:collection) do
        stub
      end

      before do
        Person.expects(:collection).returns(collection)
      end

      it "calls group on the collection with the aggregate js" do
        collection.expects(:group).with(
          :key => [:field1],
          :cond => {},
          :initial => {:group => []},
          :reduce => reduce
        ).returns(grouping)
        context.group
      end
    end
  end

  describe ".initialize" do

    let(:selector) do
      { :field => "value"  }
    end

    let(:options) do
      { :skip => 20 }
    end

    let(:klass) do
      Doctor
    end

    let(:criteria) do
      Mongoid::Criteria.new(klass).where(selector).skip(20)
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(criteria)
    end

    context "when hereditary" do

      it "set the selector to query across the _type when it is hereditary" do
        context.selector[:_type].should eq({'$in' => klass._types})
      end
    end

    context "when not hereditary" do

      let(:criteria) do
        Mongoid::Criteria.new(Name)
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      it "does not add the type to the selector" do
        context.selector[:_type].should be_nil
      end
    end
  end

  describe "#iterate" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    let(:cursor) do
      stub
    end

    before do
      cursor.stubs(:each).yields(person)
    end

    context "when not caching" do

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      before do
        context.expects(:execute).returns(cursor)
      end

      it "executes the criteria" do
        context.iterate do |person|
          person.should eq(person)
        end
      end
    end

    context "when caching" do

      let(:cached) do
        criteria.cache
      end

      context "when executing once" do

        let(:context) do
          Mongoid::Contexts::Mongo.new(cached)
        end

        before do
          context.expects(:execute).returns(cursor)
        end

        it "executes the criteria" do
          context.iterate do |person|
            person.should eq(person)
          end
        end
      end

      context "when executing twice" do

        let(:context) do
          Mongoid::Contexts::Mongo.new(cached)
        end

        before do
          context.expects(:execute).once.returns(cursor)
        end

        it "executes only once and it caches the result" do
          2.times do
            context.iterate do |person|
              person.should eq(person)
            end
          end
        end
      end

      context "when there is no block" do

        let(:context) do
          Mongoid::Contexts::Mongo.new(cached)
        end

        before do
          context.expects(:execute).once.returns(cursor)
        end

        it "executes the context" do
          context.iterate
        end
      end
    end
  end

  describe "#last" do

    let(:collection) do
      stub
    end

    before do
      Person.expects(:collection).returns(collection)
    end

    context "when documents exist" do

      let(:ordered) do
        criteria.order_by([[:title, :asc]])
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(ordered)
      end

      before do
        collection.expects(:find_one).with(
          {},
          { :sort => [[:title, :desc], [:_id, :desc]] }
        ).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and sort options reversed" do
        context.last.should be_a_kind_of(Person)
      end
    end

    context "when no documents exist" do

      let(:ordered) do
        criteria.order_by([[:_id, :asc]])
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(ordered)
      end

      before do
        collection.expects(:find_one).with(
          {},
          { :sort => [[:_id, :desc]] }
        ).returns(nil)
      end

      it "returns nil" do
        context.last.should be_nil
      end
    end

    context "when no sorting options provided" do

      let(:ordered) do
        criteria.order_by([[:_id, :asc]])
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      before do
        collection.expects(:find_one).with(
          {},
          { :sort => [[:_id, :desc]] }
        ).returns(
          { "title" => "Sir", "_type" => "Person" }
        )
      end

      it "defaults to sort by id" do
        context.last
      end
    end
  end

  describe "#max" do

    let(:reduce) do
      Mongoid::Javascript.max.gsub("[field]", "age")
    end

    let(:collection) do
      mock
    end

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(criteria)
    end

    before do
      Person.expects(:collection).returns(collection)
    end

    it "calls group on the collection with the aggregate js" do
      collection.expects(:group).with(
        :cond => {},
        :initial => {:max => "start"},
        :reduce => reduce
      ).returns([{"max" => 200.0}])
      context.max(:age).should eq(200.0)
    end
  end

  describe "#min" do

    let(:reduce) do
      Mongoid::Javascript.min.gsub("[field]", "age")
    end

    let(:collection) do
      mock
    end

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    let(:context) do
      Mongoid::Contexts::Mongo.new(criteria)
    end

    before do
      Person.expects(:collection).returns(collection)
    end

    it "calls group on the collection with the aggregate js" do
      collection.expects(:group).with(
        :cond => {},
        :initial => {:min => "start"},
        :reduce => reduce
      ).returns([{"min" => 4.0}])
      context.min(:age).should eq(4.0)
    end
  end

  describe "#first" do

    context "when documents exist" do

      let(:collection) do
        mock
      end

      let(:criteria) do
        Mongoid::Criteria.new(Person)
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(
          {},
          {:sort => [[:_id, :asc ]]}
        ).returns(
          { "title"=> "Sir", "_type" => "Person" }
        )
      end

      it "calls find on the collection with the selector and options" do
        context.one.should be_a_kind_of(Person)
      end
    end

    context "when no documents exist" do

      let(:collection) do
        mock
      end

      let(:criteria) do
        Mongoid::Criteria.new(Person)
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      before do
        Person.expects(:collection).returns(collection)
        collection.expects(:find_one).with(
          {},
          {:sort => [[:_id, :asc ]]}
        ).returns(nil)
      end

      it "returns nil" do
        context.one.should be_nil
      end
    end
  end

  describe "#shift" do

    let(:collection) { [1, 2, 3] }
    let(:criteria) { Person.criteria }
    let(:context) { Mongoid::Contexts::Mongo.new(criteria) }

    before do
      Person.stubs(:collection).returns(collection)
    end

    after do
      Person.unstub(:collection)
    end

    it "returns the first document" do
      context.expects(:first).returns(collection.first)
      context.shift.should eq(collection.first)
    end

    it "updates the criteria with the new skip value" do
      context.stubs(:first)
      context.options[:skip] = 1
      criteria.expects(:skip).with(2)
      context.shift
    end
  end

  describe "#sum" do

    context "when klass not provided" do

      let(:reduce) do
        Mongoid::Javascript.sum.gsub("[field]", "age")
      end

      let(:collection) do
        mock
      end

      let(:criteria) do
        Mongoid::Criteria.new(Person)
      end

      let(:context) do
        Mongoid::Contexts::Mongo.new(criteria)
      end

      before do
        Person.expects(:collection).returns(collection)
      end

      it "calls group on the collection with the aggregate js" do
        collection.expects(:group).with(
          :cond => {},
          :initial => {:sum => "start"},
          :reduce => reduce
        ).returns([{"sum" => 50.0}])
        context.sum(:age).should eq(50.0)
      end
    end
  end
end
