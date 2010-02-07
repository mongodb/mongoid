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
end
