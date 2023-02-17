# frozen_string_literal: true

require "spec_helper"
require "support/immutable_ids"

describe Mongoid::Persistable::Updatable do
  extend Mongoid::ImmutableIds
  immutable_id_examples_as "persisted _ids are immutable"

  describe "#update_attribute" do

    context "when the field is aliased" do

      let(:person) do
        Person.create!
      end

      context "when the setter is overridden" do

        before do
          person.update_attribute(:overridden_setter, "value")
        end

        it "updates the field" do
          expect(person.overridden_setter).to eq("value")
        end

        it "clears the dirty attributes" do
          expect(person).to_not be_changed
        end

        it "calls the overridden setter" do
          expect(person.instance_variable_get(:@override_called)).to be true
        end

        it "persists the changes" do
          expect(person.reload.overridden_setter).to eq("value")
        end
      end

      context "when setting via the field name" do

        before do
          person.update_attribute(:t, "testing")
        end

        it "updates the field" do
          expect(person.t).to eq("testing")
        end

        it "persists the changes" do
          expect(person.reload.t).to eq("testing")
        end
      end

      context "when setting via the field alias" do

        before do
          person.update_attribute(:test, "testing")
        end

        it "updates the field" do
          expect(person.t).to eq("testing")
        end

        it "persists the changes" do
          expect(person.reload.t).to eq("testing")
        end
      end
    end

    context "when setting an array field" do

      let(:person) do
        Person.create!(aliases: [])
      end

      before do
        person.update_attribute(:aliases, person.aliases << "Bond")
      end

      it "sets the new value in the document" do
        expect(person.aliases).to eq([ "Bond" ])
      end

      it "persists the changes" do
        expect(person.reload.aliases).to eq([ "Bond" ])
      end
    end

    context "when setting a boolean field" do

      context "when the field is true" do

        let(:person) do
          Person.new(terms: true)
        end

        context "when setting to false" do

          before do
            person.update_attribute(:terms, false)
          end

          it "persists the document" do
            expect(person).to be_persisted
          end

          it "changes the attribute value" do
            expect(person.terms).to be false
          end

          it "persists the changes" do
            expect(person.reload.terms).to be false
          end
        end
      end
    end

    context "when dynamic attributes are not enabled" do

      it "raises exception for an unknown attribute " do
        account = Account.create!(name: 'Foobar')

        expect {
          account.update_attribute(:somethingnew, "somethingnew")
        }.to raise_error(Mongoid::Errors::UnknownAttribute)
      end

      it "will update value of aliased field" do
        person = Person.create!
        person.update_attribute(:t, "test_value")
        expect(person.reload.t).to eq "test_value"
        expect(person.test).to eq "test_value"
      end
    end

    context "when provided a symbol attribute name" do

      let(:post) do
        Post.new
      end

      context "when the document is valid" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "sets the attribute" do
          expect(post.title).to eq("Testing")
        end

        it "saves the document" do
          expect(post).to be_persisted
        end
      end

      context "when updating to the same value" do

        before do
          post.update_attribute(:title, "Testing")
        end

        it "returns true" do
          expect(post.update_attribute(:title, "Testing")).to be true
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute(:title, "$invalid")
        end

        it "sets the attribute" do
          expect(post.title).to eq("$invalid")
        end

        it "saves the document" do
          expect(post).to be_persisted
        end
      end

      context "when the document has been destroyed" do

        before do
          post.delete
        end

        it "raises an error" do
          expect {
            post.update_attribute(:title, "something")
          }.to raise_error(RuntimeError)
        end
      end
    end

    context "when provided a string attribute name" do

      let(:post) do
        Post.new
      end

      context "when the document is valid" do

        before do
          post.update_attribute("title", "Testing")
        end

        it "sets the attribute" do
          expect(post.title).to eq("Testing")
        end

        it "saves the document" do
          expect(post).to be_persisted
        end
      end

      context "when the document is invalid" do

        before do
          post.update_attribute("title", "$invalid")
        end

        it "sets the attribute" do
          expect(post.title).to eq("$invalid")
        end

        it "saves the document" do
          expect(post).to be_persisted
        end
      end
    end

    context "when persisting a localized field" do
      with_default_i18n_configs

      let!(:product) do
        Product.create!(description: "The bomb")
      end

      before do
        ::I18n.locale = :de
        product.update_attribute(:description, "Die Bombe")
      end

      let(:attributes) do
        product.attributes["description"]
      end

      it "persists the en locale" do
        expect(attributes["en"]).to eq("The bomb")
      end

      it "persists the de locale" do
        expect(attributes["de"]).to eq("Die Bombe")
      end
    end

    context "when updating a deeply embedded document" do

      let!(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(street: "Winterfeldtstr")
      end

      let!(:location) do
        address.locations.create!(name: "work")
      end

      let(:from_db) do
        Person.last.addresses.last.locations.last
      end

      before do
        from_db.update_attribute(:name, "home")
      end

      it "updates the attribute" do
        expect(from_db.name).to eq("home")
      end

      it "persists the changes" do
        expect(from_db.reload.name).to eq("home")
      end
    end

    context 'when the field is read-only' do

      before do
        Person.attr_readonly :species
      end

      after do
        Person.readonly_attributes.reject! { |a| a.to_s == 'species' }
      end

      let(:person) do
        Person.create!(species: :human)
      end

      it 'raises an error when trying to set the attribute' do
        expect {
          person.update_attribute(:species, :reptile)
        }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
      end

      context 'when referring to the attribute with a string' do

        it 'raises an error when trying to set the attribute' do
          expect {
            person.update_attribute('species', :reptile)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end
      end

      context 'when the field is aliased' do

        before do
          Person.attr_readonly :at
        end

        after do
          Person.readonly_attributes.reject! { |a| a.to_s == 'at' }
        end

        it 'raises an error when trying to set the attribute using the db name' do
          expect {
            person.update_attribute(:at, Time.now)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end

        it 'raises an error when trying to set the attribute using the aliased name' do
          expect {
            person.update_attribute(:aliased_timestamp, Time.now)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end
      end
    end

    context 'when the field is loaded explicitly' do

      before do
        Person.create!(title: 'Captain')
      end

      context 'when the loaded attribute is updated' do

        let(:person) do
          Person.only(:title).first.tap do |_person|
            _person.update_attribute(:title, 'Esteemed')
          end
        end

        it 'allows the field to be updated' do
          expect(person.title).to eq('Esteemed')
        end

        it 'persists the updated field' do
          expect(person.reload.title).to eq('Esteemed')
        end
      end

      context 'when the an attribute other than the loaded one is updated' do

        let(:person) do
          Person.only(:title).first
        end

        it 'does not allow the field to be updated' do
          expect {
            person.update_attribute(:age, 20)
          }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
        end

        it 'does not persist the change' do
          expect(person.reload.age).to eq(100)
        end

        context 'when referring to the attribute with a string' do

          it 'does not allow the field to be updated' do
            expect {
              person.update_attribute('age', 20)
            }.to raise_exception(Mongoid::Errors::ReadonlyAttribute)
          end

          it 'does not persist the change' do
            expect(person.reload.age).to eq(100)
          end
        end
      end
    end

    context 'when fields are explicitly not loaded' do

      before do
        Person.create!(title: 'Captain')
      end

      context 'when the loaded attribute is updated' do

        let(:person) do
          Person.without(:age).first.tap do |_person|
            _person.update_attribute(:title, 'Esteemed')
          end
        end

        it 'allows the field to be updated' do
          expect(person.title).to eq('Esteemed')
        end

        it 'persists the updated field' do
          expect(person.reload.title).to eq('Esteemed')
        end
      end

      context 'when the non-loaded attribute is updated' do

        let(:person) do
          Person.without(:title).first
        end

        it 'does not allow the field to be updated' do
          expect {
            person.update_attribute(:title, 'Esteemed')
          }.to raise_exception(ActiveModel::MissingAttributeError)
        end

        it 'does not persist the change' do
          expect(person.reload.title).to eq('Captain')
        end

        context 'when referring to the attribute with a string' do

          it 'does not allow the field to be updated' do
            expect {
              person.update_attribute('title', 'Esteemed')
            }.to raise_exception(ActiveModel::MissingAttributeError)
          end

          it 'does not persist the change' do
            expect(person.reload.title).to eq('Captain')
          end
        end
      end
    end

    context 'when the field is _id' do
      def invoke_operation!
        object.update_attribute "_id", new_id_value
      end

      it_behaves_like "persisted _ids are immutable"
    end
  end

  [:update_attributes, :update].each do |method|

    describe "##{method}" do

      context "when saving with a hash field with invalid keys" do
        max_server_version '4.9'

        let(:person) do
          Person.create!
        end

        it "raises an error" do
          expect {
            person.update_attributes!(map: { "$bad.key" => "value" })
          }.to raise_error(Mongo::Error::OperationFailure)
        end
      end

      context "when the document has been destroyed" do
        max_server_version '4.9'

        let(:person) do
          Person.create!
        end

        it "raises an error" do
          expect {
            person.send(method, map: { "$bad.key" => "value" })
          }.to raise_error(Mongo::Error::OperationFailure)
        end
      end

      context "when validation passes" do

        let(:person) do
          Person.create!
        end

        let!(:saved) do
          person.send(method, pets: false)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "returns true" do
          expect(saved).to be true
        end

        it "saves the attributes" do
          expect(from_db.pets).to be false
        end
      end

      context "when the document has been destroyed" do

        let!(:person) do
          Person.create!
        end

        before do
          person.delete
        end

        it "raises an error" do
          expect {
            person.send(method, title: "something")
          }.to raise_error(RuntimeError)
        end
      end

      context "when updating through a one-to-one relation" do

        let(:person) do
          Person.create!
        end

        let(:game) do
          Game.create!(person: person)
        end

        before do
          person.send(method, ssn: "444-44-4444")
          game.person.send(method, ssn: "555-66-7777")
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it "saves the attributes" do
          expect(person.ssn).to eq("555-66-7777")
        end
      end

      context "on a new record" do

        let(:person) do
          Person.new
        end

        before do
          person.send(method, pets: false, title: nil)
        end

        it "saves the new record" do
          expect(Person.find(person.id)).to_not be_nil
        end
      end

      context "when passing in a relation" do

        context "when providing an embedded child" do

          let!(:person) do
            Person.create!
          end

          let!(:name) do
            person.create_name(first_name: "test", last_name: "user")
          end

          let(:new_name) do
            Name.new(first_name: "Rupert", last_name: "Parkes")
          end

          before do
            person.send(method, name: new_name)
          end

          it "updates the embedded document" do
            expect(person.name).to eq(new_name)
          end

          it "persists the changes" do
            expect(person.reload.name).to eq(new_name)
          end
        end

        context "when providing a parent to a referenced in" do

          let!(:person) do
            Person.create!
          end

          let!(:post) do
            Post.create!(title: "Testing")
          end

          context "when the relation has not yet been touched" do

            before do
              post.send(method, person: person)
            end

            it "sets the instance of the relation" do
              expect(person.posts).to eq([ post ])
            end

            it "sets properly through method_missing" do
              expect(person.posts.to_a).to eq([ post ])
            end

            it "persists the reference" do
              expect(person.posts(true)).to eq([ post ])
            end
          end

          context "when the relation has been touched" do

            before do
              person.posts
              post.send(method, person: person)
            end

            it "sets the instance of the relation" do
              expect(person.posts).to eq([ post ])
            end

            it "sets properly through method_missing" do
              expect(person.posts.to_a).to eq([ post ])
            end

            it "persists the reference" do
              expect(person.posts(true)).to eq([ post ])
            end
          end
        end
      end

      context "when in a deeply nested hierarchy" do

        let!(:person) do
          Person.new(title: "The Boss")
        end

        let!(:phone_number) do
          Phone.new(number: "123-456-7890")
        end

        let!(:country_code) do
          CountryCode.new(code: 1)
        end

        before do
          phone_number.country_code = country_code
          person.phone_numbers << phone_number
          person.save!
        end

        it "sets the first level document" do
          expect(person.phone_numbers.first).to eq(phone_number)
        end

        it "sets the second level document" do
          expect(person.phone_numbers.first.country_code).to eq(country_code)
        end

        context "when updating the first level document" do

          let(:phone) do
            person.phone_numbers.first
          end

          before do
            phone.number = "098-765-4321"
            phone.send(method, number: "098-765-4321")
          end

          it "sets the new attributes" do
            expect(phone.number).to eq("098-765-4321")
          end

          context "when reloading the root" do

            let(:reloaded) do
              person.reload
            end

            it "saves the new attributes" do
              expect(reloaded.phone_numbers.first.number).to eq("098-765-4321")
            end
          end
        end
      end

      context 'when the _id is one of the fields' do
        def invoke_operation!
          object.update_attributes _id: new_id_value
        end
  
        it_behaves_like "persisted _ids are immutable"
      end
    end
  end

  describe "#update!" do

    context "when a callback aborts the callback chain" do

      let(:oscar) do
        Oscar.new
      end

      it "raises a callback error" do
        expect {
          oscar.update!(title: "The Grouch")
        }.to raise_error(Mongoid::Errors::Callback)
      end
    end
  end

  describe "#update_attributes!" do

    let(:person) do
      Person.create!
    end

    let(:attributes) do
      { security_code: 'secret' }
    end

    it 'calls update_attributes' do
      person.should receive(:update_attributes).with(attributes).and_call_original
      lambda do
        person.update_attributes!(attributes)
      end.should_not raise_error
    end
  end
end
