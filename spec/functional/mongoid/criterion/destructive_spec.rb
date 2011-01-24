require "spec_helper"

describe Mongoid::Criteria do

  let(:name) do
    Name.new(:first_name => "Durran")
  end

  let(:address) do
    Address.new(:street => "Forsterstr")
  end

  before do
    Person.delete_all
    Person.create(:title => "Madam")

    2.times do |n|
      Person.create(
        :title => "Sir",
        :ssn => "666-66-666#{n}",
        :name => name,
        :addresses => [ address ]
      )
    end
  end

  [ :delete, :delete_all, :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      context "when removing root documents" do

        let(:criteria) do
          Person.where(:title => "Sir").and(:age.gt => 5)
        end

        let!(:removed) do
          criteria.send(method)
        end

        it "deletes the removes the documents from the database" do
          Person.count.should == 1
        end

        it "returns the number removed" do
          removed.should == 2
        end
      end

      context "when removing embedded documents" do

        let(:person) do
          Person.where(:title => "Sir").first
        end

        let(:criteria) do
          person.addresses.where(:street => "Forsterstr")
        end

        let!(:removed) do
          criteria.send(method)
        end

        it "deletes the removes the documents from the database" do
          person.addresses.count.should == 0
        end

        it "returns the number removed" do
          removed.should == 1
        end
      end
    end
  end
end
