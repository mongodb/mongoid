require "spec_helper"

describe Mongoid::Criteria do

  before do
    Person.delete_all
  end

  context "===" do

    context "when the other object is a Criteria" do

      let(:other) do
        Mongoid::Criteria.allocate
      end

      it "returns true" do
        (Mongoid::Criteria === other).should be_true
      end
    end

    context "when the other object is not compatible" do

      let(:other) do
        []
      end

      it "returns false" do
        (Mongoid::Criteria === other).should be_false
      end
    end
  end

  describe "#as_conditions" do

    context "when the options contain sort criteria" do

      let(:criteria) do
        Person.where(:title => "Sir").asc(:score)
      end

      it "changes sort to order_by" do
        criteria.as_conditions.should eq(
          { :where => { :title => "Sir" }, :order_by => [[ :score, :asc ]] }
        )
      end
    end
  end

  describe "#clone" do

    let(:criteria) do
      Person.only(:title).where(:age.gt => 30).skip(10).asc(:age)
    end

    let(:copy) do
      criteria.clone
    end

    it "copies the selector" do
      copy.selector.should eq(criteria.selector)
    end

    it "copies the options" do
      copy.options.should eq(criteria.options)
    end

    it "copies the embedded flag" do
      copy.embedded.should eq(criteria.embedded)
    end

    it "references the class" do
      copy.klass.should eql(criteria.klass)
    end

    it "references the documents" do
      copy.documents.should eql(criteria.documents)
    end
  end

  describe "#find" do

    context "when using object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      let!(:person) do
        Person.create(
          :title => "Sir",
          :age => 33,
          :aliases => ["D", "Durran"],
          :things => [{:phone => 'HTC Incredible'}]
        )
      end

      it 'should find object with String args' do
        Person.find(person.id.to_s).should eq(person)
      end

      it 'should find object with BSON::ObjectId  args' do
        Person.find(person.id).should eq(person)
      end
    end

    context "when not using object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: String,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new.to_s }
        )
      end

      after(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new }
        )
      end

      let!(:person) do
        Person.create(
          :title => "Sir",
          :age => 33,
          :aliases => ["D", "Durran"],
          :things => [{:phone => 'HTC Incredible'}]
        )
      end

      it 'should find the object with a matching String arg' do
        Person.find(person.id.to_s).should eq(person)
      end

      it 'should find the object with a matching BSON::ObjectId argument' do
        Person.find(BSON::ObjectId(person.id)).should eq(person)
      end
    end
  end

  describe "#fuse" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    context "when providing a selector" do

      let(:result) do
        criteria.fuse(:where => { :title => 'Test' })
      end

      it "adds the selector" do
        result.selector[:title].should eq('Test')
      end
    end

    context "when providing a selector and options" do

      let(:result) do
        criteria.fuse(:where => { :title => 'Test' }, :skip => 10)
      end

      it "adds the selector" do
        result.selector[:title].should eq('Test')
      end

      it "adds the options" do
        result.options.should eq({ :skip => 10 })
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    it "sets the selector to an empty hash" do
      criteria.selector.should eq({})
    end

    it "sets the options to an empty hash" do
      criteria.options.should eq({})
    end

    it "sets the documents to an empty array" do
      criteria.documents.should be_empty
    end

    it "sets the klass to the given class" do
      criteria.klass.should eq(Person)
    end
  end

  describe "#merge" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

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
          merged.selector.should eq(selector)
        end

        it "merges the options" do
          merged.options.should eq(options)
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
          merged.selector.should eq(selector)
        end

        it "merges the options" do
          merged.options.should eq(options)
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
          merged.documents.should eq(documents)
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
          merged.selector.should eq(selector)
        end

        it "merges the options" do
          merged.options.should eq(options)
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
          merged.selector.should eq(selector)
        end

        it "merges the options" do
          merged.options.should eq(options)
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
      chained.selector.should eq({ :title => "Sir", :terms => true })
    end

    context "chaining more than one scope" do

      let(:criteria) do
        Person.accepted.knight
      end

      let(:chained) do
        criteria.where(:security_code => "5555")
      end

      it "returns the final merged criteria" do
        criteria.selector.should eq(
          { :title => "Sir", :terms => true }
        )
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
          criteria[0].should eq(document)
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

  describe "#to_json" do

    let(:criteria) do
      Person.all
    end

    before do
      Person.create(:ssn => "555-55-1212")
    end

    it "returns the results as a json string" do
      criteria.to_json.should include("\"ssn\":\"555-55-1212\"")
    end
  end

  context "when caching" do

    before do
      5.times do |n|
        Person.create!(
          :title => "Sir",
          :age => (n * 10),
          :aliases => ["D", "Durran"],
          :ssn => "#{n}"
        )
      end
    end

    let(:criteria) do
      Person.where(:title => "Sir").cache
    end

    it "iterates over the cursor only once" do
      criteria.size.should eq(5)
      Person.create!(:title => "Sir")
      criteria.size.should eq(5)
    end
  end

  context "when chaining criteria after an initial execute" do

    let(:criteria) do
      Mongoid::Criteria.new(Person)
    end

    it 'should not carry scope to cloned criteria' do
      criteria.first
      criteria.limit(1).context.options[:limit].should eq(1)
    end
  end
end
