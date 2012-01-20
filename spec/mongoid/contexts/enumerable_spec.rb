require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before(:all) do
    Mongoid.raise_not_found_error = true
  end

  let(:london) do
    Address.new(:number => 1, :street => "Bond Street")
  end

  let(:shanghai) do
    Address.new(:number => 10, :street => "Nan Jing Dong Lu")
  end

  let(:melbourne) do
    Address.new(:number => 20, :street => "Bourke Street")
  end

  let(:new_york) do
    Address.new(:number => 20, :street => "Broadway")
  end

  let(:berlin) do
    Address.new(:street => "Hobrechtstr")
  end

  let(:docs) do
    [ london, shanghai, melbourne, new_york, berlin ]
  end

  let(:criteria) do
    Mongoid::Criteria.new(Address).tap do |criteria|
      criteria.documents = docs
    end
  end

  let(:context) do
    described_class.new(criteria)
  end

  describe "#aggregate" do

    let(:counts) do
      context.aggregate
    end

    before do
      context.criteria = criteria.only(:number)
    end

    it "groups by the fields provided in the options" do
      counts.size.should eq(4)
    end

    it "groups the first group properly" do
      counts[1].should eq(1)
    end

    it "groups the second group properly" do
      counts[10].should eq(1)
    end

    it "groups the third group properly" do
      counts[20].should eq(2)
    end
  end

  describe "#avg" do

    it "returns the avg value for the supplied field" do
      context.avg(:number).should eq(10.2)
    end
  end

  describe "#count" do

    it "returns the size of the enumerable" do
      context.count.should eq(5)
    end
  end

  describe "#distinct" do

    context "when the criteria is limited" do

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should eq([ "Bourke Street" ])
      end
    end

    context "when the criteria is not limited" do

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should eq(
          [ "Bond Street", "Nan Jing Dong Lu", "Bourke Street", "Broadway", "Hobrechtstr" ]
        )
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

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns the matching documents from the array" do
        context.execute.should eq([ melbourne ])
      end
    end

    context "when selector is empty" do

      it "returns all the documents" do
        context.execute.should eq(docs)
      end
    end

    context "when skip and limit are in the options" do

      before do
        context.criteria = criteria.skip(2).limit(2)
      end

      it "properly narrows down the matching results" do
        context.execute.should eq([ melbourne, new_york ])
      end
    end

    context "when limit is set without skip in the options" do

      before do
        context.criteria = criteria.limit(2)
      end

      it "properly narrows down the matching results" do
        context.execute.size.should eq(2)
      end
    end

    context "when skip is set without limit in the options" do

      before do
        context.criteria = criteria.skip(2)
      end

      it "properly skips the specified records" do
        context.execute.size.should eq(3)
      end
    end
  end

  describe "#first" do

    context "when a selector is present" do

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns the first that matches the selector" do
        context.first.should eq(melbourne)
      end
    end
  end

  describe "#group" do

    let(:group) do
      context.group
    end

    before do
      context.criteria = criteria.only(:number)
    end

    it "groups by the fields provided in the options" do
      group.size.should eq(4)
    end

    it "groups the first group properly" do
      group[1].should eq([ london ])
    end

    it "groups the second group properly" do
      group[10].should eq([ shanghai ])
    end

    it "groups the third group properly" do
      group[20].should eq([ melbourne, new_york ])
    end
  end

  describe ".initialize" do

    let(:selector) do
      { :field => "value"  }
    end

    let(:options) do
      { :skip => 20 }
    end

    let(:documents) do
      [ stub ]
    end

    let(:crit) do
      criteria.where(selector).skip(20)
    end

    let(:context) do
      described_class.new(crit)
    end

    before do
      crit.documents = documents
    end

    it "sets the selector" do
      context.selector.should eq(selector)
    end

    it "sets the options" do
      context.options.should eq(options)
    end

    it "sets the documents" do
      context.documents.should eq(documents)
    end
  end

  describe "#iterate" do

    let(:crit) do
      criteria.where(:street => "Bourke Street")
    end

    let(:context) do
      described_class.new(crit)
    end

    let(:iterated) do
      []
    end

    before do
      context.iterate do |doc|
        iterated << doc
      end
    end

    it "executes the criteria" do
      iterated.should eq([ melbourne ])
    end
  end

  describe "#limit" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    it "returns the specified number of documents" do
      person.addresses.criteria.limit(5).size.should eq(5)
    end
  end

  describe "#last" do

    context "when the selector is present" do

      let(:crit) do
        criteria.where(:street => "Bourke Street")
      end

      let(:context) do
        described_class.new(crit)
      end

      it "returns the last matching in the enumerable" do
        context.last.should eq(melbourne)
      end
    end
  end

  describe "#max" do

    it "returns the max value for the supplied field" do
      context.max(:number).should eq(20)
    end
  end

  describe "#min" do

    it "returns the min value for the supplied field" do
      context.min(:number).should eq(0)
    end
  end

  describe "#one" do

    context "when the selector is present" do

      let(:crit) do
        criteria.where(:street => "Bourke Street")
      end

      let(:context) do
        described_class.new(crit)
      end

      it "returns the first matching in the enumerable" do
        context.one.should eq(melbourne)
      end
    end
  end

  describe "#order_by" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    context "ascending" do

      it "sorts by a simple key" do
        person.addresses.order_by(:number.asc).
          map(&:number).should eq((0..9).to_a)
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.asc, :number.asc).
          map(&:number).should eq([0, 3, 6, 9, 1, 2, 4, 5, 7, 8])
      end
    end

    context "descending" do

      it "sorts by a simple key" do
        person.addresses.order_by(:number.desc).
          map(&:number).should eq((0..9).to_a.reverse)
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.desc, :number.desc).
          map(&:number).should eq([0, 3, 6, 9, 1, 2, 4, 5, 7, 8].reverse)
      end
    end

    context "with ascending and descending" do

      it "sorts by ascending first" do
        person.addresses.order_by(:post_code.asc, :number.desc).
          map(&:number).should eq([9, 6, 3, 0, 8, 7, 5, 4, 2, 1])
      end

      it "sorts by descending first" do
        person.addresses.order_by(:post_code.desc, :number.asc).
          map(&:number).should eq([1, 2, 4, 5, 7, 8, 0, 3, 6, 9])
      end
    end
  end

  describe "#shift" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    let(:criteria) do
      person.addresses.criteria
    end

    it "returns the first element" do
      criteria.shift.number.should eq(0)
    end

    context "when shifting multiple times" do

      before do
        2.times { criteria.shift }
      end

      it "skips to the next value" do
        criteria.first.number.should eq(2)
      end
    end
  end

  describe "#skip" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    it "excludes the specified number of document" do
      person.addresses.criteria.skip(5).limit(10).
        map(&:number).should eq([5, 6, 7, 8, 9])
    end
  end

  describe "#sort" do

    context "with no sort options" do

      it "returns the documents as is" do
        context.send(:sort, docs).should eq(docs)
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
      context.sum(:number).should eq(51)
    end
  end
end
