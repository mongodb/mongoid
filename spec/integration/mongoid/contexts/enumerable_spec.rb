require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before do
    @person = Person.new(:title => "Sir")
    10.times do |n|
      @person.addresses << Address.new(:number => n, :street => "Upper Street")
    end
  end

  describe "#paginate" do

    it "paginates the embedded documents" do
      addresses = @person.addresses.paginate(:page => nil, :per_page => 5)
      addresses.current_page.should == 1
      addresses.size.should == 5
    end
  end

  describe "limit and skip" do

    it "limits" do
      @person.addresses.criteria.limit(5).size.should == 5
    end

    it "skips" do
      @person.addresses.criteria.skip(5).limit(10).
        map(&:number).should == [5, 6, 7, 8, 9]
    end

  end
end
