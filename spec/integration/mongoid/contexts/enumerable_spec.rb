require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  let(:person) do
    person = Person.new(:title => "Sir")
    10.times do |n|
      post_code = n % 3 == 0 ? 32250 : 60661
      person.addresses << Address.new(:number => n, :post_code => post_code, :street => "Upper Street #{n}")
    end
    person
  end

  describe "#limit" do

    it "returns the specified number of documents" do
      person.addresses.criteria.limit(5).size.should == 5
    end

  end

  describe "#paginate" do

    it "paginates the embedded documents" do
      addresses = person.addresses.paginate(:page => nil, :per_page => 5)
      addresses.current_page.should == 1
      addresses.size.should == 5
    end

  end

  describe "#order_by" do

    context "ascending" do
      it "sorts by a simple key" do
        person.addresses.order_by(:number.asc).
          map(&:number).should == (0..9).to_a
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.asc, :number.asc).
          map(&:number).should == [0, 3, 6, 9, 1, 2, 4, 5, 7, 8]
      end
    end

    context "descending" do
      it "sorts by a simple key" do
        person.addresses.order_by(:number.desc).
          map(&:number).should == (0..9).to_a.reverse
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.desc, :number.desc).
          map(&:number).should == [0, 3, 6, 9, 1, 2, 4, 5, 7, 8].reverse
      end
    end

    context "with ascending and descending" do
      it "sorts by ascending first" do
        person.addresses.order_by(:post_code.asc, :number.desc).
          map(&:number).should == [9, 6, 3, 0, 8, 7, 5, 4, 2, 1]
      end

      it "sorts by descending first" do
        person.addresses.order_by(:post_code.desc, :number.asc).
          map(&:number).should == [1, 2, 4, 5, 7, 8, 0, 3, 6, 9]
      end
    end

  end

  describe "#shift" do
    it "returns the first element" do
      person.addresses.criteria.shift.number.should == 0
    end

    it "skips to the next value" do
      criteria = person.addresses.criteria
      criteria.shift
      criteria.shift
      criteria.first.number.should == 2
    end
  end

  describe "#skip" do

    it "excludes the specified number of document" do
      person.addresses.criteria.skip(5).limit(10).
        map(&:number).should == [5, 6, 7, 8, 9]
    end

  end

end
