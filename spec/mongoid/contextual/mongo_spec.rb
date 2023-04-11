# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Mongo do

  [ :blank?, :empty? ].each do |method|

    describe "##{method}" do

      before do
        Band.create!(name: "Depeche Mode")
      end

      context "when the count is zero" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns true" do
          expect(context.send(method)).to be true
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
          expect(context.send(method)).to be false
        end
      end
    end
  end

  describe "#count" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    context "when no arguments are provided" do

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the number of documents that match" do
        expect(context.count).to eq(1)
      end
    end

    context "when the query cache is enabled" do
      query_cache_enabled

      let(:context) do
        described_class.new(criteria)
      end

      it "only executes the count query once" do
        expect_query(1) do
          2.times { expect(context.count).to eq(1) }
        end
      end
    end

    context "when provided a block" do

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count do |doc|
          doc.likes.nil?
        end
      end

      it "returns the number of documents that match" do
        expect(count).to eq(1)
      end

      context "and a limit true" do

        before do
          2.times { Band.create!(name: "Depeche Mode", likes: 1) }
        end

        let(:count) do
          context.count(true) do |doc|
            doc.likes.nil?
          end
        end

        it "returns the number of documents that match" do
          expect(count).to eq(1)
        end
      end
    end

    context "when provided limit" do

      before do
        2.times { Band.create!(name: "Depeche Mode") }
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:count) do
        context.count(limit: 2)
      end

      it "returns the number of documents that match" do
        expect(count).to eq(2)
      end
    end

    context 'when a collation is specified' do
      min_server_version '3.4'

      let(:context) do
        described_class.new(criteria)
      end

      context 'when the collation is specified on the criteria' do

        let(:criteria) do
          Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
        end

        let(:count) do
          context.count
        end

        it 'applies the collation' do
          expect(count).to eq(1)
        end
      end
    end
  end

  describe "#estimated_count" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.where
    end

    context "when not providing options" do
      it 'returns the correct count' do
        expect(criteria.estimated_count).to eq(2)
      end
    end

    context "when providing options" do
      it 'returns the correct count' do
        expect(criteria.estimated_count(maxTimeMS: 1000)).to eq(2)
      end
    end

    context "when the query cache is enabled" do
      query_cache_enabled

      let(:context) do
        described_class.new(criteria)
      end

      it "the results are not cached" do
        expect_query(2) do
          2.times do
            context.estimated_count
          end
        end
      end
    end

    context "when the criteria contains a selector", :focus do
      let(:criteria) do
        Band.where(name: "New Order")
      end

      context "when not providing options" do
        it 'raises an error' do
          expect do
            criteria.estimated_count
          end.to raise_error(Mongoid::Errors::InvalidEstimatedCountCriteria)
        end
      end

      context "when providing options" do
        it 'raises an error' do
          expect do
            criteria.estimated_count(maxTimeMS: 1000)
          end.to raise_error(Mongoid::Errors::InvalidEstimatedCountCriteria)
        end
      end
    end
  end



  [ :delete, :delete_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create!(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create!(name: "New Order")
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
          expect(Band.find(new_order.id)).to eq(new_order)
        end

        it "deletes the correct number of documents" do
          expect(Band.count).to eq(1)
        end

        it "returns the number of documents deleted" do
          expect(deleted).to eq(1)
        end

        context 'when the criteria has a collation' do
          min_server_version '3.4'

          let(:criteria) do
            Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
          end

          let(:context) do
            described_class.new(criteria)
          end

          let!(:deleted) do
            context.send(method)
          end

          it "deletes the matching documents" do
            expect(Band.find(new_order.id)).to eq(new_order)
          end

          it "deletes the correct number of documents" do
            expect(Band.count).to eq(1)
          end

          it "returns the number of documents deleted" do
            expect(deleted).to eq(1)
          end
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
          expect(Band.count).to eq(0)
        end
      end

      context 'when the write concern is unacknowledged' do

        let(:criteria) do
          Band.all
        end

        let!(:deleted) do
          criteria.with(write: { w: 0 }) do |crit|
            crit.send(method)
          end
        end

        it 'returns 0' do
          expect(deleted).to eq(0)
        end
      end
    end
  end

  [ :destroy, :destroy_all ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create!(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create!(name: "New Order")
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
          expect(Band.find(new_order.id)).to eq(new_order)
        end

        it "destroys the correct number of documents" do
          expect(Band.count).to eq(1)
        end

        it "returns the number of documents destroyed" do
          expect(destroyed).to eq(1)
        end

        context 'when the criteria has a collation' do
          min_server_version '3.4'

          let(:criteria) do
            Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
          end

          let(:context) do
            described_class.new(criteria)
          end

          let!(:destroyed) do
            context.send(method)
          end

          it "destroys the matching documents" do
            expect(Band.find(new_order.id)).to eq(new_order)
          end

          it "destroys the correct number of documents" do
            expect(Band.count).to eq(1)
          end

          it "returns the number of documents destroyed" do
            expect(destroyed).to eq(1)
          end
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
          expect(Band.count).to eq(0)
        end
      end
    end

    context 'when the write concern is unacknowledged' do

      before do
        2.times { Band.create! }
      end

      let(:criteria) do
        Band.all
      end

      let!(:deleted) do
        criteria.with(write: { w: 0 }) do |crit|
          crit.send(method)
        end
      end

      it 'returns 0' do
        expect(deleted).to eq(0)
      end
    end
  end

  describe "#distinct" do

    before do
      Band.create!(name: "Depeche Mode", years: 30, sales: "1E2")
      Band.create!(name: "New Order", years: 25, sales: "2E3")
      Band.create!(name: "10,000 Maniacs", years: 20, sales: "1E2")
    end

    with_config_values :legacy_pluck_distinct, true, false do
      context "when limiting the result set" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the distinct matching fields" do
          expect(context.distinct(:name)).to eq([ "Depeche Mode" ])
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
          expect(context.distinct(:name).sort).to eq([ "10,000 Maniacs", "Depeche Mode", "New Order" ].sort)
        end
      end

      context "when providing an aliased field" do

        let(:criteria) do
          Band.criteria
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the distinct field values" do
          expect(context.distinct(:years).sort).to eq([ 20, 25, 30 ])
        end
      end

      context 'when a collation is specified' do
        min_server_version '3.4'

        before do
          Band.create!(name: 'DEPECHE MODE')
        end

        let(:context) do
          described_class.new(criteria)
        end

        let(:expected_results) do
          ["10,000 Maniacs", "Depeche Mode", "New Order"]
        end

        let(:criteria) do
          Band.where({}).collation(locale: 'en_US', strength: 2)
        end

        it 'applies the collation' do
          expect(context.distinct(:name).sort).to eq(expected_results.sort)
        end
      end
    end

    context "when providing a demongoizable field" do
      let(:criteria) do
        Band.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true

        context 'when storing BigDecimal as string' do
          config_override :map_big_decimal_to_decimal128, false

          it "returns the non-demongoized distinct field values" do
            expect(context.distinct(:sales).sort).to eq([ "1E2", "2E3" ])
          end
        end

        context 'when storing BigDecimal as decimal128' do
          config_override :map_big_decimal_to_decimal128, true
          min_bson_version '4.15.0'
          max_bson_version '4.99.99'

          it "returns the non-demongoized distinct field values" do
            expect(context.distinct(:sales).sort).to eq([ BSON::Decimal128.new("1E2"), BSON::Decimal128.new("2E3") ])
          end
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false

        it "returns the non-demongoized distinct field values" do
          expect(context.distinct(:sales).sort).to eq([ BigDecimal("1E2"), BigDecimal("2E3") ])
        end
      end
    end

    context "when getting a localized field" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        d = Dictionary.create!(description: 'english-text')
        I18n.locale = :de
        d.description = 'deutsch-text'
        d.save!
      end

      let(:criteria) do
        Dictionary.criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when getting the field without _translations" do
        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "gets the full hash" do
            expect(context.distinct(:description)).to eq([{ "de" => "deutsch-text", "en" => "english-text" }])
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it "gets the demongoized localized field" do
            expect(context.distinct(:description)).to eq([ 'deutsch-text' ])
          end
        end
      end

      context "when getting the field with _translations" do
        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "gets an empty list" do
            expect(context.distinct(:description_translations)).to eq([])
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it "gets the full hash" do
            expect(context.distinct(:description_translations)).to eq([ { "de" => "deutsch-text", "en" => "english-text" } ])
          end
        end
      end

      context 'when plucking a specific locale' do

        let(:distinct) do
          context.distinct(:'description.de')
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it 'returns the specific translation' do
            expect(distinct).to eq([ 'deutsch-text' ])
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it 'returns the specific translation' do
            expect(distinct).to eq([ "deutsch-text" ])
          end
        end
      end

      context 'when plucking a specific locale from _translations field' do

        let(:distinct) do
          context.distinct(:'description_translations.de')
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it 'returns the empty list' do
            expect(distinct).to eq([])
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it 'returns the specific translations' do
            expect(distinct).to eq(['deutsch-text'])
          end
        end
      end

      context 'when fallbacks are enabled with a locale list' do
        require_fallbacks
        with_default_i18n_configs

        before do
          I18n.fallbacks[:he] = [ :en ]
        end

        let(:distinct) do
          context.distinct(:description).first
        end

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "does not correctly use the fallback" do
            distinct.should == {"de"=>"deutsch-text", "en"=>"english-text"}
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

          it "correctly uses the fallback" do
            I18n.locale = :en
            Dictionary.create!(description: 'english-text')
            I18n.locale = :he
            distinct.should == "english-text"
          end
        end
      end

      context "when the localized field is embedded" do
        with_default_i18n_configs

        before do
          p = Passport.new
          I18n.locale = :en
          p.name = "Neil"
          I18n.locale = :he
          p.name = "Nissim"

          Person.create!(passport: p, employer_id: 12345)
        end

        let(:criteria) do
          Person.where(employer_id: 12345)
        end

        let(:context) do
          described_class.new(criteria)
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

        context "when legacy_pluck_distinct is set" do
          config_override :legacy_pluck_distinct, true

          it "returns the full hash" do
            expect(distinct).to eq({ "en" => "Neil", "he" => "Nissim" })
          end

          it "returns the empty hash" do
            expect(distinct_translations).to eq(nil)
          end

          it "returns the empty hash" do
            expect(distinct_translations_field).to eq(nil)
          end
        end

        context "when legacy_pluck_distinct is not set" do
          config_override :legacy_pluck_distinct, false

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
    end

    context "when getting an embedded field" do

      let(:label) { Label.new(sales: "1E2") }
      let!(:band) { Band.create!(label: label) }
      let(:criteria) { Band.where(_id: band.id) }
      let(:context) { described_class.new(criteria) }

      context "when legacy_pluck_distinct is set" do
        config_override :legacy_pluck_distinct, true
        config_override :map_big_decimal_to_decimal128, true
        max_bson_version '4.99.99'

        it "returns the distinct matching fields" do
          expect(context.distinct("label.sales")).to eq([ BSON::Decimal128.new('1E+2') ])
        end
      end

      context "when legacy_pluck_distinct is not set" do
        config_override :legacy_pluck_distinct, false
        it "returns the distinct matching fields" do
          expect(context.distinct("label.sales")).to eq([ BigDecimal("1E2") ])
        end
      end
    end
  end

  describe "#tally" do
    let(:fans1) { [ Fanatic.new(age:1), Fanatic.new(age:2) ] }
    let(:fans2) { [ Fanatic.new(age:1), Fanatic.new(age:2) ] }
    let(:fans3) { [ Fanatic.new(age:1), Fanatic.new(age:3) ] }

    let(:genres1) { [ { x: 1, y: { z: 1 } }, { x: 2, y: { z: 2 } }, { y: 3 } ]}
    let(:genres2) { [ { x: 1, y: { z: 1 } }, { x: 2, y: { z: 2 } }, { y: 4 } ]}
    let(:genres3) { [ { x: 1, y: { z: 1 } }, { x: 3, y: { z: 3 } }, { y: 5 } ]}

    let(:label1) {  Label.new(name: "Atlantic") }
    let(:label2) {  Label.new(name: "Atlantic") }
    let(:label3) {  Label.new(name: "Columbia") }

    before do
      Band.create!(origin: "tally", name: "Depeche Mode", years: 30, sales: "1E2", label: label1, genres: genres1)
      Band.create!(origin: "tally", name: "New Order", years: 30, sales: "2E3", label: label2, genres: genres2)
      Band.create!(origin: "tally", name: "10,000 Maniacs", years: 30, sales: "1E2", label: label3, genres: genres3)
      Band.create!(origin: "tally2", fanatics: fans1, genres: [1, 2])
      Band.create!(origin: "tally2", fanatics: fans2, genres: [1, 2])
      Band.create!(origin: "tally2", fanatics: fans3, genres: [1, 3])
    end

    let(:criteria) { Band.where(origin: "tally") }

    context "when tallying a string" do
      let(:tally) do
        criteria.tally(:name)
      end

      it "returns the correct hash" do
        expect(tally).to eq("Depeche Mode" => 1, "New Order" => 1, "10,000 Maniacs" => 1)
      end
    end

    context "using an aliased field" do
      let(:tally) do
        criteria.tally(:years)
      end

      it "returns the correct hash" do
        expect(tally).to eq(30 => 3)
      end
    end

    context "when tallying a demongoizable field" do
      let(:tally) do
        criteria.tally(:sales)
      end

      it "returns the correct hash" do
        expect(tally).to eq(BigDecimal("1E2") => 2, BigDecimal("2E3") => 1)
      end
    end

    context "when tallying a localized field" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        d1 = Dictionary.create!(description: 'en1')
        d2 = Dictionary.create!(description: 'en1')
        d3 = Dictionary.create!(description: 'en1')
        d4 = Dictionary.create!(description: 'en2')
        I18n.locale = :de
        d1.description = 'de1'
        d2.description = 'de1'
        d3.description = 'de2'
        d4.description = 'de3'
        d1.save!
        d2.save!
        d3.save!
        d4.save!
        I18n.locale = :en
      end

      context "when getting the demongoized field" do
        let(:tallied) do
          Dictionary.tally(:description)
        end

        it "returns the translation for the current locale" do
          expect(tallied).to eq("en1" => 3, "en2" => 1)
        end
      end

      context "when getting a specific locale" do
        let(:tallied) do
          Dictionary.tally("description.de")
        end

        it "returns the translation for the the specific locale" do
          expect(tallied).to eq("de1" => 2, "de2" => 1, "de3" => 1)
        end
      end

      context "when getting the full hash" do
        let(:tallied) do
          Dictionary.tally("description_translations")
        end

        it "returns the correct hash" do
          expect(tallied).to eq(
            {"de" => "de1", "en" => "en1" } => 2,
            {"de" => "de2", "en" => "en1" } => 1,
            {"de" => "de3", "en" => "en2" } => 1
          )
        end
      end
    end

    context "when tallying an embedded localized field" do
      with_default_i18n_configs

      before do
        I18n.locale = :en
        address1a = Address.new(name: "en1")
        address1b = Address.new(name: "en2")
        address2a = Address.new(name: "en1")
        address2b = Address.new(name: "en3")
        I18n.locale = :de
        address1a.name = "de1"
        address1b.name = "de2"
        address2a.name = "de1"
        address2b.name = "de3"
        Person.create!(addresses: [ address1a, address1b ])
        Person.create!(addresses: [ address2a, address2b ])
        I18n.locale = :en
      end

      context "when getting the demongoized field" do
        let(:tallied) do
          Person.tally("addresses.name")
        end

        it "returns the translation for the current locale" do
          expect(tallied).to eq(
            [ "en1", "en2" ] => 1,
            [ "en1", "en3" ] => 1,
          )
        end
      end

      context "when getting a specific locale" do
        let(:tallied) do
          Person.tally("addresses.name.de")
        end

        it "returns the translation for the the specific locale" do
          expect(tallied).to eq(
            [ "de1", "de2" ] => 1,
            [ "de1", "de3" ] => 1,
          )
        end
      end

      context "when getting the full hash" do
        let(:tallied) do
          Person.tally("addresses.name_translations")
        end

        it "returns the correct hash" do
          expect(tallied).to eq(
            [{ "de" => "de1", "en" => "en1" }, { "de" => "de2", "en" => "en2" }] => 1,
            [{ "de" => "de1", "en" => "en1" }, { "de" => "de3", "en" => "en3" }] => 1,
          )
        end
      end

    end

    context "when tallying an embedded field" do
      let(:tally) do
        criteria.tally("label.name")
      end

      it "returns the correct hash" do
        expect(tally).to eq("Atlantic" => 2, "Columbia" => 1)
      end
    end

    context "when tallying an element in an embeds_many field" do
      let(:criteria) { Band.where(origin: "tally2") }

      let(:tally) do
        criteria.tally("fanatics.age")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when tallying an embeds_many field" do
      let(:criteria) { Band.where(origin: "tally2") }

      let(:tally) do
        criteria.tally("fanatics")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          fans1.map(&:attributes) => 1,
          fans2.map(&:attributes) => 1,
          fans3.map(&:attributes) => 1,
        )
      end
    end

    context "when tallying a field of type array" do
      let(:criteria) { Band.where(origin: "tally2") }

      let(:tally) do
        criteria.tally("genres")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when tallying an element from an array of hashes" do
      let(:criteria) { Band.where(origin: "tally") }

      let(:tally) do
        criteria.tally("genres.x")
      end

      it "returns the correct hash without the nil keys" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when tallying an element from an array of hashes; with duplicate" do

      before do
        Band.create!(origin: "tally", genres: [ { x: 1 }, {x: 1} ] )
      end

      let(:criteria) { Band.where(origin: "tally") }

      let(:tally) do
        criteria.tally("genres.x")
      end

      it "returns the correct hash without the nil keys" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1,
          [1, 1] => 1,
        )
      end
    end

    context "when tallying an aliased field of type array" do

      before do
        Person.create!(array: [ 1, 2 ])
        Person.create!(array: [ 1, 3 ])
      end

      let(:tally) do
        Person.tally("array")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 1,
          [1, 3] => 1
        )
      end
    end

    context "when going multiple levels deep in arrays" do
      let(:criteria) { Band.where(origin: "tally") }

      let(:tally) do
        criteria.tally("genres.y.z")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when going multiple levels deep in an array" do
      let(:criteria) { Band.where(origin: "tally") }

      let(:tally) do
        criteria.tally("genres.y.z")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when tallying deeply nested arrays/embedded associations" do

      before do
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 3 } } ]))) ])
      end

      let(:tally) do
        Person.tally("addresses.code.deepest.array.y.z")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [ [ 1, 2 ] ] => 2,
          [ [ 1, 3 ] ] => 1
        )
      end
    end

    context "when tallying deeply nested arrays/embedded associations" do

      before do
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))),
                                    Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))),
                                    Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 2 } } ]))) ])
        Person.create!(addresses: [ Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 3 } } ]))),
                                    Address.new(code: Code.new(deepest: Deepest.new(array: [ { y: { z: 1 } }, { y: { z: 3 } } ]))) ])
      end

      let(:tally) do
        Person.tally("addresses.code.deepest.array.y.z")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [ [ 1, 2 ], [ 1, 2 ] ] => 2,
          [ [ 1, 3 ], [ 1, 3 ] ] => 1
        )
      end
    end

    context "when some keys are missing" do
      before do
        3.times { Band.create!(origin: "tally") }
      end

      let(:tally) do
        criteria.tally(:name)
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          "Depeche Mode" => 1,
          "New Order" => 1,
          "10,000 Maniacs" => 1,
          nil => 3
        )
      end
    end

    context "when the first element is an embeds_one" do
      before do
        Person.create!(name: Name.new(translations: [ Translation.new(language: 1), Translation.new(language: 2) ]))
        Person.create!(name: Name.new(translations: [ Translation.new(language: 1), Translation.new(language: 2) ]))
        Person.create!(name: Name.new(translations: [ Translation.new(language: 1), Translation.new(language: 3) ]))
      end

      let(:tally) do
        Person.tally("name.translations.language")
      end

      it "returns the correct hash" do
        expect(tally).to eq(
          [1, 2] => 2,
          [1, 3] => 1
        )
      end
    end

    context "when tallying demongoizable values from typeless fields" do

      let!(:person1) { Person.create!(ssn: /hello/) }
      let!(:person2) { Person.create!(ssn: BSON::Decimal128.new("1")) }
      let(:tally) { Person.tally("ssn") }

      context "< BSON 5" do
        max_bson_version '4.99.99'

        it "stores the correct types in the database" do
          Person.find(person1.id).attributes["ssn"].should be_a BSON::Regexp::Raw
          Person.find(person2.id).attributes["ssn"].should be_a BSON::Decimal128
        end

        it "tallies the correct type" do
          tally.keys.map(&:class).sort do |a,b|
            a.to_s <=> b.to_s
          end.should == [BSON::Decimal128, BSON::Regexp::Raw]
        end
      end

      context ">= BSON 5" do
        min_bson_version "5.0"

        it "stores the correct types in the database" do
          Person.find(person1.id).ssn.should be_a BSON::Regexp::Raw
          Person.find(person2.id).ssn.should be_a BigDeimal
        end

        it "tallies the correct type" do
          tally.keys.map(&:class).sort do |a,b|
            a.to_s <=> b.to_s
          end.should == [BigDecimal, BSON::Regexp::Raw]
        end
      end
    end
  end

  describe "#each" do

    before do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let(:criteria) do
        Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
      end

      it "yields mongoid documents to the block" do
        context.each do |doc|
          expect(doc).to be_a(Mongoid::Document)
        end
      end

      it "iterates over the matching documents" do
        context.each do |doc|
          expect(doc.name).to eq("Depeche Mode")
        end
      end

      it "returns self" do
        expect(context.each{}).to be(context)
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
          expect(doc.name).to eq("Depeche Mode")
        end
      end

      it "returns self" do
        expect(context.each{}).to be(context)
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

          before do
            10.times { |i| Band.create!(name: "Test #{i}") }
          end

          let(:criteria) do
            Band.batch_size(5)
          end

          it "yields mongoid documents" do
            expect(enum.next).to be_a(Mongoid::Document)
          end

          it "does not load all documents" do
            subscriber = Mrss::EventSubscriber.new
            context.view.client.subscribe(Mongo::Monitoring::COMMAND, subscriber)

            enum.next

            find_events = subscriber.all_events.select do |evt|
              evt.command_name == 'find'
            end
            expect(find_events.length).to be(2)
            get_more_events = subscriber.all_events.select do |evt|
              evt.command_name == 'getMore'
            end
            expect(get_more_events.length).to be(0)
          ensure
            context.view.client.unsubscribe(Mongo::Monitoring::COMMAND, subscriber)
          end
        end
      end
    end

    context 'when the criteria has a parent document' do

      before do
        Post.create!(person: person)
        Post.create!(person: person)
        Post.create!(person: person)
      end

      let(:person) do
        Person.new
      end

      let(:criteria) do
        person.posts.all
      end

      let(:persons) do
        criteria.collect(&:person)
      end

      it 'sets the same parent object on each related object' do
        expect(persons.uniq.size).to eq(1)
      end
    end
  end

  describe "#eager_load" do

    let(:criteria) do
      Person.includes(:game)
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when no documents are returned" do

      let(:game_association) do
        Person.reflect_on_association(:game)
      end

      it "does not make any additional database queries" do
        expect(game_association).to receive(:eager_load).never
        context.send(:eager_load, [])
      end
    end
  end

  describe "#exists?" do

    let!(:band) do
      Band.create!(name: "Depeche Mode", active: true)
    end

    context "when not passing options" do

      context "when the count is zero" do

        let(:criteria) do
          Band.where(name: "New Order")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns false" do
          expect(context).to_not be_exists
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
          expect(context).to be_exists
        end
      end

      context "when caching is not enabled" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when exists? already called and query cache is enabled" do
          query_cache_enabled

          before do
            context.exists?
          end

          it "does not hit the database again" do
            expect_no_queries do
              expect(context).to be_exists
            end
          end
        end
      end
    end

    context "when passing an _id" do

      context "when its of type BSON::ObjectId" do

        context "when calling it on the class" do

          it "returns true" do
            expect(Band.exists?(band._id)).to be true
          end
        end

        context "when calling it on a criteria that includes the object" do

          it "returns true" do
            expect(Band.where(name: band.name).exists?(band._id)).to be true
          end
        end

        context "when calling it on a criteria that does not include the object" do

          it "returns false" do
            expect(Band.where(name: "bogus").exists?(band._id)).to be false
          end
        end

        context "when the id does not exist" do

          it "returns false" do
            expect(Band.exists?(BSON::ObjectId.new)).to be false
          end
        end
      end

      context "when its of type String" do

        context "when the id exists" do

          it "returns true" do
            expect(Band.exists?(band._id.to_s)).to be true
          end
        end

        context "when the id does not exist" do

          it "returns false" do
            expect(Band.exists?(BSON::ObjectId.new.to_s)).to be false
          end
        end
      end
    end

    context "when passing a hash" do

      context "when calling it on the class" do

        it "returns true" do
          expect(Band.exists?(name: band.name)).to be true
        end
      end

      context "when calling it on a criteria that includes the object" do

        it "returns true" do
          expect(Band.where(active: true).exists?(name: band.name)).to be true
        end
      end

      context "when calling it on a criteria that does not include the object" do

        it "returns false" do
          expect(Band.where(active: false).exists?(name: band.name)).to be false
        end
      end

      context "when the conditions don't match" do

        it "returns false" do
          expect(Band.exists?(name: "bogus")).to be false
        end
      end
    end

    context "when passing false" do

      it "returns false" do
        expect(Band.exists?(false)).to be false
      end
    end

    context "when passing nil" do

      it "returns false" do
        expect(Band.exists?(nil)).to be false
      end
    end

    context "when the limit is 0" do

      it "returns false" do
        expect(Band.limit(0).exists?).to be false
      end
    end

    context "when the criteria limit is 0" do

      it "returns false" do
        expect(Band.criteria.limit(0).exists?).to be false
      end
    end
  end

  describe "#explain" do

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "returns the criteria explain path" do
      explain = context.explain
      expect(explain).to_not be_empty
      expect(explain.keys).to include("queryPlanner", "executionStats", "serverInfo")
    end

    it "respects options passed to explain" do
      explain = context.explain(verbosity: :query_planner)
      expect(explain).to_not be_empty
      expect(explain.keys).to include("queryPlanner", "serverInfo")
      expect(explain.keys).not_to include("executionStats")
    end
  end

  describe "#find_one_and_replace" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create!(name: "Tool")
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_replace(name: 'FKA Twigs')
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "updates the document in the database" do
          expect(depeche.reload.name).to eq('FKA Twigs')
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_replace(likes: 1)
        end

        it "returns the first matching document" do
          expect(result).to eq(tool)
        end

        it "updates the document in the database" do
          expect(tool.reload.likes).to eq(1)
          expect(tool.reload.name).to be_nil
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_replace(name: 'FKA Twigs', likes: 1)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "limits the returned fields" do
          expect(result.name).to be_nil
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_replace({ likes: 1 }, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.name).to be_nil
          expect(result.likes).to eq(1)
        end
      end

      context 'when a collation is specified on the criteria' do
        min_server_version '3.4'

        let(:criteria) do
          Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_replace({ likes: 1 }, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.likes).to eq(1)
          expect(result.name).to be_nil
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "DEPECHE MODE")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:result) do
        context.find_one_and_replace(name: 'FKA Twigs')
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#find_one_and_update" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:tool) do
      Band.create!(name: "Tool")
    end

    context "when the selector matches" do

      context "when not providing options" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when sorting" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(tool)
        end

        it "updates the document in the database" do
          expect(tool.reload.likes).to eq(1)
        end
      end

      context "when limiting fields" do

        let(:criteria) do
          Band.only(:_id)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update("$inc" => { likes: 1 })
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "limits the returned fields" do
          expect(result.name).to be_nil
        end

        it "updates the document in the database" do
          expect(depeche.reload.likes).to eq(1)
        end
      end

      context "when returning new" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update({ "$inc" => { likes: 1 }}, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.likes).to eq(1)
        end
      end

      context 'when a collation is specified on the criteria' do
        min_server_version '3.4'

        let(:criteria) do
          Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_update({ "$inc" => { likes: 1 }}, return_document: :after)
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "returns the updated document" do
          expect(result.likes).to eq(1)
        end
      end
    end

    context "when the selector does not match" do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:result) do
        context.find_one_and_update("$inc" => { likes: 1 })
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#find_one_and_delete" do

    let!(:depeche) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    let!(:result) do
      context.find_one_and_delete
    end

    context 'when the selector matches a document' do

      it "returns the first matching document" do
        expect(result).to eq(depeche)
      end

      it "deletes the document from the database" do
        expect {
          depeche.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Band with id\(s\)/)
      end

      context 'when a collation is specified on the criteria' do
        min_server_version '3.4'

        let(:criteria) do
          Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
        end

        let(:context) do
          described_class.new(criteria)
        end

        let!(:result) do
          context.find_one_and_delete
        end

        it "returns the first matching document" do
          expect(result).to eq(depeche)
        end

        it "deletes the document from the database" do
          expect {
            depeche.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Band with id\(s\)/)
        end
      end
    end

    context 'when the selector does not match a document' do

      let(:criteria) do
        Band.where(name: "Placebo")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:result) do
        context.find_one_and_delete
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  [ :first, :one ].each do |method|

    describe "##{method}" do

      let!(:depeche_mode) do
        Band.create!(name: "Depeche Mode")
      end

      let!(:new_order) do
        Band.create!(name: "New Order")
      end

      let!(:rolling_stones) do
        Band.create!(name: "The Rolling Stones")
      end

      context "when the context is not cached" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the first matching document" do
          expect(context.send(method)).to eq(depeche_mode)
        end

        context 'when the criteria has a collation' do
          min_server_version '3.4'

          let(:criteria) do
            Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
          end

          it "returns the first matching document" do
            expect(context.send(method)).to eq(depeche_mode)
          end
        end
      end

      context "when using .desc" do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when there is sort on the context" do

          it "follows the main sort" do
            expect(context.send(method)).to eq(rolling_stones)
          end
        end

        context "when subsequently calling #last" do

          it "returns the correct document" do
            expect(context.send(method)).to eq(rolling_stones)
            expect(context.last).to eq(depeche_mode)
          end
        end
      end

      context 'when the criteria has no sort' do

        let(:criteria) do
          Band.all
        end

        let(:context) do
          described_class.new(criteria)
        end


        it 'applies a sort on _id' do
          expect(context.send(method)).to eq(depeche_mode)
        end

        context 'when calling #last' do

          it 'returns the last document, sorted by _id' do
            expect(context.send(method)).to eq(depeche_mode)
            expect(context.last).to eq(rolling_stones)
          end
        end
      end

      context 'when the criteria has a sort' do

        let(:criteria) do
          Band.desc(:name)
        end

        let(:context) do
          described_class.new(criteria)
        end

        it 'applies the criteria sort' do
          expect(context.send(method)).to eq(rolling_stones)
        end

        context 'when calling #last' do

          it 'applies the criteria sort' do
            expect(context.send(method)).to eq(rolling_stones)
            expect(context.last).to eq(depeche_mode)
          end
        end
      end

      context "when using .sort" do

        let(:criteria) do
          Band.all.sort(:name => -1).criteria
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when there is sort on the context" do

          it "follows the main sort" do
            expect(context.send(method)).to eq(rolling_stones)
          end
        end

        context "when subsequently calling #last" do

          it "returns the correct document" do
            expect(context.send(method)).to eq(rolling_stones)
            expect(context.last).to eq(depeche_mode)
          end
        end
      end

      context "when the query cache is enabled" do
        query_cache_enabled

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when first method was called before" do

          before do
            context.first
          end

          it "returns the first document without touching the database" do
            expect_no_queries do
              expect(context.send(method)).to eq(depeche_mode)
            end
          end
        end
      end

      context "when including a limit" do

        context "when the context is not cached" do

          let(:context) do
            described_class.new(criteria)
          end

          context "when the limit is 1" do
            let(:criteria) do
              Band.criteria
            end

            let(:docs) do
              context.send(method, 1)
            end

            it "returns an array of documents" do
              expect(docs).to eq([ depeche_mode ])
            end
          end

          context "when the limit is >1" do
            let(:criteria) do
              Band.criteria
            end

            let(:docs) do
              context.send(method, 2)
            end

            it "returns the number of documents in order" do
              expect(docs).to eq([ depeche_mode, new_order ])
            end
          end

          context 'when the criteria has a collation' do
            min_server_version '3.4'

            let(:criteria) do
              Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
            end

            it "returns the first matching document" do
              expect(context.send(method, 1)).to eq([ depeche_mode ])
            end
          end
        end

        context "when the query cache is enabled" do

          let(:context) do
            described_class.new(criteria)
          end

          context "when calling first beforehand" do
            query_cache_enabled

            let(:context) do
              described_class.new(criteria)
            end

            let(:criteria) do
              Band.all
            end

            before do
              context.first(before_limit)
            end

            let(:docs) do
              context.send(method, limit)
            end

            context "when getting all of the documents before" do
              let(:before_limit) { 3 }

              context "when getting all of the documents" do
                let(:limit) { 3 }

                it "returns all documents without touching the database" do
                  expect_no_queries do
                    expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                  end
                end
              end

              context "when getting fewer documents" do
                let(:limit) { 2 }

                it "returns the correct documents without touching the database" do
                  expect_no_queries do
                    expect(docs).to eq([ depeche_mode, new_order ])
                  end
                end
              end
            end

            context "when getting fewer documents before" do
              let(:before_limit) { 2 }

              context "when getting the same number of documents" do
                let(:limit) { 2 }

                it "returns the correct documents without touching the database" do
                  expect_no_queries do
                    expect(docs).to eq([ depeche_mode, new_order ])
                  end
                end
              end

              context "when getting more documents" do
                let(:limit) { 3 }

                it "returns the correct documents and touches the database" do
                  expect_query(1) do
                    expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                  end
                end
              end
            end

            context "when getting one document before" do
              let(:before_limit) { 1 }

              context "when getting one document" do
                let(:limit) { 1 }

                it "returns the correct documents without touching the database" do
                  expect_no_queries do
                    expect(docs).to eq([ depeche_mode ])
                  end
                end
              end

              context "when getting more than one document" do
                let(:limit) { 3 }

                it "returns the correct documents and touches the database" do
                  expect_query(1) do
                    expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                  end
                end
              end
            end
          end
        end
      end

      context "when calling #first then #last and the query cache is enabled" do
        query_cache_enabled

        let(:context) do
          described_class.new(criteria)
        end

        let(:criteria) do
          Band.all
        end

        before do
          context.first(before_limit)
        end

        let(:docs) do
          context.last(limit)
        end

        context "when getting one from the beginning and one from the end" do
          let(:before_limit) { 2 }
          let(:limit) { 1 }

          it "gets the correct document and hits the database" do
            expect_query(1) do
              expect(docs).to eq([rolling_stones])
            end
          end
        end
      end
    end
  end

  describe "#last" do
    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    context "when the context is not cached" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      it "returns the last matching document" do
        expect(context.last).to eq(depeche_mode)
      end

      context 'when the criteria has a collation' do
        min_server_version '3.4'

        let(:criteria) do
          Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
        end

        it "returns the last matching document" do
          expect(context.last).to eq(depeche_mode)
        end
      end
    end

    context "when using .desc" do

      let(:criteria) do
        Band.desc(:name)
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when there is sort on the context" do

        it "follows the main sort" do
          expect(context.last).to eq(depeche_mode)
        end
      end

      context "when subsequently calling #first" do

        it "returns the correct document" do
          expect(context.last).to eq(depeche_mode)
          expect(context.first).to eq(rolling_stones)
        end
      end
    end

    context 'when the criteria has no sort' do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      it 'applies a sort on _id' do
        expect(context.last).to eq(rolling_stones)
      end

      context 'when calling #first' do

        it 'returns the first document, sorted by _id' do
          expect(context.last).to eq(rolling_stones)
          expect(context.first).to eq(depeche_mode)
        end
      end
    end

    context 'when the criteria has a sort' do

      let(:criteria) do
        Band.desc(:name)
      end

      let(:context) do
        described_class.new(criteria)
      end


      it 'applies the criteria sort' do
        expect(context.last).to eq(depeche_mode)
      end

      context 'when calling #first' do

        it 'applies the criteria sort' do
          expect(context.last).to eq(depeche_mode)
          expect(context.first).to eq(rolling_stones)
        end
      end
    end

    context "when using .sort" do

      let(:criteria) do
        Band.all.sort(:name => -1).criteria
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when there is sort on the context" do

        it "follows the main sort" do
          expect(context.last).to eq(depeche_mode)
        end
      end

      context "when subsequently calling #first" do

        it "returns the correct document" do
          expect(context.last).to eq(depeche_mode)
          expect(context.first).to eq(rolling_stones)
        end
      end
    end

    context "when the query cache is enabled" do
      query_cache_enabled

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      context "when last method was called before" do

        before do
          context.last
        end

        it "returns the last document without touching the database" do
          expect_no_queries do
            expect(context.last).to eq(depeche_mode)
          end
        end
      end
    end

    context "when including a limit" do

      context "when the context is not cached" do

        let(:context) do
          described_class.new(criteria)
        end

        context "when the limit is 1" do
          let(:criteria) do
            Band.criteria
          end

          let(:docs) do
            context.last(1)
          end

          it "returns an array of documents" do
            expect(docs).to eq([ rolling_stones ])
          end
        end

        context "when the limit is >1" do
          let(:criteria) do
            Band.criteria
          end

          let(:docs) do
            context.last(2)
          end

          it "returns the number of documents in order" do
            expect(docs).to eq([ new_order, rolling_stones ])
          end
        end

        context 'when the criteria has a collation' do
          min_server_version '3.4'

          let(:criteria) do
            Band.where(name: "DEPECHE MODE").collation(locale: 'en_US', strength: 2)
          end

          it "returns the first matching document" do
            expect(context.last(1)).to eq([ depeche_mode ])
          end
        end
      end

      context "when the context is cached" do

        let(:context) do
          described_class.new(criteria)
        end

        context "when query cache is enabled" do
          query_cache_enabled

          let(:context) do
            described_class.new(criteria)
          end

          let(:criteria) do
            Band.all
          end

          before do
            context.last(before_limit)
          end

          let(:docs) do
            context.last(limit)
          end

          context "when getting all of the documents before" do
            let(:before_limit) { 3 }

            context "when getting all of the documents" do
              let(:limit) { 3 }

              it "returns all documents without touching the db" do
                expect_no_queries do
                  expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                end
              end
            end

            context "when getting fewer documents" do
              let(:limit) { 2 }

              it "returns the correct documents without touching the db" do
                expect_no_queries do
                  expect(docs).to eq([ new_order, rolling_stones ])
                end
              end
            end
          end

          context "when getting fewer documents before" do
            let(:before_limit) { 2 }

            context "when getting the same number of documents" do
              let(:limit) { 2 }

              it "returns the correct documents without touching the db" do
                expect_no_queries do
                  expect(docs).to eq([ new_order, rolling_stones ])
                end
              end
            end

            context "when getting more documents" do
              let(:limit) { 3 }

              it "returns the correct documents and touches the database" do
                expect_query(1) do
                  expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                end
              end
            end
          end

          context "when getting one document before" do
            let(:before_limit) { 1 }

            context "when getting one document" do
              let(:limit) { 1 }

              it "returns the correct documents without touching the database" do
                expect_no_queries do
                  expect(docs).to eq([ rolling_stones ])
                end
              end
            end

            context "when getting more than one document" do
              let(:limit) { 3 }

              it "returns the correct documents and touches the database" do
                expect_query(1) do
                  expect(docs).to eq([ depeche_mode, new_order, rolling_stones ])
                end
              end
            end
          end
        end
      end
    end

    context "when calling #last then #first and the query cache is enabled" do
      query_cache_enabled

      let(:context) do
        described_class.new(criteria)
      end

      let(:criteria) do
        Band.all
      end

      before do
        context.last(before_limit)
      end

      let(:docs) do
        context.first(limit)
      end

      context "when getting one from the beginning and one from the end" do
        let(:before_limit) { 2 }
        let(:limit) { 1 }

        it "hits the database" do
          expect_query(1) do
            docs
          end
        end

        it "gets the correct document" do
          expect(docs).to eq([ depeche_mode ])
        end
      end
    end
  end

  describe "#initialize" do

    let(:criteria) do
      Band.where(name: "Depeche Mode").no_timeout
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "sets the criteria" do
      expect(context.criteria).to eq(criteria)
    end

    it "sets the klass" do
      expect(context.klass).to eq(Band)
    end

    it "sets the view" do
      expect(context.view).to be_a(Mongo::Collection::View)
    end

    it "sets the view selector" do
      expect(context.view.selector).to eq({ "name" => "Depeche Mode" })
    end
  end

  [ :length, :size ].each do |method|

    describe "##{method}" do

      before do
        Band.create!(name: "Depeche Mode")
        Band.create!(name: "New Order")
      end

      context "when the criteria has a limit" do

        let(:criteria) do
          Band.limit(1)
        end

        let(:context) do
          described_class.new(criteria)
        end

        context "when broken_view_options is false" do
          driver_config_override :broken_view_options, false

          it "returns the number of documents that match" do
            expect(context.send(method)).to eq(1)
          end
        end

        context "when broken_view_options is true" do
          driver_config_override :broken_view_options, true

          it "returns the number of documents that match" do
            expect(context.send(method)).to eq(2)
          end
        end

        context "when calling more than once with different limits" do
          driver_config_override :broken_view_options, false

          it "does not cache the value" do
            expect(context.limit(1).send(method)).to eq(1)
            expect(context.limit(2).send(method)).to eq(2)
          end
        end
      end

      context "when the criteria has no limit" do

        let(:criteria) do
          Band.where(name: "Depeche Mode")
        end

        let(:context) do
          described_class.new(criteria)
        end

        it "returns the number of documents that match" do
          expect(context.send(method)).to eq(1)
        end

        context "when calling more than once with different skips" do
          driver_config_override :broken_view_options, false

          it "does not cache the value" do
            expect(context.skip(0).send(method)).to eq(1)
            expect(context.skip(1).send(method)).to eq(0)
          end
        end

        context "when the results have been iterated over" do

          before do
            context.entries
          end

          it "returns the cached value for all calls" do
            expect(context.view).to receive(:count_documents).once.and_return(1)
            expect(context.send(method)).to eq(1)
          end

          context "when the results have been iterated over multiple times" do

            before do
              context.entries
            end

            it "resets the length on each full iteration" do
              expect(context.size).to eq(1)
            end
          end
        end
      end
    end
  end

  describe "#limit" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      expect(context.limit(1).entries).to eq([ depeche_mode ])
    end
  end

  describe "#take" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "takes the correct number results" do
      expect(context.take(2)).to eq([ depeche_mode, new_order ])
    end

    it "returns an array when passing 1" do
      expect(context.take(1)).to eq([ depeche_mode ])
    end

    it "does not return an array when not passing an argument" do
      expect(context.take).to eq(depeche_mode)
    end

    it "returns all the documents taking more than whats in the db" do
      expect(context.take(5)).to eq([ depeche_mode, new_order, rolling_stones ])
    end
  end

  describe "#take!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "takes the first document" do
      expect(context.take!).to eq(depeche_mode)
    end

    context "when there are no documents" do
      it "raises an error" do
        expect do
          Person.take!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Person./)
      end
    end
  end

  describe "#map" do

    before do
      Band.create!(name: "Depeche Mode")
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when passed the symbol field name" do

      it "raises an error" do
        expect do
          context.map(:name)
        end.to raise_error(ArgumentError)
      end
    end

    context "when passed a block" do

      it "performs mapping" do
        expect(context.map(&:name)).to eq ["Depeche Mode", "New Order"]
      end
    end
  end

  describe "#map_reduce" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode", likes: 200)
    end

    let!(:tool) do
      Band.create!(name: "Tool", likes: 100)
    end

    let(:map) do
      %Q{
      function() {
        emit(this.name, { likes: this.likes });
      }}
    end

    let(:reduce) do
      %Q{
      function(key, values) {
        var result = { likes: 0 };
        values.forEach(function(value) {
          result.likes += value.likes;
        });
        return result;
      }}
    end

    let(:ordered_results) do
      results['results'].sort_by { |doc| doc['_id'] }
    end

    context "when no selection is provided" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the second aggregate result" do
        expect(results).to include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(2)
      end

      it "contains the entire raw results" do
        expect(ordered_results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end

      context 'when statistics are available' do
        max_server_version '4.2'

        it "contains the execution time" do
          expect(results.time).to_not be_nil
        end

        it "contains the count statistics" do
          expect(results["counts"]).to eq({
            "input" => 2, "emit" => 2, "reduce" => 0, "output" => 2
          })
        end

        it "contains the input count" do
          expect(results.input).to eq(2)
        end

        it "contains the emitted count" do
          expect(results.emitted).to eq(2)
        end

        it "contains the reduced count" do
          expect(results.reduced).to eq(0)
        end

        it "contains the output count" do
          expect(results.output).to eq(2)
        end
      end
    end

    context "when selection is provided" do

      let(:criteria) do
        Band.where(name: "Depeche Mode")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "includes the aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire raw results" do
        expect(ordered_results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end

      context 'when statistics are available' do
        max_server_version '4.2'

        it "contains the execution time" do
          expect(results.time).to_not be_nil
        end

        it "contains the count statistics" do
          expect(results["counts"]).to eq({
            "input" => 1, "emit" => 1, "reduce" => 0, "output" => 1
          })
        end

        it "contains the input count" do
          expect(results.input).to eq(1)
        end

        it "contains the emitted count" do
          expect(results.emitted).to eq(1)
        end

        it "contains the reduced count" do
          expect(results.reduced).to eq(0)
        end

        it "contains the output count" do
          expect(results.output).to eq(1)
        end
      end
    end

    context "when sorting is provided" do

      before do
        Band.index(name: -1)
        Band.create_indexes
      end

      let(:criteria) do
        Band.desc(:name)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        )
      end

      it "returns the second aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(2)
      end

      it "contains the entire raw results" do
        expect(ordered_results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }},
          { "_id" => "Tool", "value" => { "likes" => 100 }}
        ])
      end
    end

    context "when limiting is provided" do
      # map/reduce with limit is not supported on sharded clusters:
      # https://jira.mongodb.org/browse/SERVER-2099
      require_topology :single, :replica_set

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1)
      end

      it "returns the first aggregate result" do
        expect(results).to include(
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        )
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire raw results" do
        expect(results["results"]).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is replace" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(replace: "mr-output")
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is reduce" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(reduce: :mr_output)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output is merge" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce).out(merge: :mr_output)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
        ])
      end
    end

    context "when the output specifies a different db" do
      # Limit is not supported in sharded clusters
      require_topology :single, :replica_set

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      after do
        Band.with(database: 'another-db') do |b|
          b.all.delete
        end
      end

      context 'when db is a string' do

        let(:results) do
          context.map_reduce(map, reduce).out(merge: :mr_output, db: 'another-db')
        end

        it "returns the correct number of documents" do
          expect(results.count).to eq(1)
        end

        it "contains the entire results" do
          expect(results).to eq([
                                    { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
                                ])
        end

        it 'writes to the specified db' do
          expect(Band.mongo_client.with(database: 'another-db')[:mr_output].find.count).to eq(1)
        end
      end

      context 'when db is a symbol' do

        let(:results) do
          context.map_reduce(map, reduce).out(merge: :mr_output, 'db' => 'another-db')
        end

        it "returns the correct number of documents" do
          expect(results.count).to eq(1)
        end

        it "contains the entire results" do
          expect(results).to eq([
                                    { "_id" => "Depeche Mode", "value" => { "likes" => 200 }}
                                ])
        end

        it 'writes to the specified db' do
          expect(Band.mongo_client.with(database: 'another-db')[:mr_output].find.count).to eq(1)
        end
      end
    end

    context "when providing no output" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:results) do
        context.map_reduce(map, reduce)
      end

      it "raises an error" do
        expect {
          results.entries
        }.to raise_error(Mongoid::Errors::NoMapReduceOutput)
      end
    end

    context "when providing a finalize" do

      let(:criteria) do
        Band.limit(1)
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:finalize) do
        %Q{
        function(key, value) {
          value.extra = true;
          return value;
        }}
      end

      let(:results) do
        context.map_reduce(map, reduce).out(inline: 1).finalize(finalize)
      end

      it "returns the correct number of documents" do
        expect(results.count).to eq(1)
      end

      it "contains the entire results" do
        expect(results).to eq([
          { "_id" => "Depeche Mode", "value" => { "likes" => 200, "extra" => true }}
        ])
      end
    end
  end

  describe "#skip" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    it "limits the results" do
      expect(context.skip(1).entries).to eq([ new_order ])
    end
  end

  describe "#sort" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing a spec" do

      it "sorts the results" do
        expect(context.sort(name: -1).entries).to eq([ new_order, depeche_mode ])
      end

      it "returns the context" do
        expect(context.sort(name: 1)).to eq(context)
      end
    end

    context "when providing a block" do

      let(:sorted) do
        context.sort do |a, b|
          b.name <=> a.name
        end
      end

      it "sorts the results in memory" do
        expect(sorted).to eq([ new_order, depeche_mode ])
      end
    end
  end

  describe "#update" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when adding an element to a HABTM set" do

      let(:person) do
        Person.create!
      end

      let(:preference) do
        Preference.create!
      end

      before do
        Person.where(id: person.id).
          update("$addToSet" => { preference_ids: preference.id })
      end

      it "adds a single element to the array" do
        expect(person.reload.preference_ids).to eq([ preference.id ])
      end
    end

    context "when providing attributes" do

      context "when the attributes are of the correct type" do

        before do
          context.update(name: "Smiths")
        end

        it "updates only the first matching document" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "does not update the last matching document" do
          expect(new_order.reload.name).to eq("New Order")
        end
      end

      context "when the attributes must be mongoized" do

        context "when coercing a string to integer" do

          before do
            context.update(member_count: "1")
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "does not update the last matching document" do
            expect(new_order.reload.member_count).to be_nil
          end
        end

        context "when coercing a string to date" do

          before do
            context.update(founded: "1979/1/1")
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.founded).to eq(Date.new(1979, 1, 1))
          end

          it "does not update the last matching document" do
            expect(new_order.reload.founded).to be_nil
          end
        end
      end
    end

    context "when providing atomic operations" do

      context "when only atomic operations are provided" do

        context "when the attributes are in the correct type" do

          before do
            context.update("$set" => { name: "Smiths" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.name).to eq("Smiths")
          end

          it "does not update the last matching document" do
            expect(new_order.reload.name).to eq("New Order")
          end
        end

        context "when the attributes must be mongoized" do

          before do
            context.update("$set" => { member_count: "1" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "does not update the last matching document" do
            expect(new_order.reload.member_count).to be_nil
          end
        end
      end

      context "when a mix are provided" do

        before do
          context.update("$set" => { name: "Smiths" }, likes: 100)
        end

        it "updates the first matching document's set" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "updates the first matching document's updates" do
          expect(depeche_mode.reload.likes).to eq(100)
        end

        it "does not update the last matching document's set" do
          expect(new_order.reload.name).to eq("New Order")
        end

        it "does not update the last matching document's updates" do
          expect(new_order.reload.likes).to be_nil
        end
      end
    end

    context "when providing no attributes" do

      it "returns false" do
        expect(context.update).to be false
      end
    end

    context 'when provided array filters' do
      min_server_version '3.6'

      before do
        Band.delete_all
        b = Band.new(name: 'Depeche Mode')
        b.labels << Label.new(name: 'Warner')
        b.labels << Label.new(name: 'Sony')
        b.labels << Label.new(name: 'Cbs')
        b.save!

        b = Band.new(name: 'FKA Twigs')
        b.labels << Label.new(name: 'Warner')
        b.labels << Label.new(name: 'Cbs')
        b.save!
      end


      let(:criteria) do
        Band.where(name: 'Depeche Mode')
      end

      let!(:update) do
        context.update({ '$set' => { 'labels.$[i].name' => 'Sony' } },
                       array_filters: [{ 'i.name' => 'Cbs' }])
      end

      it 'applies the array filters' do
        expect(Band.where(name: 'Depeche Mode').first.labels.collect(&:name)).to match_array(['Warner', 'Sony', 'Sony'])
      end

      it 'does not affect other documents' do
        expect(Band.where(name: 'FKA Twigs').first.labels.collect(&:name)).to match_array(['Warner', 'Cbs'])
      end
    end
  end

  describe "#update_all" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode", origin: "Essex")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when providing attributes" do

      context "when the attributes are of the correct type" do

        before do
          context.update_all(name: "Smiths")
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "does not clear out other attributes" do
          expect(depeche_mode.reload.origin).to eq("Essex")
        end

        it "updates the last matching document" do
          expect(new_order.reload.name).to eq("Smiths")
        end
      end

      context "when the attributes must be mongoized" do

        before do
          context.update_all(member_count: "1")
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.member_count).to eq(1)
        end

        it "updates the last matching document" do
          expect(new_order.reload.member_count).to eq(1)
        end
      end

      context "when using aliased field names" do

        before do
          context.update_all(years: 100)
        end

        it "updates the first matching document" do
          expect(depeche_mode.reload.years).to eq(100)
        end

        it "updates the last matching document" do
          expect(new_order.reload.years).to eq(100)
        end
      end
    end

    context "when providing atomic operations" do

      context "when only atomic operations are provided" do

        context "when the attributes are in the correct type" do

          before do
            context.update_all("$set" => { name: "Smiths" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.name).to eq("Smiths")
          end

          it "updates the last matching document" do
            expect(new_order.reload.name).to eq("Smiths")
          end
        end

        context "when the attributes must be mongoized" do

          before do
            context.update_all("$set" => { member_count: "1" })
          end

          it "updates the first matching document" do
            expect(depeche_mode.reload.member_count).to eq(1)
          end

          it "updates the last matching document" do
            expect(new_order.reload.member_count).to eq(1)
          end
        end
      end

      context "when a mix are provided" do

        before do
          context.update_all("$set" => { name: "Smiths" }, likes: 100)
        end

        it "updates the first matching document's set" do
          expect(depeche_mode.reload.name).to eq("Smiths")
        end

        it "updates the first matching document's updates" do
          expect(depeche_mode.reload.likes).to eq(100)
        end

        it "updates the last matching document's set" do
          expect(new_order.reload.name).to eq("Smiths")
        end

        it "updates the last matching document's updates" do
          expect(new_order.reload.likes).to eq(100)
        end
      end
    end

    context "when providing no attributes" do

      it "returns false" do
        expect(context.update_all).to be false
      end
    end

    context 'when provided array filters' do
      min_server_version '3.6'

      before do
        Band.delete_all
        b = Band.new(name: 'Depeche Mode')
        b.labels << Label.new(name: 'Warner')
        b.labels << Label.new(name: 'Sony')
        b.labels << Label.new(name: 'Cbs')
        b.save!

        b = Band.new(name: 'FKA Twigs')
        b.labels << Label.new(name: 'Warner')
        b.labels << Label.new(name: 'Cbs')
        b.save!
      end


      let(:criteria) do
        Band.all
      end

      let!(:update) do
        context.update_all({ '$set' => { 'labels.$[i].name' => 'Sony' } },
                       array_filters: [{ 'i.name' => 'Cbs' }])
      end

      it 'applies the array filters' do
        expect(Band.where(name: 'Depeche Mode').first.labels.collect(&:name)).to match_array(['Warner', 'Sony', 'Sony'])
      end

      it 'updates all documents' do
        expect(Band.where(name: 'FKA Twigs').first.labels.collect(&:name)).to match_array(['Warner', 'Sony'])
      end
    end
  end

  describe '#pipeline' do

    context 'when the criteria has a selector' do

      before do
        Artist.index(name: "text")
        Artist.create_indexes
      end

      let(:criteria) do
        Artist.text_search("New Order")
      end

      let(:context) do
        described_class.new(criteria)
      end

      let(:pipeline_match) do
        context.send(:pipeline, :some_field).first['$match']
      end

      it 'creates a pipeline with the selector as one of the $match criteria' do
        expect(pipeline_match).to include({ '$text' => { '$search' => "New Order" } })
      end

      it 'creates a pipeline with the $exists operator as one of the $match criteria' do
        expect(pipeline_match).to include({ 'some_field' => { '$exists' => true } })
      end
    end
  end

  describe "#first!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the first document" do
        expect(context.first!).to eq(depeche_mode)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the first document" do
        expect(context.sort(name: 1).first!).to eq(death_cab)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.first!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#last!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the last document" do
        expect(context.last!).to eq(death_cab)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the last document" do
        expect(context.sort(name: 1).last!).to eq(rolling_stones)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.last!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#second" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second document" do
        expect(context.second).to eq(new_order)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second document" do
        expect(context.sort(name: 1).second).to eq(depeche_mode)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.second).to be_nil
      end
    end
  end

  describe "#second!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second document" do
        expect(context.second!).to eq(new_order)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second document" do
        expect(context.sort(name: 1).second!).to eq(depeche_mode)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.second!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#third" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third document" do
        expect(context.third).to eq(rolling_stones)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third document" do
        expect(context.sort(name: 1).third).to eq(new_order)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.third).to be_nil
      end
    end
  end

  describe "#third!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third document" do
        expect(context.third!).to eq(rolling_stones)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third document" do
        expect(context.sort(name: 1).third!).to eq(new_order)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.third!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#fourth" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fourth document" do
        expect(context.fourth).to eq(death_cab)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fourth document" do
        expect(context.sort(name: 1).fourth).to eq(rolling_stones)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.fourth).to be_nil
      end
    end
  end

  describe "#fourth!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fourth document" do
        expect(context.fourth!).to eq(death_cab)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fourth document" do
        expect(context.sort(name: 1).fourth!).to eq(rolling_stones)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.fourth!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#fifth" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let!(:guns_and_roses) do
      Band.create!(name: "Guns and Roses")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fifth document" do
        expect(context.fifth).to eq(guns_and_roses)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fifth document" do
        expect(context.sort(name: 1).fifth).to eq(rolling_stones)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.fifth).to be_nil
      end
    end
  end

  describe "#fifth!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let!(:guns_and_roses) do
      Band.create!(name: "Guns and Roses")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fifth document" do
        expect(context.fifth!).to eq(guns_and_roses)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the fifth document" do
        expect(context.sort(name: 1).fifth!).to eq(rolling_stones)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.fifth!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#second_to_last" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second_to_last document" do
        expect(context.second_to_last).to eq(rolling_stones)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second_to_last document" do
        expect(context.sort(name: 1).second_to_last).to eq(new_order)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.second_to_last).to be_nil
      end
    end
  end

  describe "#second_to_last!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second_to_last document" do
        expect(context.second_to_last!).to eq(rolling_stones)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the second_to_last document" do
        expect(context.sort(name: 1).second_to_last!).to eq(new_order)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.second_to_last!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe "#third_to_last" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third_to_last document" do
        expect(context.third_to_last).to eq(new_order)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third_to_last document" do
        expect(context.sort(name: 1).third_to_last).to eq(depeche_mode)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "returns nil" do
        expect(context.third_to_last).to be_nil
      end
    end
  end

  describe "#third_to_last!" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create!(name: "New Order")
    end

    let!(:rolling_stones) do
      Band.create!(name: "The Rolling Stones")
    end

    let!(:death_cab) do
      Band.create!(name: "Death Cab For Cutie")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context "when there's no sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third_to_last document" do
        expect(context.third_to_last!).to eq(new_order)
      end
    end

    context "when there's a custom sort" do
      let(:criteria) do
        Band.all
      end

      it "gets the third_to_last document" do
        expect(context.sort(name: 1).third_to_last!).to eq(depeche_mode)
      end
    end

    context "when there are no documents" do
      let(:criteria) do
        Band.where(name: "bogus")
      end

      it "raises an error" do
        expect do
          context.third_to_last!
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Could not find a document of class Band./)
      end
    end
  end

  describe '#load_async' do
    let!(:band) do
      Band.create!(name: "Depeche Mode")
    end

    let(:criteria) do
      Band.where(name: "Depeche Mode")
    end

    let(:context) do
      described_class.new(criteria)
    end

    context 'with global thread pool async query executor' do
      config_override :async_query_executor, :global_thread_pool

      it 'preloads the documents' do
        context.load_async
        context.documents_loader.wait

        expect(context.view).not_to receive(:map)
        expect(context.to_a).to eq([band])
      end

      it 're-raises exception during preload' do
        expect_any_instance_of(Mongoid::Contextual::Mongo::DocumentsLoader)
          .to receive(:execute)
          .at_least(:once)
          .and_raise(Mongo::Error::OperationFailure)

        context.load_async
        context.documents_loader.wait

        expect do
          context.to_a
        end.to raise_error(Mongo::Error::OperationFailure)
      end
    end

    context 'with immediate thread pool async query executor' do
      config_override :async_query_executor, :immediate

      it 'preloads the documents' do
        context.load_async
        context.documents_loader.wait

        expect(context.view).not_to receive(:map)
        expect(context.to_a).to eq([band])
      end

      it 're-raises exception during preload' do
        expect_any_instance_of(Mongoid::Contextual::Mongo::DocumentsLoader)
          .to receive(:execute)
          .at_least(:once)
          .and_raise(Mongo::Error::OperationFailure)

        context.load_async
        context.documents_loader.wait

        expect do
          context.to_a
        end.to raise_error(Mongo::Error::OperationFailure)
      end
    end
  end
end
