# frozen_string_literal: true

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

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.where(street: "hobrecht").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.send(method)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(street: "hobrecht").tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.count
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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
      Person.create!
    end

    let(:hobrecht) do
      person.addresses.create!(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create!(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create!(street: "pfluger")
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
          hobrecht.locations.create!(name: "home")
        end

        let!(:work) do
          hobrecht.locations.create!(name: "work")
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

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
            crit.documents = [ hobrecht, friedel, pfluger ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.send(method)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
        end
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    let(:person) do
      Person.create!
    end

    let(:hobrecht) do
      person.addresses.create!(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create!(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create!(street: "pfluger")
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

      context 'when there is no collation on the criteria' do

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

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.any_in(street: [ "hobrecht", "friedel" ]).tap do |crit|
            crit.documents = [ hobrecht, friedel, pfluger ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.send(method)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
        end
      end
    end
  end

  describe "#distinct" do

    context "when legacy_pluck_distinct is true" do
      config_override :legacy_pluck_distinct, true

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

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.where(street: "hobrecht").tap do |crit|
            crit.documents = [ hobrecht, hobrecht, friedel ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.distinct(:street)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
        end
      end
    end

    context "when legacy_pluck_distinct is false" do
      config_override :legacy_pluck_distinct, false

      let(:depeche) { Band.create!(name: "Depeche Mode", years: 30, sales: "1E2") }
      let(:new_order) { Band.create!(name: "New Order", years: 25, sales: "2E3") }
      let(:maniacs) { Band.create!(name: "10,000 Maniacs", years: 20, sales: "1E2") }

      let(:criteria) do
        Band.all.tap do |crit|
          crit.documents = [ depeche, new_order, maniacs ]
        end
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when limiting the result set" do

        let(:criteria) do
          Band.where(name: "Depeche Mode").tap do |crit|
            crit.documents = [ depeche ]
          end
        end

        it "returns the distinct matching fields" do
          expect(context.distinct(:name)).to eq([ "Depeche Mode" ])
        end
      end

      context "when not limiting the result set" do

        it "returns the distinct field values" do
          expect(context.distinct(:name).sort).to eq([ "10,000 Maniacs", "Depeche Mode", "New Order" ].sort)
        end
      end

      context "when providing an aliased field" do

        it "returns the distinct field values" do
          expect(context.distinct(:years).sort).to eq([ 20, 25, 30 ])
        end
      end

      context "when providing a demongoizable field" do

        it "returns the non-demongoized distinct field values" do
          expect(context.distinct(:sales).sort).to eq([ BigDecimal("1E2"), BigDecimal("2E3") ])
        end
      end

      context "when getting a localized field" do
        before do
          I18n.locale = :en
          d = Dictionary.create!(description: 'english-text')
          I18n.locale = :de
          d.description = 'deutsch-text'
          d.save!
        end

        after do
          I18n.locale = :en
        end

        let(:criteria) do
          Dictionary.all.tap do |crit|
            crit.documents = [ Dictionary.first ]
          end
        end

        context "when getting the field without _translations" do
          it "gets the demongoized localized field" do
            expect(context.distinct(:description)).to eq([ 'deutsch-text' ])
          end
        end

        context "when getting the field with _translations" do

          it "gets the full hash" do
            expect(context.distinct(:description_translations)).to eq([ { "de" => "deutsch-text", "en" => "english-text" } ])
          end
        end

        context 'when plucking a specific locale' do

          let(:distinct) do
            context.distinct(:'description.de')
          end

          it 'returns the specific translation' do
            expect(distinct).to eq([ "deutsch-text" ])
          end
        end

        context 'when plucking a specific locale from _translations field' do

          let(:distinct) do
            context.distinct(:'description_translations.de')
          end

          it 'returns the specific translations' do
            expect(distinct).to eq(['deutsch-text'])
          end
        end

        context 'when fallbacks are enabled with a locale list' do
          require_fallbacks

          around(:all) do |example|
            prev_fallbacks = I18n.fallbacks.dup
            I18n.fallbacks[:he] = [ :en ]
            example.run
            I18n.fallbacks = prev_fallbacks
          end

          after do
            I18n.locale = :en
          end

          let(:distinct) do
            context.distinct(:description).first
          end

          it "correctly uses the fallback" do
            I18n.locale = :en
            d = Dictionary.create!(description: 'english-text')
            I18n.locale = :he
            distinct.should == "english-text"
          end
        end

        context "when the localized field is embedded" do
          let(:person) do
            p = Passport.new
            I18n.locale = :en
            p.name = "Neil"
            I18n.locale = :he
            p.name = "Nissim"

            Person.create!(passport: p, employer_id: 12345)
          end

          after do
            I18n.locale = :en
          end

          let(:criteria) do
            Person.where(employer_id: 12345).tap do |crit|
              crit.documents = [ person ]
            end
          end

          let(:distinct) do
            context.distinct("pass.name").first
          end

          let(:distinct_translations) do
            context.distinct("pass.name_translations").first
          end

          let(:distinct_translations_field) do
            context.distinct("pass.name_translations.en").first
          end

          it "returns the translation for the current locale" do
            expect(distinct).to eq("Nissim")
          end

          it "returns the full _translation hash" do
            expect(distinct_translations).to eq({ "en" => "Neil", "he" => "Nissim" })
          end

          it "returns the translation for the requested locale" do
            expect(distinct_translations_field).to eq("Neil")
          end
        end
      end

      context "when getting an embedded field" do

        let(:label) { Label.new(sales: "1E2") }
        let!(:band) { Band.create!(label: label) }
        let(:criteria) do
          Band.where(_id: band.id).tap do |crit|
            crit.documents = [ band ]
          end
        end

        it "returns the distinct matching fields" do
          expect(context.distinct("label.sales")).to eq([ BigDecimal("1E2") ])
        end
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(street: "hobrecht").tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.each
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(street: "pfluger").tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

      it "returns a list when passing a limit" do
        expect(context.send(method, 2)).to eq([ hobrecht, friedel ])
      end

      it "returns a list when passing 1" do
        expect(context.send(method, 1)).to eq([ hobrecht ])
      end

      it "returns the matching document when passing deprecated options" do
        expect(context.send(method, id_sort: :none)).to eq(hobrecht)
      end

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.send(method)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
        end
      end
    end
  end

  describe "#take" do

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
      expect(context.take).to eq(hobrecht)
    end

    it "returns an array when passing a limit" do
      expect(context.take(2)).to eq([ hobrecht, friedel ])
    end

    it "returns an array when passing a limit as 1" do
      expect(context.take(1)).to eq([ hobrecht ])
    end

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.take
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
    end
  end

  describe "#take!" do

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
      expect(context.take!).to eq(hobrecht)
    end

    context "when the criteria is empty" do
      let(:criteria) do
        Address.where(street: "bogus").tap do |crit|
          crit.documents = []
        end
      end

      it "raise an error" do
        expect do
          context.take!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Address./)
      end
    end

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.take
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.limit(1).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    it "returns a list when a limit is passed" do
      expect(context.last(2)).to eq([ hobrecht, friedel ])
    end

    it "returns a list when the limit is 1" do
      expect(context.last(1)).to eq([ friedel ])
    end

    it "returns the matching document when passing deprecated options" do
      expect(context.last(id_sort: :none)).to eq(friedel)
    end

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.where(:street.in => [ "hobrecht", "friedel" ]).tap do |crit|
          crit.documents = [ hobrecht, friedel ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.last
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
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

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.where(street: "hobrecht").tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.send(method)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    context 'when there is no collation on the criteria' do

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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.tap do |crit|
          crit.documents = [ hobrecht, friedel, pfluger ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.limit(2)
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
    end
  end

  describe "#pluck" do

    let(:context) do
      described_class.new(criteria)
    end

    context "when legacy_pluck_distinct is true" do
      config_override :legacy_pluck_distinct, true

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

      context "when plucking" do

        let!(:plucked) do
          context.pluck(:street)
        end

        it "returns the values" do
          expect(plucked).to eq([ "hobrecht", "friedel" ])
        end
      end

      context "when plucking a mix of empty and non-empty values" do

        let(:empty_doc) do
          Address.new(street: nil)
        end

        let(:criteria) do
          Address.all.tap do |crit|
            crit.documents = [ hobrecht, friedel, empty_doc ]
          end
        end

        let!(:plucked) do
          context.pluck(:street)
        end

        it "returns the values" do
          expect(plucked).to eq([ "hobrecht", "friedel", nil ])
        end
      end

      context "when plucking a field that doesnt exist" do

        context "when pluck one field" do

          let(:plucked) do
            context.pluck(:foo)
          end

          it "returns a empty array" do
            expect(plucked).to eq([nil, nil])
          end
        end

        context "when pluck multiple fields" do

          let(:plucked) do
            context.pluck(:foo, :bar)
          end

          it "returns a empty array" do
            expect(plucked).to eq([[nil, nil], [nil, nil]])
          end
        end
      end

      context 'when there is a collation on the criteria' do

        let(:criteria) do
          Address.all.tap do |crit|
            crit.documents = [ hobrecht, friedel ]
          end.collation(locale: 'en_US', strength: 2)
        end

        it "raises an exception" do
          expect {
            context.pluck(:foo, :bar)
          }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
        end
      end
    end

    context "when legacy_pluck_distinct is false" do
      config_override :legacy_pluck_distinct, false

      let!(:depeche) do
        Band.create!(name: "Depeche Mode", likes: 3)
      end

      let!(:tool) do
        Band.create!(name: "Tool", likes: 3)
      end

      let!(:photek) do
        Band.create!(name: "Photek", likes: 1)
      end

      let(:maniacs) do
        Band.create!(name: "10,000 Maniacs", likes: 1, sales: "1E2")
      end

      let(:criteria) do
        Band.all.tap do |crit|
          crit.documents = [ depeche, tool, photek, maniacs ]
        end
      end

      context "when the field is aliased" do

        let!(:expensive) do
          Product.create!(price: 100000)
        end

        let!(:cheap) do
          Product.create!(price: 1)
        end

        let(:criteria) do
          Product.all.tap do |crit|
            crit.documents = [ expensive, cheap ]
          end
        end

        context "when using alias_attribute" do

          let(:plucked) do
            context.pluck(:price)
          end

          it "uses the aliases" do
            expect(plucked).to eq([ 100000, 1 ])
          end
        end
      end

      context "when the criteria matches" do

        context "when there are no duplicate values" do

          let!(:plucked) do
            context.pluck(:name)
          end

          it "returns the values" do
            expect(plucked).to contain_exactly("10,000 Maniacs", "Depeche Mode", "Tool", "Photek")
          end

          context "when subsequently executing the criteria without a pluck" do

            it "does not limit the fields" do
              expect(context.first.likes).to eq(3)
            end
          end

          context 'when the field is a subdocument' do

            context 'when a top-level field and a subdocument field are plucked' do
              let(:criteria) do
                Band.where(name: 'FKA Twigs').tap do |crit|
                  crit.documents = [
                    Band.create!(name: 'FKA Twigs'),
                    Band.create!(name: 'FKA Twigs', records: [ Record.new(name: 'LP1') ])
                  ]
                end
              end

              let(:embedded_pluck) do
                context.pluck(:name, 'records.name')
              end

              let(:expected) do
                [
                  ["FKA Twigs", []],
                  ['FKA Twigs', ["LP1"]]
                ]
              end

              it 'returns the list of top-level field and subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end

            context 'when only a subdocument field is plucked' do

              let(:criteria) do
                Band.where(name: 'FKA Twigs').tap do |crit|
                  crit.documents = [
                    Band.create!(name: 'FKA Twigs'),
                    Band.create!(name: 'FKA Twigs', records: [ Record.new(name: 'LP1') ])
                  ]
                end
              end

              let(:embedded_pluck) do
                context.pluck('records.name')
              end

              let(:expected) do
                [
                  [],
                  ["LP1"]
                ]
              end

              it 'returns the list of subdocument values' do
                expect(embedded_pluck).to eq(expected)
              end
            end
          end
        end

        context "when plucking multi-fields" do

          let(:plucked) do
            context.pluck(:name, :likes)
          end

          it "returns the values" do
            expect(plucked).to contain_exactly(["10,000 Maniacs", 1], ["Depeche Mode", 3], ["Tool", 3], ["Photek", 1])
          end
        end

        context "when there are duplicate values" do

          let(:plucked) do
            context.pluck(:likes)
          end

          it "returns the duplicates" do
            expect(plucked).to contain_exactly(1, 3, 3, 1)
          end
        end
      end

      context "when plucking an aliased field" do

        let(:plucked) do
          context.pluck(:id)
        end

        it "returns the field values" do
          expect(plucked).to eq([ depeche.id, tool.id, photek.id, maniacs.id ])
        end
      end

      context "when plucking existent and non-existent fields" do

        let(:plucked) do
          context.pluck(:id, :fooz)
        end

        it "returns nil for the field that doesnt exist" do
          expect(plucked).to eq([[depeche.id, nil], [tool.id, nil], [photek.id, nil], [maniacs.id, nil] ])
        end
      end

      context "when plucking a field that doesnt exist" do

        context "when pluck one field" do

          let(:plucked) do
            context.pluck(:foo)
          end

          it "returns an array with nil values" do
            expect(plucked).to eq([nil, nil, nil, nil])
          end
        end

        context "when pluck multiple fields" do

          let(:plucked) do
            context.pluck(:foo, :bar)
          end

          it "returns an array of arrays with nil values" do
            expect(plucked).to eq([[nil, nil], [nil, nil], [nil, nil], [nil, nil]])
          end
        end
      end

      context 'when plucking a localized field' do

        before do
          I18n.locale = :en
          d = Dictionary.create!(description: 'english-text')
          I18n.locale = :de
          d.description = 'deutsch-text'
          d.save!
        end

        after do
          I18n.locale = :en
        end

        let(:criteria) do
          Dictionary.all.tap do |crit|
            crit.documents = [ Dictionary.first ]
          end
        end

        context 'when plucking the entire field' do

          let(:plucked) do
            context.pluck(:description)
          end

          let(:plucked_translations) do
            context.pluck(:description_translations)
          end

          let(:plucked_translations_both) do
            context.pluck(:description_translations, :description)
          end

          it 'returns the demongoized translations' do
            expect(plucked.first).to eq('deutsch-text')
          end

          it 'returns the full translations hash to _translations' do
            expect(plucked_translations.first).to eq({"de"=>"deutsch-text", "en"=>"english-text"})
          end

          it 'returns both' do
            expect(plucked_translations_both.first).to eq([{"de"=>"deutsch-text", "en"=>"english-text"}, "deutsch-text"])
          end
        end

        context 'when plucking a specific locale' do

          let(:plucked) do
            context.pluck(:'description.de')
          end

          it 'returns the specific translations' do
            expect(plucked.first).to eq('deutsch-text')
          end
        end

        context 'when plucking a specific locale from _translations field' do

          let(:plucked) do
            context.pluck(:'description_translations.de')
          end

          it 'returns the specific translations' do
            expect(plucked.first).to eq('deutsch-text')
          end
        end

        context 'when fallbacks are enabled with a locale list' do
          require_fallbacks

          around(:all) do |example|
            prev_fallbacks = I18n.fallbacks.dup
            I18n.fallbacks[:he] = [ :en ]
            example.run
            I18n.fallbacks = prev_fallbacks
          end

          after do
            I18n.locale = :en
          end

          let(:plucked) do
            context.pluck(:description).first
          end

          it "correctly uses the fallback" do
            I18n.locale = :en
            d = Dictionary.create!(description: 'english-text')
            I18n.locale = :he
            plucked.should == "english-text"
          end
        end

        context "when the localized field is embedded" do
          before do
            p = Passport.new
            I18n.locale = :en
            p.name = "Neil"
            I18n.locale = :he
            p.name = "Nissim"

            Person.create!(passport: p, employer_id: 12345)
          end

          after do
            I18n.locale = :en
          end

          let(:plucked) do
            Person.where(employer_id: 12345).pluck("pass.name").first
          end

          let(:plucked_translations) do
            Person.where(employer_id: 12345).pluck("pass.name_translations").first
          end

          let(:plucked_translations_field) do
            Person.where(employer_id: 12345).pluck("pass.name_translations.en").first
          end

          it "returns the translation for the current locale" do
            expect(plucked).to eq("Nissim")
          end

          it "returns the full _translation hash" do
            expect(plucked_translations).to eq({ "en" => "Neil", "he" => "Nissim" })
          end

          it "returns the translation for the requested locale" do
            expect(plucked_translations_field).to eq("Neil")
          end
        end
      end

      context 'when plucking a field to be demongoized' do

        let(:plucked) do
          Band.where(name: maniacs.name).pluck(:sales)
        end

        it "demongoizes the field" do
          expect(plucked.first).to be_a(BigDecimal)
          expect(plucked.first).to eq(BigDecimal("1E2"))
        end
      end

      context "when plucking an embedded field" do
        let(:label) { Label.new(sales: "1E2") }
        let!(:band) { Band.create!(label: label) }

        let(:plucked) do
          Band.where(_id: band.id).tap do |crit|
            crit.documents = [band]
          end.pluck("label.sales")
        end

        it "demongoizes the field" do
          expect(plucked).to eq([ BigDecimal("1E2") ])
        end
      end

      context "when plucking an embeds_many field" do
        let(:label) { Label.new(sales: "1E2") }
        let!(:band) { Band.create!(labels: [label]) }

        let(:plucked) { Band.where(_id: band.id).pluck("labels.sales") }

        it "demongoizes the field" do
          expect(plucked.first).to eq([ BigDecimal("1E2") ])
        end
      end

      context "when plucking a nonexistent embedded field" do
        let(:label) { Label.new(sales: "1E2") }
        let!(:band) { Band.create!(label: label) }

        let(:plucked) do
          Band.where(_id: band.id).tap do |crit|
            crit.documents = band
          end.pluck("label.qwerty")
        end

        it "returns nil" do
          expect(plucked.first).to eq(nil)
        end
      end

      context "when tallying deeply nested arrays/embedded associations" do

        let(:criteria) do
          Person.all.tap do |crit|
            crit.documents = [
              Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ]),
              Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ]),
              Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 3 } } ]))) ]),
            ]
          end
        end

        let(:plucked) do
          context.pluck("addresses.code.deepest.array.y.z")
        end

        it "returns the correct hash" do
          expect(plucked).to eq([
            [ [ 1, 2 ] ], [ [ 1, 2 ] ], [ [ 1, 3 ] ]
          ])
        end
      end
    end
  end

  describe '#inc' do

    let(:criteria) do
      Address.all.tap do |crit|
        crit.documents = [ Address.new(number: 1),
                           Address.new(number: 2),
                           Address.new(number: 3) ]
      end
    end

    let(:context) do
      described_class.new(criteria)
    end

    it 'increases each member' do
      expect(context.inc(number: 10).collect(&:number)).to eql([11, 12, 13])
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

    context 'when there is no collation on the criteria' do

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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.tap do |crit|
          crit.documents = [ hobrecht, friedel, pfluger ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.skip(1)
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.tap do |crit|
          crit.documents = [ hobrecht, friedel, pfluger ]
        end.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.sort(state: 1)
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
    end
  end

  describe "#update" do

    let(:person) do
      Person.create!
    end

    let(:hobrecht) do
      person.addresses.create!(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create!(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create!(street: "pfluger")
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
        hobrecht.locations.create!(name: "home")
      end

      let!(:work) do
        hobrecht.locations.create!(name: "work")
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

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.update
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
    end
  end

  describe "#update_all" do

    let(:person) do
      Person.create!
    end

    let(:hobrecht) do
      person.addresses.create!(street: "hobrecht")
    end

    let(:friedel) do
      person.addresses.create!(street: "friedel")
    end

    let(:pfluger) do
      person.addresses.create!(street: "pfluger")
    end

    context 'when there is a collation on the criteria' do

      let(:criteria) do
        Address.all.collation(locale: 'en_US', strength: 2)
      end

      it "raises an exception" do
        expect {
          context.update_all({})
        }.to raise_exception(Mongoid::Errors::InMemoryCollationNotSupported)
      end
    end

    context "when the documents are empty" do

      let(:person_two) do
        Person.create!
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
        hobrecht.locations.create!(name: "home")
      end

      let!(:work) do
        hobrecht.locations.create!(name: "work")
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
