require "spec_helper"

describe Mongoid::Criteria do

  let(:name) do
    Name.new(first_name: "Durran")
  end

  let(:address_one) do
    Address.new(street: "Forsterstr")
  end

  let(:address_two) do
    Address.new(street: "Hobrechtstr")
  end

  before do
    Person.create(title: "Madam")
    2.times do |n|
      Person.create(
        title: "Sir",
        name: name,
        addresses: [ address_one, address_two ]
      )
    end
  end

  [ :delete, :delete_all, :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      context "when removing root documents" do

        let(:criteria) do
          Person.where(title: "Sir", :age.gt => 5)
        end

        let!(:removed) do
          criteria.send(method)
        end

        it "deletes the removes the documents from the database" do
          Person.count.should eq(1)
        end

        it "returns the number removed" do
          removed.should eq(2)
        end
      end

      context "when removing embedded documents" do

        context "when removing a single document" do

          let(:person) do
            Person.where(title: "Sir").first
          end

          let(:criteria) do
            person.addresses.where(street: "Forsterstr")
          end

          let!(:removed) do
            criteria.send(method)
          end

          it "deletes the removes the documents from the database" do
            person.addresses.count.should eq(1)
          end

          it "returns the number removed" do
            removed.should eq(1)
          end
        end

        context "when removing multiple documents" do

          let(:person) do
            Person.where(title: "Sir").first
          end

          let(:criteria) do
            person.addresses.where(city: nil)
          end

          let!(:removed) do
            criteria.send(method)
          end

          it "deletes the removes the documents from the database" do
            person.addresses.count.should eq(0)
          end

          it "returns the number removed" do
            removed.should eq(2)
          end
        end
      end
    end
  end
end
