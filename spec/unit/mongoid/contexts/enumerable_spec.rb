require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before :all do
    Mongoid.raise_not_found_error = true
  end

  let(:london) { Address.new(:number => 1, :street => "Bond Street") }
  let(:shanghai) { Address.new(:number => 10, :street => "Nan Jing Dong Lu") }
  let(:melbourne) { Address.new(:number => 20, :street => "Bourke Street") }
  let(:new_york) { Address.new(:number => 20, :street => "Broadway") }
  let(:docs) { [ london, shanghai, melbourne, new_york ] }
  let(:context) { Mongoid::Contexts::Enumerable.new(criteria) }
  let(:criteria) do
    Mongoid::Criteria.new(Address).tap do |criteria|
      criteria.documents = docs
    end
  end

  describe "#aggregate" do

    let(:counts) { context.aggregate }
    before { criteria.only(:number) }

    it "groups by the fields provided in the options" do
      counts.size.should == 3
    end

    it "stores the counts in proper groups" do
      counts[1].should == 1
      counts[10].should == 1
      counts[20].should == 2
    end

  end

  describe "#avg" do

    it "returns the avg value for the supplied field" do
      context.avg(:number).should == 12.75
    end

  end

  describe "#count" do

    it "returns the size of the enumerable" do
      context.count.should == 4
    end

  end

  describe "#distinct" do

    context "when the criteria is limited" do

      before do
        criteria.where(:street => "Bourke Street")
      end

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should == [ "Bourke Street" ]
      end

    end

    context "when the criteria is not limited" do

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should ==
          [ "Bond Street", "Nan Jing Dong Lu", "Bourke Street", "Broadway" ]
      end

    end

  end

  describe "#execute" do

    it "calls sort on the filtered collection" do
      filtered_documents = []
      context.stubs(:filter).returns(filtered_documents)
      context.expects(:sort).with(filtered_documents)
      context.execute
    end

    context "when the selector is present" do
      before { criteria.where(:street => "Bourke Street") }
      it "returns the matching documents from the array" do
        context.execute.should == [ melbourne ]
      end
    end

    context "when selector is empty" do

      it "returns all the documents" do
        context.execute.should == docs
      end

    end

    context "when skip and limit are in the options" do

      before { criteria.skip(2).limit(2) }

      it "properly narrows down the matching results" do
        context.execute.should == [ melbourne, new_york ]
      end

    end

    context "when limit is set without skip in the options" do

      before { criteria.limit(2) }

      it "properly narrows down the matching results" do
        context.execute.size.should == 2
      end

    end

    context "when skip is set without limit in the options" do

      before { criteria.skip(2) }

      it "properly skips the specified records" do
        context.execute.size.should == 2
      end

    end

  end

  describe "#first" do

    context "when a selector is present" do
      before { criteria.where(:street => "Bourke Street") }

      it "returns the first that matches the selector" do
        context.first.should == melbourne
      end
    end

  end

  describe "#group" do

    let(:group) { context.group }
    before { criteria.only(:number) }

    it "groups by the fields provided in the options" do
      group.size.should == 3
    end

    it "stores the documents in proper groups" do
      group[1].should == [ london ]
      group[10].should == [ shanghai ]
      group[20].should == [ melbourne, new_york ]
    end

  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:documents) { [stub] }

    before do
      criteria.documents = documents
      criteria.where(selector).skip(20)
    end

    it "sets the selector" do
      context.selector.should == selector
    end

    it "sets the options" do
      context.options.should == options
    end

    it "sets the documents" do
      context.documents.should == documents
    end

  end

  describe "#iterate" do

    before { criteria.where(:street => "Bourke Street") }

    it "executes the criteria" do
      acc = []
      context.iterate do |doc|
        acc << doc
      end
      acc.should == [melbourne]
    end

  end

  describe "#last" do

    context "when the selector is present" do
      before { criteria.where(:street => "Bourke Street") }
      it "returns the last matching in the enumerable" do
        context.last.should == melbourne
      end
    end

  end

  describe "#max" do

    it "returns the max value for the supplied field" do
      context.max(:number).should == 20
    end

  end

  describe "#min" do

    it "returns the min value for the supplied field" do
      context.min(:number).should == 1
    end

  end

  describe "#one" do

    context "when the selector is present" do
      before { criteria.where(:street => "Bourke Street") }
      it "returns the first matching in the enumerable" do
        context.one.should == melbourne
      end
    end

  end

  describe "#page" do

    let(:criteria) do
      Mongoid::Criteria.new(Person).tap do |criteria|
        criteria.documents = []
      end
    end

    context "when the page option exists" do
      before { criteria.extras(:page => 5) }

      it "returns the page option" do
        context.page.should == 5
      end

    end

    context "when the page option does not exist" do

      it "returns 1" do
        context.page.should == 1
      end

    end

  end

  describe "#paginate" do
    let(:criteria) { Person.criteria.skip(2).limit(2) }
    let(:results) { context.paginate }

    it "executes and paginates the results" do
      results.current_page.should == 2
      results.per_page.should == 2
    end

  end

  describe "#per_page" do

    context "when a limit option exists" do

      it "returns 20" do
        context.per_page.should == 20
      end

    end

    context "when a limit option does not exist" do

      let(:criteria) do
        Person.criteria.limit(50).tap do |criteria|
          criteria.documents = []
        end
      end

      it "returns the limit" do
        context.per_page.should == 50
      end

    end

  end

  describe "#sort" do

    context "with no sort options" do
      it "returns the documents as is" do
        context.send(:sort, docs).should == docs
      end
    end

    context "with sort options" do
      before { context.options[:sort] = [ [:created_at, :asc] ] }
      it "sorts by the key" do
        docs.expects(:sort_by).once
        context.send(:sort, docs)
      end
    end

  end

  describe "#sum" do

    it "returns the sum of all the field values" do
      context.sum(:number).should == 51
    end

  end

  context "#id_criteria" do

    let(:criteria) do
      criteria = Mongoid::Criteria.new(Address)
      criteria.documents = []
      criteria
    end
    let(:context) { criteria.context }

    context "with a single argument" do

      let(:id) { BSON::ObjectId.new.to_s }

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
          (0..2).inject([]) { |ary, i| ary << BSON::ObjectId.new.to_s }
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
          (0..2).inject([]) { |ary, i| ary << BSON::ObjectId.new }
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
