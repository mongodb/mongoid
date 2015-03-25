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
          expect(context.send(method)).to be false
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
          expect(context.send(method)).to be true
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
        expect(context.count).to eq(1)
      end
    end

    context "when provided a document" do

      context "when the document matches" do

        let(:count) do
          context.count(hobrecht)
        end

        it "returns 1" do
          expect(count).to eq(1)
        end
      end

      context "when the document does not match" do

        let(:count) do
          context.count(friedel)
        end

        it "returns 0" do
          expect(count).to eq(0)
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
          expect(count).to eq(1)
        end
      end

      context "when the block evals none to true" do

        let(:count) do
          context.count do |doc|
            doc.street == "friedel"
          end
        end

        it "returns 0" do
          expect(count).to eq(0)
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

    describe "##{method}" do

      context "when embedded a single level" do

        let(:criteria) do
          Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
            crit.documents = [ hobrecht, friedel, pfluger ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:deleted) do
          context.send(method)
        end

        it "deletes the first matching document" do
          expect(hobrecht).to be_destroyed
        end

        it "deletes the last matching document" do
          expect(friedel).to be_destroyed
        end

        it "does not delete non matching docs" do
          expect(pfluger).to_not be_destroyed
        end

        it "removes the docs from the relation" do
          expect(person.addresses).to eq([ pfluger ])
        end

        it "removes the docs from the context" do
          expect(context.entries).to be_empty
        end

        it "persists the changes to the database" do
          expect(person.reload.addresses).to eq([ pfluger ])
        end

        it "returns the number of deleted documents" do
          expect(deleted).to eq(2)
        end
      end

      context "when embedded multiple levels" do

        let!(:home) do
          hobrecht.locations.create(name: "home")
        end

        let!(:work) do
          hobrecht.locations.create(name: "work")
        end

        let(:criteria) do
          Location.where(name: "work").tap do |crit|
            crit.documents = [ home, work ]
          end
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:deleted) do
          context.send(method)
        end

        it "deletes the first matching document" do
          expect(work).to be_destroyed
        end

        it "does not delete non matching docs" do
          expect(home).to_not be_destroyed
        end

        it "removes the docs from the relation" do
          expect(person.addresses.first.locations).to eq([ home ])
        end

        it "removes the docs from the context" do
          expect(context.entries).to be_empty
        end

        it "persists the changes to the database" do
          expect(person.reload.addresses.first.locations).to eq([ home ])
        end

        it "returns the number of deleted documents" do
          expect(deleted).to eq(1)
        end
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
        expect(hobrecht).to be_destroyed
      end

      it "deletes the last matching document" do
        expect(friedel).to be_destroyed
      end

      it "does not delete non matching docs" do
        expect(pfluger).to_not be_destroyed
      end

      it "removes the docs from the relation" do
        expect(person.addresses).to eq([ pfluger ])
      end

      it "removes the docs from the context" do
        expect(context.entries).to be_empty
      end

      it "persists the changes to the database" do
        expect(person.reload.addresses).to eq([ pfluger ])
      end

      it "returns the number of destroyed documents" do
        expect(destroyed).to eq(2)
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
        expect(context.distinct(:street)).to eq([ "hobrecht" ])
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
        expect(context.distinct(:street)).to eq([ "hobrecht", "friedel" ])
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

    context "when skip and limit outside of range" do

      before do
        context.skip(10).limit(2)
      end

      it "contains no documents" do
        expect(context.map(&:street)).to be_empty
      end

      context "when calling next on the enumerator" do

        it "raises a stop iteration error" do
          expect {
            context.each.next
          }.to raise_error(StopIteration)
        end
      end
    end

    context "when providing a block" do

      it "yields mongoid documents to the block" do
        context.each do |doc|
          expect(doc).to be_a(Mongoid::Document)
        end
      end

      it "iterates over the matching documents" do
        context.each do |doc|
          expect(doc).to eq(hobrecht)
        end
      end
    end

    context "when no block is provided" do

      let(:enum) do
        context.each
      end

      it "returns an enumerator" do
        expect(enum).to be_a(Enumerator)
      end

      context "when iterating over the enumerator" do

        context "when iterating with each" do

          it "yields mongoid documents to the block" do
            enum.each do |doc|
              expect(doc).to be_a(Mongoid::Document)
            end
          end
        end

        context "when iterating with next" do

          it "yields mongoid documents" do
            expect(enum.next).to be_a(Mongoid::Document)
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
        expect(context).to be_exists
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
        expect(context).to_not be_exists
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
        expect(context.send(method)).to eq(hobrecht)
      end
    end
  end

  describe "#initialize" do

    context "when the criteria has no options" do

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
        expect(context.criteria).to eq(criteria)
      end

      it "sets the klass" do
        expect(context.klass).to eq(Address)
      end

      it "sets the matching documents" do
        expect(context.documents).to eq([ hobrecht ])
      end
    end

    context "when the criteria skips" do

      let(:hobrecht) do
        Address.new(street: "hobrecht")
      end

      let(:friedel) do
        Address.new(street: "friedel")
      end

      let(:criteria) do
        Address.all.skip(1).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "limits the matching documents" do
        expect(context).to eq([ friedel ])
      end
    end

    context "when the criteria limits" do

      let(:hobrecht) do
        Address.new(street: "hobrecht")
      end

      let(:friedel) do
        Address.new(street: "friedel")
      end

      let(:criteria) do
        Address.all.limit(1).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "limits the matching documents" do
        expect(context).to eq([ hobrecht ])
      end
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
      expect(context.last).to eq(friedel)
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
          expect(context.send(method)).to eq(1)
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
          expect(context.send(method)).to eq(0)
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
      expect(limit).to eq(context)
    end

    context "when asking for all documents" do

      context "when only a limit exists" do

        it "only returns the limited documents" do
          expect(context.entries).to eq([ hobrecht, friedel ])
        end
      end

      context "when a skip and limit exist" do

        before do
          limit.skip(1)
        end

        it "applies the skip before the limit" do
          expect(context.entries).to eq([ friedel, pfluger ])
        end
      end
    end
  end

  describe "#pluck" do

    let(:hobrecht) do
      Address.new(street: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel")
    end

    let(:criteria) do
      Address.all.tap do |crit|
        crit.documents = [ hobrecht, friedel ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when plucking" do

      let!(:plucked) do
        context.pluck(:street)
      end

      it "returns the values" do
        expect(plucked).to eq([ "hobrecht", "friedel" ])
      end
    end

    context "when plucking a field that doesnt exist" do

      context "when pluck one field" do

        let(:plucked) do
          context.pluck(:foo)
        end

        it "returns a empty array" do
          expect(plucked).to eq([])
        end
      end

      context "when pluck multiple fields" do

        let(:plucked) do
          context.pluck(:foo, :bar)
        end

        it "returns a empty array" do
          expect(plucked).to eq([[], []])
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
      expect(skip).to eq(context)
    end

    context "when asking for all documents" do

      context "when only a skip exists" do

        it "skips the correct number" do
          expect(context.entries).to eq([ friedel, pfluger ])
        end
      end

      context "when a skip and limit exist" do

        before do
          skip.limit(1)
        end

        it "applies the skip before the limit" do
          expect(context.entries).to eq([ friedel ])
        end
      end
    end
  end

  describe "#sort" do

    let(:hobrecht) do
      Address.new(street: "hobrecht", number: 9, name: "hobrecht")
    end

    let(:friedel) do
      Address.new(street: "friedel", number: 1, name: "friedel")
    end

    let(:pfluger) do
      Address.new(street: "pfluger", number: 5, name: "pfluger")
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
          expect(context.entries).to eq([ friedel, hobrecht, pfluger ])
        end

        it "returns the context" do
          expect(sorted).to eq(context)
        end
      end

      context "when the sort is descending" do

        context "when sorting on a string" do

          let!(:sorted) do
            context.sort(street: -1)
          end

          it "sorts the documents" do
            expect(context.entries).to eq([ pfluger, hobrecht, friedel ])
          end

          it "returns the context" do
            expect(sorted).to eq(context)
          end
        end

        context "when sorting on a time" do

          before do
            pfluger.move_in = 30.days.ago
            hobrecht.move_in = 25.days.ago
          end

          let!(:sorted) do
            context.sort(move_in: -1)
          end

          it "sorts the documents" do
            expect(context.entries).to eq([ friedel, hobrecht, pfluger ])
          end

          it "returns the context" do
            expect(sorted).to eq(context)
          end
        end
      end
    end

    context "when providing multiple sort fields" do

      let(:lenau) do
        Address.new(street: "lenau", number: 5, name: "lenau")
      end

      let(:kampuchea_krom) do
        Address.new(street: "kampuchea krom", number: 5, name: "kampuchea krom")
      end

      before do
        criteria.documents.unshift(lenau)
        criteria.documents.unshift(kampuchea_krom)
      end

      context "when the sort is ascending" do

        let!(:sorted) do
          context.sort(number: 1, street: 1)
        end

        it "sorts the documents" do
          expect(context.entries).to eq([ friedel, kampuchea_krom, lenau, pfluger, hobrecht ])
        end

        it "returns the context" do
          expect(sorted).to eq(context)
        end
      end

      context "when the sort is descending" do

        let!(:sorted) do
          context.sort(number: -1, street: -1)
        end

        it "sorts the documents" do
          expect(context.entries).to eq([ hobrecht, pfluger, lenau, kampuchea_krom, friedel ])
        end

        it "returns the context" do
          expect(sorted).to eq(context)
        end
      end
    end

    context "when the field is nil" do

      let!(:sorted) do
        context.sort(state: 1)
      end

      it "does not sort the documents" do
        expect(context.entries).to eq([ hobrecht, friedel, pfluger ])
      end

      it "returns the context" do
        expect(sorted).to eq(context)
      end
    end

    context "with localized field" do

      let!(:sorted) do
        context.sort("name.en" => 1)
      end

      it "sorts the documents" do
        expect(context.entries).to eq([ friedel, hobrecht, pfluger ])
      end
    end
  end

  describe "#update" do

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

    context "when the documents are embedded one level" do

      let(:criteria) do
        Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel, pfluger ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when attributes are provided" do

        before do
          context.update(number: 5)
        end

        it "updates the first matching document" do
          expect(hobrecht.number).to eq(5)
        end

        it "does not update the last matching document" do
          expect(friedel.number).to be_nil
        end

        it "does not update non matching docs" do
          expect(pfluger.number).to be_nil
        end

        context "when reloading the embedded documents" do

          it "updates the first matching document" do
            expect(hobrecht.reload.number).to eq(5)
          end

          it "updates the last matching document" do
            expect(friedel.reload.number).to be_nil
          end

          it "does not update non matching docs" do
            expect(pfluger.reload.number).to be_nil
          end
        end
      end

      context "when no attributes are provided" do

        it "returns false" do
          expect(context.update).to be false
        end
      end
    end

    context "when the documents are embedded multiple levels" do

      let!(:home) do
        hobrecht.locations.create(name: "home")
      end

      let!(:work) do
        hobrecht.locations.create(name: "work")
      end

      let(:criteria) do
        Location.where(name: "work").tap do |crit|
          crit.documents = [ home, work ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when attributes are provided" do

        before do
          context.update(number: 5)
        end

        it "updates the first matching document" do
          expect(work.number).to eq(5)
        end

        it "does not update non matching docs" do
          expect(home.number).to be_nil
        end

        context "when reloading the embedded documents" do

          it "updates the first matching document" do
            expect(work.reload.number).to eq(5)
          end

          it "does not update non matching docs" do
            expect(home.reload.number).to be_nil
          end
        end
      end

      context "when no attributes are provided" do

        it "returns false" do
          expect(context.update).to be false
        end
      end
    end
  end

  describe "#update_all" do

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

    context "when the documents are empty" do

      let(:person_two) do
        Person.create
      end

      let(:criteria) do
        Address.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns false" do
        expect(context.update_all({})).to be false
      end
    end

    context "when the documents are embedded one level" do

      let(:criteria) do
        Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel, pfluger ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when providing aliased fields" do

        before do
          context.update_all(suite: "10B")
        end

        it "updates the first matching document" do
          expect(hobrecht.suite).to eq("10B")
        end

        it "updates the last matching document" do
          expect(friedel.suite).to eq("10B")
        end

        it "does not update non matching docs" do
          expect(pfluger.suite).to be_nil
        end
      end

      context "when attributes are provided" do

        before do
          context.update_all(number: 5)
        end

        it "updates the first matching document" do
          expect(hobrecht.number).to eq(5)
        end

        it "updates the last matching document" do
          expect(friedel.number).to eq(5)
        end

        it "does not update non matching docs" do
          expect(pfluger.number).to be_nil
        end

        context "when reloading the embedded documents" do

          it "updates the first matching document" do
            expect(hobrecht.reload.number).to eq(5)
          end

          it "updates the last matching document" do
            expect(friedel.reload.number).to eq(5)
          end

          it "does not update non matching docs" do
            expect(pfluger.reload.number).to be_nil
          end
        end

        context "when updating the documents a second time" do

          before do
            context.update_all(number: 5)
          end

          it "does not error on the update" do
            expect(hobrecht.number).to eq(5)
          end
        end
      end

      context "when no attributes are provided" do

        it "returns false" do
          expect(context.update_all).to be false
        end
      end
    end

    context "when the documents are embedded multiple levels" do

      let!(:home) do
        hobrecht.locations.create(name: "home")
      end

      let!(:work) do
        hobrecht.locations.create(name: "work")
      end

      let(:criteria) do
        Location.where(name: "work").tap do |crit|
          crit.documents = [ home, work ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when attributes are provided" do

        before do
          context.update_all(number: 5)
        end

        it "updates the first matching document" do
          expect(work.number).to eq(5)
        end

        it "does not update non matching docs" do
          expect(home.number).to be_nil
        end

        context "when reloading the embedded documents" do

          it "updates the first matching document" do
            expect(work.reload.number).to eq(5)
          end

          it "does not update non matching docs" do
            expect(home.reload.number).to be_nil
          end
        end
      end

      context "when no attributes are provided" do

        it "returns false" do
          expect(context.update_all).to be false
        end
      end
    end
  end
end
