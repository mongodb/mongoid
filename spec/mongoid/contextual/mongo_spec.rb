require "spec_helper"

describe Mongoid::Contextual::Mongo do

  [ :blank?, :empty? ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
      end

      context "when the count is zero" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns true" do
          context.send(method).should be_true
        end
      end

      context "when the count is greater than zero" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns false" do
          context.send(method).should be_false
        end
      end
    end
  end

  [ :count, :length, :size ].each do |method|

    describe "##{method}" do

      before do
        Band.create(name: "Depeche Mode")
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the number of documents that match" do
        context.send(method).should eq(1)
      end
    end
  end

  [ :delete, :delete_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:deleted) do
          context.send(method)
        end

        it "deletes the matching documents" do
          Band.find(new_order.id).should eq(new_order)
        end

        it "deletes the correct number of documents" do
          Band.count.should eq(1)
        end

        it "returns the number of documents deleted" do
          deleted.should eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "deletes all the documents" do
          Band.count.should eq(0)
        end
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      context "when the selector is contraining" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:destroyed) do
          context.send(method)
        end

        it "destroys the matching documents" do
          Band.find(new_order.id).should eq(new_order)
        end

        it "destroys the correct number of documents" do
          Band.count.should eq(1)
        end

        it "returns the number of documents destroyed" do
          destroyed.should eq(1)
        end
      end

      context "when the selector is not contraining" do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end

        before do
          context.send(method)
        end

        it "destroys all the documents" do
          Band.count.should eq(0)
        end
      end
    end
  end

  describe "#distinct" do

    before do
      Band.create(name: "Depeche Mode")
      Band.create(name: "New Order")
    end

    context "when limiting the result set" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct matching fields" do
        context.distinct(:name).should eq([ "Depeche Mode" ])
      end
    end

    context "when not limiting the result set" do

      let(:criteria) do
        Band.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        context.distinct(:name).should eq([ "Depeche Mode", "New Order" ])
      end
    end
  end

  describe "#each" do

    before do
      Band.create(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a block" do

      it "yields mongoid documents to the block" do
        context.each do |doc|
          doc.should be_a(Mongoid::Document)
        end
      end

      it "iterates over the matching documents" do
        context.each do |doc|
          doc.name.should eq("Depeche Mode")
        end
      end
    end

    context "when no block is provided" do

      let(:enum) do
        context.each
      end

      it "returns an enumerator" do
        enum.should be_a(Enumerator)
      end

      context "when iterating over the enumerator" do

        context "when iterating with each" do

          it "yields mongoid documents to the block" do
            enum.each do |doc|
              doc.should be_a(Mongoid::Document)
            end
          end
        end

        context "when iterating with next" do

          it "yields mongoid documents" do
            enum.next.should be_a(Mongoid::Document)
          end
        end
      end
    end
  end

  describe "#exists?" do

    before do
      Band.create(name: "Depeche Mode")
    end

    context "when the count is zero" do

      let(:criteria) do
        Band.where(name: "New Order")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        context.should_not be_exists
      end
    end

    context "when the count is greater than zero" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns true" do
        context.should be_exists
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the first matching document" do
        context.send(method).should eq(depeche_mode)
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sets the criteria" do
      context.criteria.should eq(criteria)
    end

    it "sets the klass" do
      context.klass.should eq(Band)
    end

    it "sets the query" do
      context.query.should be_a(Moped::Query)
    end

    it "sets the query selector" do
      context.query.selector.should eq({ "name" => "Depeche Mode" })
    end
  end

  describe "#last" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "returns the last matching document" do
      context.last.should eq(new_order)
    end
  end

  describe "#limit" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      context.limit(1).entries.should eq([ depeche_mode ])
    end
  end

  describe "#skip" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      context.skip(1).entries.should eq([ new_order ])
    end
  end

  describe "#sort" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sorts the results" do
      context.sort(name: -1).entries.should eq([ new_order, depeche_mode ])
    end

    it "returns the context" do
      context.sort(name: 1).should eq(context)
    end
  end

  [ :update, :update_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create(name: "New Order")
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when providing attributes" do

        before do
          context.send(method, name: "Smiths")
        end

        it "updates the first matching document" do
          depeche_mode.reload.name.should eq("Smiths")
        end

        it "updates the last matching document" do
          new_order.reload.name.should eq("Smiths")
        end
      end

      context "when providing no attributes" do

        it "returns false" do
          context.send(method).should be_false
        end
      end
    end
  end
end
