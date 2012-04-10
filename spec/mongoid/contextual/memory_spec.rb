require "spec_helper"

describe Mongoid::Contextual::Memory do

  [ :blank?, :empty? ].each do |method|

    describe "##{method}" do

      let(:hobrecht) do
        Address.new(street: "hobrecht")
      end

      let(:friedel) do
        Address.new(street: "friedel")
      end

      context "when there are matching documents" do

        let(:criteria) do
          Address.where(street: "hobrecht").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns false" do
          context.send(method).should be_false
        end
      end

      context "when there are no matching documents" do

        let(:criteria) do
          Address.where(street: "pfluger").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns true" do
          context.send(method).should be_true
        end
      end
    end
  end

  describe "#count" do

    let!(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let!(:friedel) do
      Address.new(street: "friedel")
    end

    let(:criteria) do
      Address.where(street: "hobrecht").tap do |crit|
        crit.documents = [ hobrecht, friedel ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "context when no arguments are provided" do

      it "returns the number of matches" do
        context.count.should eq(1)
      end
    end

    context "when provided a document" do

      context "when the document matches" do

        let(:count) do
          context.count(hobrecht)
        end

        it "returns 1" do
          count.should eq(1)
        end
      end

      context "when the document does not match" do

        let(:count) do
          context.count(friedel)
        end

        it "returns 0" do
          count.should eq(0)
        end
      end
    end

    context "when provided a block" do

      context "when the block evals 1 to true" do

        let(:count) do
          context.count do |doc|
            doc.street == "hobrecht"
          end
        end

        it "returns 1" do
          count.should eq(1)
        end
      end

      context "when the block evals none to true" do

        let(:count) do
          context.count do |doc|
            doc.street == "friedel"
          end
        end

        it "returns 0" do
          count.should eq(0)
        end
      end
    end
  end

  [ :delete, :delete_all ].each do |method|

    let(:person) do
      Person.create
    end

    let(:hobrecht) do
      person.addresses.create(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create(street: "pfluger")
    end

    let(:criteria) do
      Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    describe "##{method}" do

      let!(:deleted) do
        context.send(method)
      end

      it "deletes the first matching document" do
        hobrecht.should be_destroyed
      end

      it "deletes the last matching document" do
        friedel.should be_destroyed
      end

      it "does not delete non matching docs" do
        pfluger.should_not be_destroyed
      end

      it "removes the docs from the relation" do
        person.addresses.should eq([ pfluger ])
      end

      it "removes the docs from the context" do
        context.entries.should be_empty
      end

      it "persists the changes to the database" do
        person.reload.addresses.should eq([ pfluger ])
      end

      it "returns the number of deleted documents" do
        deleted.should eq(2)
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    let(:person) do
      Person.create
    end

    let(:hobrecht) do
      person.addresses.create(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create(street: "pfluger")
    end

    let(:criteria) do
      Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    describe "##{method}" do

      let!(:destroyed) do
        context.send(method)
      end

      it "deletes the first matching document" do
        hobrecht.should be_destroyed
      end

      it "deletes the last matching document" do
        friedel.should be_destroyed
      end

      it "does not delete non matching docs" do
        pfluger.should_not be_destroyed
      end

      it "removes the docs from the relation" do
        person.addresses.should eq([ pfluger ])
      end

      it "removes the docs from the context" do
        context.entries.should be_empty
      end

      it "persists the changes to the database" do
        person.reload.addresses.should eq([ pfluger ])
      end

      it "returns the number of destroyed documents" do
        destroyed.should eq(2)
      end
    end
  end

  describe "#distinct" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    context "when limiting the result set" do

      let(:criteria) do
        Address.where(street: "hobrecht").tap do |crit|
          crit.documents = [ hobrecht, hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        context.distinct(:street).should eq([ "hobrecht" ])
      end
    end

    context "when not limiting the result set" do

      let(:criteria) do
        Address.all.tap do |crit|
          crit.documents = [ hobrecht, friedel, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the distinct field values" do
        context.distinct(:street).should eq([ "hobrecht", "friedel" ])
      end
    end
  end

  describe "#each" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:criteria) do
      Address.where(street: "hobrecht").tap do |crit|
        crit.documents = [ hobrecht, friedel ]
      end
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
          doc.should eq(hobrecht)
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

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    context "when there are matching documents" do

      let(:criteria) do
        Address.where(street: "hobrecht").tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns true" do
        context.should be_exists
      end
    end

    context "when there are no matching documents" do

      let(:criteria) do
        Address.where(street: "pfluger").tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        context.should_not be_exists
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let(:hobrecht) do
        Address.new(street: "hobrecht")
      end

      let(:friedel) do
        Address.new(street: "friedel")
      end

      let(:criteria) do
        Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the first matching document" do
        context.send(method).should eq(hobrecht)
      end
    end
  end

  describe "#initialize" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:criteria) do
      Address.where(street: "hobrecht").tap do |crit|
        crit.documents = [ hobrecht, friedel ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sets the criteria" do
      context.criteria.should eq(criteria)
    end

    it "sets the klass" do
      context.klass.should eq(Address)
    end

    it "sets the matching documents" do
      context.documents.should eq([ hobrecht ])
    end
  end

  describe "#last" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:criteria) do
      Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
        crit.documents = [ hobrecht, friedel ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "returns the last matching document" do
      context.last.should eq(friedel)
    end
  end

  [ :length, :size ].each do |method|

    describe "##{method}" do

      let(:hobrecht) do
        Address.new(street: "hobrecht")
      end

      let(:friedel) do
        Address.new(street: "friedel")
      end

      context "when there are matching documents" do

        let(:criteria) do
          Address.where(street: "hobrecht").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the number of matches" do
          context.send(method).should eq(1)
        end
      end

      context "when there are no matching documents" do

        let(:criteria) do
          Address.where(street: "pfluger").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns zero" do
          context.send(method).should eq(0)
        end
      end
    end
  end

  describe "#limit" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:pfluger) do
      Address.new(street: "pfluger")
    end

    let(:criteria) do
      Address.all.tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    let!(:limit) do
      context.limit(2)
    end

    it "returns the context" do
      limit.should eq(context)
    end

    context "when asking for all documents" do

      context "when only a limit exists" do

        it "only returns the limited documents" do
          context.entries.should eq([ hobrecht, friedel ])
        end
      end

      context "when a skip and limit exist" do

        before do
          limit.skip(1)
        end

        it "applies the skip before the limit" do
          context.entries.should eq([ friedel, pfluger ])
        end
      end
    end
  end

  describe "#skip" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:pfluger) do
      Address.new(street: "pfluger")
    end

    let(:criteria) do
      Address.all.tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    let!(:skip) do
      context.skip(1)
    end

    it "returns the context" do
      skip.should eq(context)
    end

    context "when asking for all documents" do

      context "when only a skip exists" do

        it "skips the correct number" do
          context.entries.should eq([ friedel, pfluger ])
        end
      end

      context "when a skip and limit exist" do

        before do
          skip.limit(1)
        end

        it "applies the skip before the limit" do
          context.entries.should eq([ friedel ])
        end
      end
    end
  end

  describe "#sort" do

    let(:hobrecht) do
      Address.new(street: "hobrecht", number: 9)
    end

    let(:friedel) do
      Address.new(street: "friedel", number: 1)
    end

    let(:pfluger) do
      Address.new(street: "pfluger", number: 5)
    end

    let(:criteria) do
      Address.all.tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a single field sort" do

      context "when the sort is ascending" do

        let!(:sorted) do
          context.sort(street: 1)
        end

        it "sorts the documents" do
          context.entries.should eq([ friedel, hobrecht, pfluger ])
        end

        it "returns the context" do
          sorted.should eq(context)
        end
      end

      context "when the sort is descending" do

        let!(:sorted) do
          context.sort(street: -1)
        end

        it "sorts the documents" do
          context.entries.should eq([ pfluger, hobrecht, friedel ])
        end

        it "returns the context" do
          sorted.should eq(context)
        end
      end
    end

    context "when providing multiple sort fields" do

      context "when the sort is ascending" do

        let!(:sorted) do
          context.sort(number: 1, street: 1)
        end

        it "sorts the documents" do
          context.entries.should eq([ friedel, hobrecht, pfluger ])
        end

        it "returns the context" do
          sorted.should eq(context)
        end
      end

      context "when the sort is descending" do

        let!(:sorted) do
          context.sort(number: -1, street: -1)
        end

        it "sorts the documents" do
          context.entries.should eq([ pfluger, hobrecht, friedel ])
        end

        it "returns the context" do
          sorted.should eq(context)
        end
      end
    end

    context "when the field is nil" do

      let!(:sorted) do
        context.sort(state: 1)
      end

      it "does not sort the documents" do
        context.entries.should eq([ hobrecht, friedel, pfluger ])
      end

      it "returns the context" do
        sorted.should eq(context)
      end
    end

    pending "with localized field" do

    end
  end

  [ :update, :update_all ].each do |method|

    let(:person) do
      Person.create
    end

    let(:hobrecht) do
      person.addresses.create(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create(street: "pfluger")
    end

    let(:criteria) do
      Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
        crit.documents = [ hobrecht, friedel, pfluger ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    describe "##{method}" do

      context "when attributes are provided" do

        before do
          context.send(method, number: 5)
        end

        it "updates the first matching document" do
          hobrecht.number.should eq(5)
        end

        it "updates the last matching document" do
          friedel.number.should eq(5)
        end

        it "does not update non matching docs" do
          pfluger.number.should be_nil
        end

        context "when reloading the embedded documents" do

          it "updates the first matching document" do
            hobrecht.reload.number.should eq(5)
          end

          it "updates the last matching document" do
            friedel.reload.number.should eq(5)
          end

          it "does not update non matching docs" do
            pfluger.reload.number.should be_nil
          end
        end
      end

      context "when no attributes are provided" do

        it "returns false" do
          context.send(method).should be_false
        end
      end
    end
  end
end
