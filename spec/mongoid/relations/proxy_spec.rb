require "spec_helper"

describe Mongoid::Relations::Proxy do

  describe ".eager_load_ids" do

    context "when relation macro has_one" do

      context "when no childs" do

        let(:klass) do
          Person
        end

        let(:ids) do
          [1, 2, 3]
        end

        let(:metadata) do
          klass.relations["account"]
        end

        before do
          Mongoid::Relations::Proxy.eager_load_ids(metadata, ids) do |doc, key|
            Mongoid::IdentityMap.set_one(doc, key)
          end
        end

        it "sets nil values in identity map" do
          Mongoid::IdentityMap[metadata.klass.collection_name].values.all?(&:nil?).should be_true
        end
      end

      context "when some childs" do

        let!(:person) { klass.create! }

        let(:klass) do
          Person
        end

        let(:ids) do
          [1, person.id.to_s]
        end

        let(:metadata) do
          klass.relations["account"]
        end

        before do
          person.create_account(name: :private)

          Mongoid::Relations::Proxy.eager_load_ids(metadata, ids) do |doc, key|
            Mongoid::IdentityMap.set_one(doc, key)
          end
        end

        it "sets nil value in identity map" do
          Mongoid::IdentityMap[metadata.klass.collection_name].values.one?(&:nil?).should be_true
        end

        it "sets document value in identity map" do
          Mongoid::IdentityMap[metadata.klass.collection_name].values.all?(&:nil?).should be_false
        end
      end
    end

    context "when relation macro not has_one" do

      context "when no childs" do

        let(:klass) do
          Person
        end

        let(:ids) do
          [1, 2, 3]
        end

        let(:metadata) do
          klass.relations["drugs"]
        end

        before do
          Mongoid::Relations::Proxy.eager_load_ids(metadata, ids) do |doc, key|
            Mongoid::IdentityMap.set_one(doc, key)
          end
        end

        it "sets no nil values in identity map" do
          Mongoid::IdentityMap[metadata.klass.collection_name].values.none?(&:nil?).should be_true
        end
      end
    end
  end

  describe "#extend" do

    before(:all) do
      module Testable
      end
    end

    after(:all) do
      Object.send(:remove_const, :Testable)
    end

    let(:person) do
      Person.create
    end

    let(:name) do
      person.build_name
    end

    before do
      name.namable.extend(Testable)
    end

    it "extends the proxied object" do
      person.should be_a(Testable)
    end

    context "when extending from the relation definition" do

      let!(:address) do
        person.addresses.create(street: "hobrecht")
      end

      let(:found) do
        person.addresses.find_by_street("hobrecht")
      end

      it "extends the proxy" do
        found.should eq(address)
      end
    end
  end
end
