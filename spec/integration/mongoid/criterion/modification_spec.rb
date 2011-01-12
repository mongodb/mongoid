require "spec_helper"

describe Mongoid::Criteria do

  before do
    Person.delete_all
  end

  [ :update, :update_all ].each do |method|

    let!(:person) do
      Person.create(:title => "Sir", :ssn => "666-66-6666")
    end

    before do
      person.addresses << Address.new(:street => "Oranienstr")
    end

    describe "##{method}" do

      context "when updating the root document" do

        let(:from_db) do
          Person.first
        end

        before do
          Person.where(:title => "Sir").send(method, :title => "Madam")
        end

        it "updates all the matching documents" do
          from_db.title.should == "Madam"
        end
      end

      context "when updating an embedded document" do

        let(:from_db) do
          Person.first
        end

        before do
          Person.where(:title => "Sir").send(
            method,
            "addresses.0.city" => "Berlin"
          )
        end

        it "updates all the matching documents" do
          from_db.addresses.first.city.should == "Berlin"
        end
      end
    end
  end
end
