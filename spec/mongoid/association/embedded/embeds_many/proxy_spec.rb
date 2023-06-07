# frozen_string_literal: true

require "spec_helper"
require_relative '../embeds_many_models.rb'

describe Mongoid::Association::Embedded::EmbedsMany::Proxy do

  [ :<<, :push ].each do |method|

    describe "##{method}" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:address) do
          Address.new
        end

        let!(:added) do
          person.addresses.send(method, address)
        end

        it "appends to the target" do
          expect(person.addresses).to eq([ address ])
        end

        it "sets the base on the inverse relation" do
          expect(address.addressable).to eq(person)
        end

        it "sets the same instance on the inverse relation" do
          expect(address.addressable).to eql(person)
        end

        it "does not save the new document" do
          expect(address).to_not be_persisted
        end

        it "sets the parent on the child" do
          expect(address._parent).to eq(person)
        end

        it "sets the association metadata on the child" do
          expect(address._association).to_not be_nil
        end

        it "sets the index on the child" do
          expect(address._index).to eq(0)
        end

        it "returns the relation" do
          expect(added).to eq(person.addresses)
        end

        context 'when the child is already related to the parent' do

          let(:message) do
            Message.new(person: person)
          end

          before do
            person.messages << message
          end

          it "appends only once to the target" do
            expect(person.messages).to eq([ message ])
          end
        end

        context "with a limiting default scope" do

          context "when the document matches the scope" do

            let(:active) do
              Appointment.new
            end

            before do
              person.appointments.send(method, active)
            end

            it "appends to the target" do
              expect(person.appointments._target).to eq([ active ])
            end

            it "appends to the _unscoped" do
              expect(person.appointments.send(:_unscoped)).to eq([ active ])
            end
          end

          context "when the document does not match the scope" do

            let(:inactive) do
              Appointment.new(active: false)
            end

            before do
              person.appointments.send(method, inactive)
            end

            it "doesn't append to the target" do
              expect(person.appointments._target).to_not eq([ inactive ])
            end

            it "appends to the _unscoped" do
              expect(person.appointments.send(:_unscoped)).to eq([ inactive ])
            end
          end
        end
      end

      context "when the parent is not a new record" do

        let(:person) do
          Person.create!
        end

        let(:address) do
          Address.new
        end

        before do
          person.addresses.send(method, address)
        end

        it "saves the new document" do
          expect(address).to be_persisted
        end
      end

      context "when appending more than one document at once" do

        let(:person) do
          Person.create!
        end

        let(:address_one) do
          Address.new
        end

        let(:address_two) do
          Address.new
        end

        let!(:added) do
          person.addresses.send(method, [ address_one, address_two ])
        end

        it "saves the first document" do
          expect(address_one).to be_persisted
        end

        it "saves the second document" do
          expect(address_two).to be_persisted
        end

        it "returns the relation" do
          expect(added).to eq(person.addresses)
        end
      end

      context "when the parent and child have a cyclic relation" do

        context "when the parent is a new record" do

          let(:parent_role) do
            Role.new
          end

          let(:child_role) do
            Role.new
          end

          before do
            parent_role.child_roles.send(method, child_role)
          end

          it "appends to the target" do
            expect(parent_role.child_roles).to eq([ child_role ])
          end

          it "sets the base on the inverse relation" do
            expect(child_role.parent_role).to eq(parent_role)
          end

          it "sets the same instance on the inverse relation" do
            expect(child_role.parent_role).to eql(parent_role)
          end

          it "does not save the new document" do
            expect(child_role).to_not be_persisted
          end

          it "sets the parent on the child" do
            expect(child_role._parent).to eq(parent_role)
          end

          it "sets the association metadata on the child" do
            expect(child_role._association).to_not be_nil
          end

          it "sets the index on the child" do
            expect(child_role._index).to eq(0)
          end
        end

        context "when the parent is not a new record" do

          let(:parent_role) do
            Role.create!(name: "CEO")
          end

          let(:child_role) do
            Role.new(name: "COO")
          end

          before do
            parent_role.child_roles.send(method, child_role)
          end

          it "saves the new document" do
            expect(child_role).to be_persisted
          end
        end
      end

      context "when the child has one sided many to many relation" do
        let(:person) do
          Person.create!
        end

        let(:message) do
          Message.new
        end

        context "assign parent first" do
          before do
            message.person = person
            message.receivers.send(method, person)
          end

          it "appends to the relation array" do
            expect(message.receivers).to include(person)
          end
        end

        context "not assign parent" do
          before do
            message.receivers.send(method, person)
          end

          it "appends to the relation array" do
            expect(message.receivers).to include(person)
          end
        end
      end
    end
  end

  describe "#=" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses = [ address ]
      end

      it "sets the target of the relation" do
        expect(person.addresses).to eq([ address ])
      end

      it "sets the _unscoped of the relation" do
        expect(person.addresses.send(:_unscoped)).to eq([ address ])
      end

      it "sets the base on the inverse relation" do
        expect(address.addressable).to eq(person)
      end

      it "sets the same instance on the inverse relation" do
        expect(address.addressable).to eql(person)
      end

      it "does not save the target" do
        expect(address).to_not be_persisted
      end

      it "sets the parent on the child" do
        expect(address._parent).to eq(person)
      end

      it "sets the association metadata on the child" do
        expect(address._association).to_not be_nil
      end

      it "sets the index on the child" do
        expect(address._index).to eq(0)
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create!
      end

      let(:address) do
        Address.new
      end

      context "when setting directly" do

        before do
          person.addresses = [ address ]
        end

        it "saves the target" do
          expect(address).to be_persisted
        end
      end

      context "when setting via an overridden method from the parent" do

        let!(:person) do
          Person.create!
        end

        let!(:address) do
          person.addresses.create!(street: "Alt Treptow")
        end

        let!(:new_address) do
          Address.new(street: "Tempelhofer Damm")
        end

        before do
          person.update_attributes!(set_addresses: [ new_address ])
        end

        it "overwrites the existing addresses" do
          expect(person.reload.addresses).to eq([ new_address ])
        end
      end

      context "when setting via the parent attributes" do

        before do
          person.attributes = { addresses: [ address ] }
        end

        it "sets the relation" do
          expect(person.addresses).to eq([ address ])
        end

        it "does not save the target" do
          expect(address).to_not be_persisted
        end

        context "when setting the relation multiple times" do

          let(:address_two) do
            Address.new(street: "kudamm")
          end

          before do
            person.addresses = [ address_two ]
            person.save!
          end

          it "sets the new documents" do
            expect(person.addresses).to eq([ address_two ])
          end

          it "persits only the new documents" do
            expect(person.reload.addresses).to eq([ address_two ])
          end
        end
      end
    end

    context "when setting for inherited docs" do

      context "when the parent collection is already accessed" do

        before do
          Person.collection
        end

        context "when setting via the subclass" do

          let(:doctor) do
            Doctor.new
          end

          let(:address_one) do
            Address.new(street: "tauentzien")
          end

          before do
            doctor.addresses = [ address_one ]
            doctor.save!
          end

          it "sets the documents" do
            expect(doctor.addresses).to eq([ address_one ])
          end

          it "persists the document" do
            expect(doctor.reload.addresses).to eq([ address_one ])
          end

          context "when setting the relation multiple times" do

            let(:address_two) do
              Address.new(street: "kudamm")
            end

            before do
              doctor.addresses = [ address_two ]
              doctor.save!
            end

            it "sets the new documents" do
              expect(doctor.addresses).to eq([ address_two ])
            end

            it "persits only the new documents" do
              expect(doctor.reload.addresses).to eq([ address_two ])
            end
          end
        end
      end
    end

    context "when replacing an existing relation" do

      let(:person) do
        Person.create!(addresses: addresses)
      end

      let(:addresses) do
        [
            Address.new(street: "1st St"),
            Address.new(street: "2nd St")
        ]
      end

      let(:address) do
        Address.new(street: "3rd St")
      end

      context "when the replaced relation is different from the existing relation" do

        before do
          person.addresses = [ address ]
        end

        it "deletes the old documents" do
          expect(person.reload.addresses).to eq([ address ])
        end
      end

      context "when the replaced relation is identical to the existing relation" do

        before do
          person.addresses = addresses
        end

        it "does nothing" do
          expect(person.reload.addresses).to eq(addresses)
        end
      end
    end

    context "when the relation has an unusual name" do

      module MyCompany
        module Model
          class TrackingId
            include Mongoid::Document
            include Mongoid::Timestamps
            store_in collection: "tracking_ids"
            embeds_many \
              :validation_history,
              class_name: "MyCompany::Model::TrackingIdValidationHistory"
          end

          class TrackingIdValidationHistory
            include Mongoid::Document
            field :old_state, type: String
            field :new_state, type: String
            field :when_changed, type: DateTime
            embedded_in :tracking_id, class_name: "MyCompany::Model::TrackingId"
          end
        end
      end

      let(:tracking_id) do
        MyCompany::Model::TrackingId.create!
      end

      let(:history) do
        MyCompany::Model::TrackingIdValidationHistory.new(old_state: "Test")
      end

      before do
        tracking_id.validation_history << history
      end

      it "allows creation of the embedded document" do
        expect(tracking_id.validation_history.size).to eq(1)
      end

      it "saves the relation" do
        expect(history).to be_persisted
      end

      it "remains on reload" do
        expect(tracking_id.reload.validation_history.size).to eq(1)
      end
    end

    context "when the relation has address in the name" do

      let(:slave) do
        Slave.new(first_name: "Test")
      end

      before do
        ActiveSupport::Inflector.inflections do |inflect|
          inflect.singular("address_numbers", "address_number")
        end
        slave.address_numbers << AddressNumber.new(country_code: 1)
        slave.save!
      end

      it "requires an inflection to determine the class" do
        expect(slave.reload.address_numbers.size).to eq(1)
      end
    end

    context "when setting the entire tree via a hash" do

      let(:person) do
        Person.create!
      end

      let!(:address_one) do
        person.addresses.create!(street: "Tauentzienstr")
      end

      let!(:address_two) do
        person.addresses.create!(street: "Kudamm")
      end

      let(:attributes) do
        person.as_document.dup
      end

      context "when the attributes have changed" do

        before do
          attributes["addresses"][0]["city"] = "Berlin"
          person.update_attributes!(attributes)
        end

        it "sets the new attributes" do
          expect(person.addresses.first.city).to eq("Berlin")
        end

        it "persists the changes" do
          expect(person.reload.addresses.first.city).to eq("Berlin")
        end
      end
    end

    context "when setting an embedded sub-document tree via a hash" do

      let(:person) do
        Person.create!
      end

      let!(:address_one) do
        person.addresses.create!(street: "Tauentzienstr")
      end

      let!(:location_one) do
        person.addresses.first.locations.create!(name: "Work")
      end

      let(:attributes) do
        person.addresses.first.as_document.dup
      end

      context "when the attributes have changed" do

        before do
          attributes["city"] = "Berlin"
          attributes["locations"][0]["name"] = "Home"
          person.addresses.first.update_attributes!(attributes)
        end

        it "sets the new attributes on the address" do
          expect(person.addresses.first.city).to eq("Berlin")
        end

        it "sets the new attributes on the location" do
          expect(person.addresses.first.locations.first.name).to eq("Home")
        end

        it "persists the changes to the address" do
          expect(person.reload.addresses.first.city).to eq("Berlin")
        end

        it "persists the changes to the location" do
          expect(person.reload.addresses.first.locations.first.name).to eq("Home")
        end

        it "does not persist the locations collection to the person document" do
          expect(person.reload[:locations]).to be_nil
        end
      end
    end

    context "when the parent and child have a cyclic relation" do

      context "when the parent is a new record" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
        end

        it "sets the target of the relation" do
          expect(parent_role.child_roles).to eq([ child_role ])
        end

        it "sets the base on the inverse relation" do
          expect(child_role.parent_role).to eq(parent_role)
        end

        it "sets the same instance on the inverse relation" do
          expect(child_role.parent_role).to eql(parent_role)
        end

        it "does not save the target" do
          expect(child_role).to_not be_persisted
        end

        it "sets the parent on the child" do
          expect(child_role._parent).to eq(parent_role)
        end

        it "sets the association metadata on the child" do
          expect(child_role._association).to_not be_nil
        end

        it "sets the index on the child" do
          expect(child_role._index).to eq(0)
        end
      end

      context "when the parent is not a new record" do

        let(:parent_role) do
          Role.create!(name: "CTO")
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
        end

        it "saves the target" do
          expect(child_role).to be_persisted
        end
      end
    end
  end

  describe "#= nil" do

    context "when the relationship is polymorphic" do

      context "when the parent is a new record" do

        let(:person) do
          Person.new
        end

        let(:address) do
          Address.new
        end

        before do
          person.addresses = [ address ]
          person.addresses = nil
        end

        it "sets the relation to empty" do
          expect(person.addresses).to be_empty
        end

        it "sets the unscoped to empty" do
          expect(person.addresses.send(:_unscoped)).to be_empty
        end

        it "removes the inverse relation" do
          expect(address.addressable).to be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:person) do
          Person.new
        end

        before do
          person.addresses = nil
        end

        it "sets the relation to empty" do
          expect(person.addresses).to be_empty
        end
      end

      context "when the parent is persisted" do

        let(:person) do
          Person.create!
        end

        let(:address) do
          Address.new
        end

        context "when setting directly" do

          before do
            person.addresses = [ address ]
            person.addresses = nil
          end

          it "sets the relation to empty" do
            expect(person.addresses).to be_empty
          end

          it "sets the relation to empty in the database" do
            expect(person.reload.addresses).to be_empty
          end

          it "removed the inverse relation" do
            expect(address.addressable).to be_nil
          end

          it "deletes the child document" do
            expect(address).to be_destroyed
          end
        end

        context "when setting via attributes" do

          before do
            person.addresses = [ address ]
            person.attributes = { addresses: nil }
          end

          it "sets the relation to empty" do
            expect(person.addresses).to be_empty
          end

          it "deletes the child document" do
            expect(address).to be_destroyed
          end

          context "when saving the parent" do

            before do
              person.save!
              person.reload
            end

            it "persists the deletion" do
              expect(person.addresses).to be_empty
            end
          end
        end
      end

      context "when setting on a reload" do

        let(:person) do
          Person.create!
        end

        let(:address) do
          Address.new
        end

        let(:reloaded) do
          person.reload
        end

        before do
          person.reload.addresses = [ address ]
          person.reload.addresses = nil
        end

        it "sets the relation to empty" do
          expect(person.addresses).to be_empty
        end

        it "sets the relation to empty in the database" do
          expect(reloaded.addresses).to be_empty
        end
      end
    end

    context "when the relationship is cyclic" do

      context "when the parent is a new record" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          expect(parent_role.child_roles).to be_empty
        end

        it "removes the inverse relation" do
          expect(child_role.parent_role).to be_nil
        end
      end

      context "when the inverse is already nil" do

        let(:parent_role) do
          Role.new
        end

        before do
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          expect(parent_role.child_roles).to be_empty
        end
      end

      context "when the documents are not new records" do

        let(:parent_role) do
          Role.create!
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles = [ child_role ]
          parent_role.child_roles = nil
        end

        it "sets the relation to empty" do
          expect(parent_role.child_roles).to be_empty
        end

        it "removed the inverse relation" do
          expect(child_role.parent_role).to be_nil
        end

        it "deletes the child document" do
          expect(child_role).to be_destroyed
        end
      end
    end
  end

  describe "#as_document" do

    let!(:person) do
      Person.create!
    end

    context 'when a string is used to access an attribute' do

      let!(:address) do
        person.addresses.create!(street: "one")
      end

      let(:document) do
        person.reload.addresses.as_document.first
      end

      it "returns the attribute value" do
        expect(document['street']).to eq('one')
      end
    end

    context 'when a symbol is used to access an attribute' do

      let!(:address) do
        person.addresses.create!(street: "one")
      end

      let(:document) do
        person.reload.addresses.as_document.first
      end

      it "returns the attribute value" do
        expect(document[:street]).to eq('one')
      end
    end

    context "when the relation has no default scope" do

      let!(:address) do
        person.addresses.create!(street: "one")
      end

      let(:document) do
        person.reload.addresses.as_document
      end

      it "returns the documents as an array of hashes" do
        expect(document).to eq([ address.as_document ])
      end
    end

    context "when the relation has a default scope" do

      context "when the default scope sorts" do

        let(:cough) do
          Symptom.new(name: "cough")
        end

        let(:headache) do
          Symptom.new(name: "headache")
        end

        before do
          person.symptoms.concat([ headache, cough ])
        end

        let(:document) do
          person.reload.symptoms.as_document
        end

        it "returns the unscoped documents as an array of hashes" do
          expect(document).to eq([ headache.as_document, cough.as_document ])
        end
      end

      context "when the default scope limits" do

        let(:active) do
          Appointment.new
        end

        let(:inactive) do
          Appointment.new(active: false)
        end

        before do
          person.appointments.concat([ active, inactive ])
        end

        let(:document) do
          person.reload.appointments.as_document
        end

        it "returns the unscoped documents as an array of hashes" do
          expect(document).to eq([ active.as_document, inactive.as_document ])
        end
      end
    end
  end

  [ :build, :new ].each do |method|

    describe "#build" do

      context "when the relation is not cyclic" do

        let(:person) do
          Person.new
        end

        let(:address) do
          person.addresses.send(method, street: "Bond") do |address|
            address.state = "CA"
          end
        end

        it "appends to the target" do
          expect(person.addresses).to eq([ address ])
        end

        it "appends to the unscoped" do
          expect(person.addresses.send(:_unscoped)).to eq([ address ])
        end

        it "sets the base on the inverse relation" do
          expect(address.addressable).to eq(person)
        end

        it "does not save the new document" do
          expect(address).to_not be_persisted
        end

        it "sets the parent on the child" do
          expect(address._parent).to eq(person)
        end

        it "sets the association metadata on the child" do
          expect(address._association).to_not be_nil
        end

        it "sets the index on the child" do
          expect(address._index).to eq(0)
        end

        it "writes to the attributes" do
          expect(address.street).to eq("Bond")
        end

        it "calls the passed block" do
          expect(address.state).to eq("CA")
        end
      end

      context "when the relation is cyclic" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          parent_role.child_roles.send(method, name: "CTO")
        end

        it "appends to the target" do
          expect(parent_role.child_roles).to eq([ child_role ])
        end

        it "sets the base on the inverse relation" do
          expect(child_role.parent_role).to eq(parent_role)
        end

        it "does not save the new document" do
          expect(child_role).to_not be_persisted
        end

        it "sets the parent on the child" do
          expect(child_role._parent).to eq(parent_role)
        end

        it "sets the association metadata on the child" do
          expect(child_role._association).to_not be_nil
        end

        it "sets the index on the child" do
          expect(child_role._index).to eq(0)
        end

        it "writes to the attributes" do
          expect(child_role.name).to eq("CTO")
        end
      end

      context "when providing nested attributes" do

        let(:person) do
          Person.create!
        end

        let(:address) do
          person.addresses.send(
              method,
              street: "Bond",
              locations_attributes: { "1" => { "name" => "Home" } }
          )
        end

        context "when followed by a save" do

          before do
            address.save!
          end

          let(:location) do
            person.reload.addresses.first.locations.first
          end

          it "persists the deeply embedded document" do
            expect(location.name).to eq("Home")
          end
        end
      end
    end
  end

  describe "#clear" do

    context "when the parent has been persisted" do

      let(:person) do
        Person.create!
      end

      context "when the children are persisted" do

        let!(:address) do
          person.addresses.create!(street: "High St")
        end

        let!(:relation) do
          person.addresses.clear
        end

        it "clears out the relation" do
          expect(person.addresses).to be_empty
        end

        it "clears the unscoped" do
          expect(person.addresses.send(:_unscoped)).to be_empty
        end

        it "marks the documents as deleted" do
          expect(address).to be_destroyed
        end

        it "deletes the documents from the db" do
          expect(person.reload.addresses).to be_empty
        end

        it "returns the relation" do
          expect(relation).to be_empty
        end
      end

      context "when the children are not persisted" do

        let!(:address) do
          person.addresses.build(street: "High St")
        end

        let!(:relation) do
          person.addresses.clear
        end

        it "clears out the relation" do
          expect(person.addresses).to be_empty
        end
      end
    end

    context "when the parent is not persisted" do

      let(:person) do
        Person.new
      end

      let!(:address) do
        person.addresses.build(street: "High St")
      end

      let!(:relation) do
        person.addresses.clear
      end

      it "clears out the relation" do
        expect(person.addresses).to be_empty
      end
    end
  end

  describe "#concat" do

    context "when the parent is a new record" do

      let(:person) do
        Person.new
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses.concat([ address ])
      end

      it "appends to the target" do
        expect(person.addresses).to eq([ address ])
      end

      it "appends to the unscoped" do
        expect(person.addresses.send(:_unscoped)).to eq([ address ])
      end

      it "sets the base on the inverse relation" do
        expect(address.addressable).to eq(person)
      end

      it "sets the same instance on the inverse relation" do
        expect(address.addressable).to eql(person)
      end

      it "does not save the new document" do
        expect(address).to_not be_persisted
      end

      it "sets the parent on the child" do
        expect(address._parent).to eq(person)
      end

      it "sets the association metadata on the child" do
        expect(address._association).to_not be_nil
      end

      it "sets the index on the child" do
        expect(address._index).to eq(0)
      end
    end

    context "when the parent is not a new record" do

      let(:person) do
        Person.create!
      end

      let(:address) do
        Address.new
      end

      before do
        person.addresses.concat([ address ])
      end

      it "saves the new document" do
        expect(address).to be_persisted
      end
    end

    context "when concatenating an empty array" do

      let(:person) do
        Person.create!
      end

      before do
        expect(person.addresses).to_not receive(:batch_insert)
        person.addresses.concat([])
      end

      it "doesn't update the target" do
        expect(person.addresses).to be_empty
      end
    end

    context "when appending more than one document at once" do

      let(:person) do
        Person.create!
      end

      let(:address_one) do
        Address.new
      end

      let(:address_two) do
        Address.new
      end

      before do
        person.addresses.concat([ address_one, address_two ])
      end

      it "saves the first document" do
        expect(address_one).to be_persisted
      end

      it "saves the second document" do
        expect(address_two).to be_persisted
      end
    end

    context "when the parent and child have a cyclic relation" do

      context "when the parent is a new record" do

        let(:parent_role) do
          Role.new
        end

        let(:child_role) do
          Role.new
        end

        before do
          parent_role.child_roles.concat([ child_role ])
        end

        it "appends to the target" do
          expect(parent_role.child_roles).to eq([ child_role ])
        end

        it "sets the base on the inverse relation" do
          expect(child_role.parent_role).to eq(parent_role)
        end

        it "sets the same instance on the inverse relation" do
          expect(child_role.parent_role).to eql(parent_role)
        end

        it "does not save the new document" do
          expect(child_role).to_not be_persisted
        end

        it "sets the parent on the child" do
          expect(child_role._parent).to eq(parent_role)
        end

        it "sets the association metadata on the child" do
          expect(child_role._association).to_not be_nil
        end

        it "sets the index on the child" do
          expect(child_role._index).to eq(0)
        end
      end

      context "when the parent is not a new record" do

        let(:parent_role) do
          Role.create!(name: "CEO")
        end

        let(:child_role) do
          Role.new(name: "COO")
        end

        before do
          parent_role.child_roles.concat([ child_role ])
        end

        it "saves the new document" do
          expect(child_role).to be_persisted
        end
      end
    end
  end

  describe "#count" do

    let(:person) do
      Person.create!
    end

    before do
      person.addresses.create!(street: "Upper")
      person.addresses.build(street: "Bond")
      person.addresses.build(street: "Lower")
    end

    it "returns the number of persisted documents" do
      expect(person.addresses.count).to eq(1)
    end

    context 'block form' do
      it "iterates across all documents" do
        expect(person.addresses.count {|a| a.persisted? }).to eq(1)
        expect(person.addresses.count {|a| !a.persisted? }).to eq(2)
        expect(person.addresses.count {|a| a.street.include?('on') }).to eq(1)
        expect(person.addresses.count {|a| a.street.ends_with?('er') }).to eq(2)
      end
    end

    context 'argument form' do
      it "behaves correctly when given a model instance" do
        expect(person.addresses.count(person.addresses.first)).to eq(1)
      end

      it "behaves correctly when given a non-model instance" do
        expect(person.addresses.count(1)).to eq(0)
      end
    end
  end

  describe "#any?" do

    let(:person) do
      Person.create!
    end

    context "when documents are persisted" do
      before do
        person.addresses.create!(street: "Upper")
      end

      it "returns true" do
        expect(person.addresses.any?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.any? {|a| a.street == "Upper" }).to be true
        expect(person.addresses.any? {|a| a.street == "Bond" }).to be false
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.any?(person.addresses.first)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.any?(1)).to be false
        end
      end
    end

    context "when documents are not persisted" do
      before do
        person.addresses.build(street: "Bond")
      end

      it "returns true" do
        expect(person.addresses.any?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.any? {|a| a.street == "Upper" }).to be false
        expect(person.addresses.any? {|a| a.street == "Bond" }).to be true
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.any?(person.addresses.first)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.any?(1)).to be false
        end
      end
    end

    context "when documents are not present" do
      it "returns false" do
        expect(person.addresses.any?).to be false
      end

      it "block form iterates across all documents" do
        expect(person.addresses.any?(&:a)).to be false
      end

      it "argument form is supported" do
        expect(person.addresses.any?(1)).to be false
      end
    end
  end

  describe "#all?" do

    let(:person) do
      Person.create!
    end

    context "when documents are persisted" do
      before do
        person.addresses.create!(street: "Upper")
      end

      it "returns true" do
        expect(person.addresses.all?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.all? {|a| a.street == "Upper" }).to be true
        expect(person.addresses.all? {|a| a.street == "Bond" }).to be false
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.all?(person.addresses.first)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.all?(1)).to be false
        end
      end
    end

    context "when documents are not persisted" do
      before do
        person.addresses.build(street: "Bond")
      end

      it "returns true" do
        expect(person.addresses.all?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.all? {|a| a.street == "Upper" }).to be false
        expect(person.addresses.all? {|a| a.street == "Bond" }).to be true
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.all?(person.addresses.first)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.all?(1)).to be false
        end
      end
    end

    context "when documents are not present" do
      it "returns false" do
        expect(person.addresses.all?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.all?(&:foo)).to be true
      end

      context 'argument form' do
        it "behaves correctly when given nil" do
          expect(person.addresses.all?(nil)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.all?(1)).to be true
        end
      end
    end
  end

  describe "#none?" do

    let(:person) do
      Person.create!
    end

    context "when documents are persisted" do
      before do
        person.addresses.create!(street: "Upper")
      end

      it "returns true" do
        expect(person.addresses.none?).to be false
      end

      it "block form iterates across all documents" do
        expect(person.addresses.none? {|a| a.street == "Upper" }).to be false
        expect(person.addresses.none? {|a| a.street == "Bond" }).to be true
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.none?(person.addresses.first)).to be false
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.none?(1)).to be true
        end
      end
    end

    context "when documents are not persisted" do
      before do
        person.addresses.build(street: "Bond")
      end

      it "returns true" do
        expect(person.addresses.none?).to be false
      end

      it "block form iterates across all documents" do
        expect(person.addresses.none? {|a| a.street == "Upper" }).to be true
        expect(person.addresses.none? {|a| a.street == "Bond" }).to be false
      end

      context 'argument form' do
        it "behaves correctly when given a model instance" do
          expect(person.addresses.none?(person.addresses.first)).to be false
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.none?(1)).to be true
        end
      end
    end

    context "when documents are not present" do
      it "returns false" do
        expect(person.addresses.none?).to be true
      end

      it "block form iterates across all documents" do
        expect(person.addresses.none?(&:a)).to be true
      end

      context 'argument form' do
        it "behaves correctly when given nil" do
          expect(person.addresses.none?(nil)).to be true
        end

        it "behaves correctly when given a non-model instance" do
          expect(person.addresses.none?(1)).to be true
        end
      end
    end
  end

  describe "#create" do

    context "when providing multiple attributes" do

      let(:person) do
        Person.create!
      end

      let!(:addresses) do
        person.addresses.create!([{ street: "Bond" }, { street: "Upper" }])
      end

      it "creates multiple documents" do
        expect(addresses.size).to eq(2)
      end

      it "sets the first attributes" do
        expect(addresses.first.street).to eq("Bond")
      end

      it "sets the second attributes" do
        expect(addresses.last.street).to eq("Upper")
      end

      it "persists the children" do
        expect(person.addresses.count).to eq(2)
      end
    end

    context "when the relation is not cyclic" do

      let(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(street: "Bond") do |address|
          address.state = "CA"
        end
      end

      it "appends to the target" do
        expect(person.reload.addresses).to eq([ address ])
      end

      it "appends to the unscoped" do
        expect(person.reload.addresses.send(:_unscoped)).to eq([ address ])
      end

      it "sets the base on the inverse relation" do
        expect(address.addressable).to eq(person)
      end

      it "saves the document" do
        expect(address).to be_persisted
      end

      it "sets the parent on the child" do
        expect(address._parent).to eq(person)
      end

      it "sets the association metadata on the child" do
        expect(address._association).to_not be_nil
      end

      it "sets the index on the child" do
        expect(address._index).to eq(0)
      end

      it "writes to the attributes" do
        expect(address.street).to eq("Bond")
      end

      it "calls the passed block" do
        expect(address.state).to eq("CA")
      end

      context "when embedding a multi word named document" do

        let!(:component) do
          person.address_components.create!(street: "Test")
        end

        it "saves the embedded document" do
          expect(person.reload.address_components.first).to eq(component)
        end
      end
    end

    context "when the relation is cyclic" do

      let!(:entry) do
        Entry.create!(title: "hi")
      end

      let!(:child_entry) do
        entry.child_entries.create!(title: "hello")
      end

      it "creates a new child" do
        expect(child_entry).to be_persisted
      end
    end
  end

  describe "#create!" do

    let(:person) do
      Person.create!
    end

    context "when providing multiple attributes" do

      let!(:addresses) do
        person.addresses.create!([{ street: "Bond" }, { street: "Upper" }])
      end

      it "creates multiple documents" do
        expect(addresses.size).to eq(2)
      end

      it "sets the first attributes" do
        expect(addresses.first.street).to eq("Bond")
      end

      it "sets the second attributes" do
        expect(addresses.last.street).to eq("Upper")
      end

      it "persists the children" do
        expect(person.addresses.count).to eq(2)
      end
    end

    context "when validation passes" do

      let(:address) do
        person.addresses.create!(street: "Bond")
      end

      it "appends to the target" do
        expect(person.addresses).to eq([ address ])
      end

      it "appends to the unscoped" do
        expect(person.addresses.send(:_unscoped)).to eq([ address ])
      end

      it "sets the base on the inverse relation" do
        expect(address.addressable).to eq(person)
      end

      it "saves the document" do
        expect(address).to be_persisted
      end

      it "sets the parent on the child" do
        expect(address._parent).to eq(person)
      end

      it "sets the association metadata on the child" do
        expect(address._association).to_not be_nil
      end

      it "sets the index on the child" do
        expect(address._index).to eq(0)
      end

      it "writes to the attributes" do
        expect(address.street).to eq("Bond")
      end
    end

    context "when validation fails" do

      it "raises an error" do
        expect {
          person.addresses.create!(street: "1")
        }.to raise_error(Mongoid::Errors::Validations)
      end

      context 'when the presence of the embedded relation is validated' do

        around do |example|
          Book.validates :pages, presence: true
          example.run
          Book.reset_callbacks(:validate)
        end

        let(:book) do
          Book.new.tap do |b|
            b.pages = [Page.new]
            b.save!
          end
        end

        let(:num_pages) do
          book.pages.size
        end

        let(:reloaded) do
          book.reload
        end

        before do
          begin; book.update_attributes!({"pages"=>nil}); rescue; end
        end

        it 'does not delete the embedded relation' do
          expect(reloaded.pages.size).to eq(num_pages)
        end
      end
    end
  end

  %i[ delete delete_one ].each do |method|
    describe "\##{method}" do
      let(:address_one) { Address.new(street: "first") }
      let(:address_two) { Address.new(street: "second") }

      before do
        person.addresses << [ address_one, address_two ]
      end

      shared_examples_for 'deleting from the collection' do
        context 'when the document exists in the relation' do
          let!(:deleted) do
            person.addresses.send(method, address_one)
          end

          it 'deletes the document' do
            expect(person.addresses).to eq([ address_two ])
            expect(person.reload.addresses).to eq([ address_two ]) if person.persisted?
          end

          it 'deletes the document from the unscoped' do
            expect(person.addresses.send(:_unscoped)).to eq([ address_two ])
          end

          it 'reindexes the relation' do
            expect(address_two._index).to eq(0)
          end

          it 'returns the document' do
            expect(deleted).to eq(address_one)
          end
        end

        context 'when the document does not exist' do
          it 'returns nil' do
            expect(person.addresses.send(method, Address.new)).to be_nil
          end
        end
      end

      context 'when the root document is unpersisted' do
        let(:person) { Person.new }

        it_behaves_like 'deleting from the collection'
      end

      context 'when the root document is persisted' do
        let(:person) { Person.create }

        it_behaves_like 'deleting from the collection'
      end
    end
  end

  describe "#delete_if" do

    let(:person) do
      Person.create!
    end

    context "when the documents are new" do

      let!(:address_one) do
        person.addresses.build(street: "Bond")
      end

      let!(:address_two) do
        person.addresses.build(street: "Upper")
      end

      context "when a block is provided" do

        let!(:deleted) do
          person.addresses.delete_if do |doc|
            doc.street == "Bond"
          end
        end

        it "removes the matching documents" do
          expect(person.addresses.size).to eq(1)
        end

        it "removes from the unscoped" do
          expect(person.addresses.send(:_unscoped).size).to eq(1)
        end

        it "returns the relation" do
          expect(deleted).to eq(person.addresses)
        end
      end

      context "when no block is provided" do

        let!(:deleted) do
          person.addresses.delete_if
        end

        it "returns an enumerator" do
          expect(deleted).to be_a(Enumerator)
        end
      end
    end

    context "when the documents persisted" do

      let!(:address_one) do
        person.addresses.create!(street: "Bond")
      end

      let!(:address_two) do
        person.addresses.create!(street: "Upper")
      end

      context "when a block is provided" do

        let!(:deleted) do
          person.addresses.delete_if do |doc|
            doc.street == "Bond"
          end
        end

        it "deletes the matching documents" do
          expect(person.addresses.count).to eq(1)
        end

        it "deletes the matching documents from the db" do
          expect(person.reload.addresses.count).to eq(1)
        end

        it "returns the relation" do
          expect(deleted).to eq(person.addresses)
        end
      end
    end

    context "when the documents are empty" do

      context "when a block is provided" do

        let!(:deleted) do
          person.addresses.delete_if do |doc|
            doc.street == "Bond"
          end
        end

        it "deletes the matching documents" do
          expect(person.addresses.count).to eq(0)
        end

        it "deletes all the documents from the db" do
          expect(person.reload.addresses.count).to eq(0)
        end

        it "returns the relation" do
          expect(deleted).to eq(person.addresses)
        end
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create!
      end

      context "when the documents are new" do

        let!(:address_one) do
          person.addresses.build(street: "Bond")
        end

        let!(:address_two) do
          person.addresses.build(street: "Upper")
        end

        context "when conditions are provided" do

          let!(:deleted) do
            person.addresses.send(
                method,
                { street: "Bond" }
            )
          end

          it "removes the matching documents" do
            expect(person.addresses.size).to eq(1)
          end

          it "removes from the unscoped" do
            expect(person.addresses.send(:_unscoped).size).to eq(1)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(1)
          end
        end

        context "when conditions are not provided" do

          let!(:deleted) do
            person.addresses.send(method)
          end

          it "removes all documents" do
            expect(person.addresses.size).to eq(0)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(2)
          end
        end
      end

      context "when the documents persisted" do

        let!(:address_one) do
          person.addresses.create!(street: "Bond")
        end

        let!(:address_two) do
          person.addresses.create!(street: "Upper")
        end

        context "when conditions are provided" do

          let!(:deleted) do
            person.addresses.send(
                method,
                { street: "Bond" }
            )
          end

          it "deletes the matching documents" do
            expect(person.addresses.count).to eq(1)
          end

          it "deletes the matching documents from the db" do
            expect(person.reload.addresses.count).to eq(1)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(1)
          end
        end

        context "when conditions are not provided" do

          let!(:deleted) do
            person.addresses.send(method)
          end

          it "deletes all the documents" do
            expect(person.addresses.count).to eq(0)
          end

          it "deletes all the documents from the db" do
            expect(person.reload.addresses.count).to eq(0)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(2)
          end
        end

        context "when removing and resaving" do

          let(:owner) do
            PetOwner.create!(title: "AKC")
          end

          before do
            owner.pet = Pet.new(name: "Fido")
            owner.pet.vet_visits << VetVisit.new(date: Date.today)
            owner.save!
            owner.pet.vet_visits.destroy_all
          end

          it "removes the documents" do
            expect(owner.pet.vet_visits).to be_empty
          end

          it "allows addition and a resave" do
            owner.pet.vet_visits << VetVisit.new(date: Date.today)
            owner.save!
            expect(owner.pet.vet_visits.first).to be_persisted
          end
        end
      end

      context "when the documents empty" do

        context "when scoped" do
          let!(:deleted) do
            person.addresses.without_postcode.send(method)
          end

          it "deletes all the documents" do
            expect(person.addresses.count).to eq(0)
          end

          it "deletes all the documents from the db" do
            expect(person.reload.addresses.count).to eq(0)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(0)
          end
        end

        context "when conditions are provided" do

          let!(:deleted) do
            person.addresses.send(
                method,
                conditions: { street: "Bond" }
            )
          end

          it "deletes all the documents" do
            expect(person.addresses.count).to eq(0)
          end

          it "deletes all the documents from the db" do
            expect(person.reload.addresses.count).to eq(0)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(0)
          end
        end

        context "when conditions are not provided" do

          let!(:deleted) do
            person.addresses.send(method)
          end

          it "deletes all the documents" do
            expect(person.addresses.count).to eq(0)
          end

          it "deletes all the documents from the db" do
            expect(person.reload.addresses.count).to eq(0)
          end

          it "returns the number deleted" do
            expect(deleted).to eq(0)
          end
        end
      end

      context "when modifying the document beforehand" do
        let(:parent) { EmmParent.new }

        before do

          parent.blocks << EmmBlock.new(name: 'test', children: [size: 1, order: 1])
          parent.save!

          parent.blocks[0].children[0].assign_attributes(size: 2)

          parent.blocks.destroy_all(:name => 'test')
        end

        it "deletes the correct document in the database" do
          expect(parent.reload.blocks.length).to eq(0)
        end
      end

      context "when nil _id" do
        let(:parent) { EmmParent.new }

        before do
          parent.blocks << EmmBlock.new(_id: nil, name: 'test', children: [size: 1, order: 1])
          parent.blocks << EmmBlock.new(_id: nil, name: 'test2', children: [size: 1, order: 1])
          parent.save!

          parent.blocks.destroy_all(:name => 'test')
        end

        it "deletes only the matching documents in the database" do
          expect(parent.reload.blocks.length).to eq(1)
        end
      end

      # Since without an _id field we must us a $pullAll with the attributes of
      # the embedded document, if you modify it beforehand, the query will not
      # be able to find the correct document to pull.
      context "when modifying the document with nil _id" do
        let(:parent) { EmmParent.new }

        before do
          parent.blocks << EmmBlock.new(_id: nil, name: 'test', children: [size: 1, order: 1])
          parent.blocks << EmmBlock.new(_id: nil, name: 'test2', children: [size: 1, order: 1])
          parent.save!

          parent.blocks[0].children[0].assign_attributes(size: 2)

          parent.blocks.destroy_all(:name => 'test')
        end

        it "does not delete the correct documents" do
          expect(parent.reload.blocks.length).to eq(2)
        end
      end

      context "when documents with and without _id" do
        let(:parent) { EmmParent.new }

        before do
          parent.blocks << EmmBlock.new(_id: nil, name: 'test', children: [size: 1, order: 1])
          parent.blocks << EmmBlock.new(name: 'test', children: [size: 1, order: 1])
          parent.save!

          parent.blocks[1].children[0].assign_attributes(size: 2)

          parent.blocks.destroy_all(:name => 'test')
        end

        it "does not delete the correct documents" do
          expect(parent.reload.blocks.length).to eq(0)
        end
      end
    end
  end

  describe ".embedded?" do

    it "returns true" do
      expect(described_class).to be_embedded
    end
  end

  describe "#exists?" do

    let!(:person) do
      Person.create!
    end

    context "when documents exist in the database" do

      before do
        person.addresses.create!(street: "Bond St")
      end

      it "returns true" do
        expect(person.addresses.exists?).to be true
      end
    end

    context "when no documents exist in the database" do

      before do
        person.addresses.build(street: "Hyde Park Dr")
      end

      it "returns false" do
        expect(person.addresses.exists?).to be false
      end
    end
  end

  describe "#find" do

    let(:person) do
      Person.new
    end

    let!(:address_one) do
      person.addresses.build(street: "Bond", city: "London")
    end

    let!(:address_two) do
      person.addresses.build(street: "Upper", city: "London")
    end

    context "when providing an id" do

      context "when the id matches" do

        let(:address) do
          person.addresses.find(address_one.id)
        end

        it "returns the matching document" do
          expect(address).to eq(address_one)
        end
      end

      context "when the id does not match" do

        context "when config set to raise error" do
          config_override :raise_not_found_error, true

          it "raises an error" do
            expect {
              person.addresses.find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Address with id\(s\)/)
          end
        end

        context "when config set not to raise error" do
          config_override :raise_not_found_error, false

          let(:address) do
            person.addresses.find(BSON::ObjectId.new)
          end

          it "returns nil" do
            expect(address).to be_nil
          end
        end
      end
    end

    context "when providing an array of ids" do

      context "when the ids match" do

        let(:addresses) do
          person.addresses.find([ address_one.id, address_two.id ])
        end

        it "returns the matching documents" do
          expect(addresses).to eq([ address_one, address_two ])
        end
      end

      context "when the ids do not match" do

        context "when config set to raise error" do
          config_override :raise_not_found_error, true

          it "raises an error" do
            expect {
              person.addresses.find([ BSON::ObjectId.new ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound, /Document\(s\) not found for class Address with id\(s\)/)
          end
        end

        context "when config set not to raise error" do
          config_override :raise_not_found_error, false

          let(:addresses) do
            person.addresses.find([ BSON::ObjectId.new ])
          end

          it "returns an empty array" do
            expect(addresses).to be_empty
          end
        end
      end
    end

    context "with block" do
      let!(:author) do
        Person.create!(title: 'Person')
      end

      let!(:video_one) do
        author.videos.create!(title: 'video one')
      end

      let!(:video_two) do
        author.videos.create!(title: 'video two')
      end

      it "finds one" do
        expect(
          author.videos.find do |video|
            video.title == 'video one'
          end
        ).to eq(video_one)
      end

      it "returns first match of multiple" do
        expect(
          author.videos.find do |video|
            ['video one', 'video two'].include?(video.title)
          end
        ).to be_a(Video)
      end

      it "returns nil when not found" do
        expect(
          author.videos.find do |video|
            video.title == 'non exiting one'
          end
        ).to be_nil
      end
    end
  end

  describe "#find_or_create_by" do

    let(:person) do
      Person.create!
    end

    let!(:address) do
      person.addresses.build(street: "Bourke", city: "Melbourne")
    end

    context "when the document exists" do

      let(:found) do
        person.addresses.find_or_create_by(street: "Bourke")
      end

      it "returns the document" do
        expect(found).to eq(address)
      end
    end

    context "when the document does not exist" do

      let(:found) do
        person.addresses.find_or_create_by(street: "King") do |address|
          address.state = "CA"
        end
      end

      it "sets the new document attributes" do
        expect(found.street).to eq("King")
      end

      it "returns a newly persisted document" do
        expect(found).to be_persisted
      end

      it "calls the passed block" do
        expect(found.state).to eq("CA")
      end
    end

    # todo: why should this pass?
    # context "when the child belongs to another document" do
    #
    #   let(:product) do
    #     Product.create!
    #   end
    #
    #   let(:purchase) do
    #     Purchase.create!
    #   end
    #
    #   let(:line_item) do
    #     purchase.line_items.find_or_create_by(
    #         product_id: product.id,
    #         product_type: product.class.name
    #     )
    #   end
    #
    #   it "properly creates the document" do
    #     expect(line_item.product).to eq(product)
    #   end
    # end
  end

  describe "#find_or_create_by!" do

    let(:person) do
      Person.create!
    end

    let!(:address) do
      person.addresses.build(street: "Bourke", city: "Melbourne")
    end

    context "when the document exists" do

      let(:found) do
        person.addresses.find_or_create_by!(street: "Bourke")
      end

      it "returns the document" do
        expect(found).to eq(address)
      end
    end

    context "when the document does not exist" do

      let(:found) do
        person.addresses.find_or_create_by!(street: "King") do |address|
          address.state = "CA"
        end
      end

      it "sets the new document attributes" do
        expect(found.street).to eq("King")
      end

      it "returns a newly persisted document" do
        expect(found).to be_persisted
      end

      it "calls the passed block" do
        expect(found.state).to eq("CA")
      end

      context "when validation fails" do

        it "raises an error" do
          expect {
            person.addresses.find_or_create_by!(street: "1")
          }.to raise_error(Mongoid::Errors::Validations)
        end
      end
    end

    # todo: why should this pass?
    # context "when the child belongs to another document" do
    #
    #   let(:product) do
    #     Product.create!
    #   end
    #
    #   let(:purchase) do
    #     Purchase.create!
    #   end
    #
    #   let(:line_item) do
    #     purchase.line_items.find_or_create_by(
    #         product_id: product.id,
    #         product_type: product.class.name
    #     )
    #   end
    #
    #   it "properly creates the document" do
    #     expect(line_item.product).to eq(product)
    #   end
    # end
  end

  describe "#find_or_initialize_by" do

    let(:person) do
      Person.new
    end

    let!(:address) do
      person.addresses.build(street: "Bourke", city: "Melbourne")
    end

    context "when the document exists" do

      let(:found) do
        person.addresses.find_or_initialize_by(street: "Bourke")
      end

      it "returns the document" do
        expect(found).to eq(address)
      end
    end

    context "when the document does not exist" do

      let(:found) do
        person.addresses.find_or_initialize_by(street: "King") do |address|
          address.state = "CA"
        end
      end

      it "sets the new document attributes" do
        expect(found.street).to eq("King")
      end

      it "returns a non persisted document" do
        expect(found).to_not be_persisted
      end

      it "calls the passed block" do
        expect(found.state).to eq("CA")
      end
    end
  end

  describe "#max" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new(number: 5)
    end

    let(:address_two) do
      Address.new(number: 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:max) do
      person.addresses.max do |a,b|
        a.number <=> b.number
      end
    end

    it "returns the document with the max value of the supplied field" do
      expect(max).to eq(address_two)
    end
  end

  describe "#max_by" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new(number: 5)
    end

    let(:address_two) do
      Address.new(number: 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:max) do
      person.addresses.max_by(&:number)
    end

    it "returns the document with the max value of the supplied field" do
      expect(max).to eq(address_two)
    end
  end

  describe "#method_missing" do

    let!(:person) do
      Person.create!
    end

    let!(:address_one) do
      person.addresses.create!(
          street: "Market",
          state: "CA",
          services: [ "1", "2" ]
      )
    end

    let!(:address_two) do
      person.addresses.create!(
          street: "Madison",
          state: "NY",
          services: [ "1", "2" ]
      )
    end

    context "when providing a single criteria" do

      context "when using a simple criteria" do

        let(:addresses) do
          person.addresses.where(state: "CA")
        end

        it "applies the criteria to the documents" do
          expect(addresses).to eq([ address_one ])
        end
      end

      context "when using an $or criteria" do

        let(:addresses) do
          person.addresses.any_of({ state: "CA" }, { state: "NY" })
        end

        it "applies the criteria to the documents" do
          expect(addresses).to eq([ address_one, address_two ])
        end
      end

      context "when using array comparison" do

        let(:addresses) do
          person.addresses.where(services: [ "1", "2" ])
        end

        it "applies the criteria to the documents" do
          expect(addresses).to eq([ address_one, address_two ])
        end
      end
    end

    context "when providing a criteria class method" do
      context "without keyword arguments" do

        let(:addresses) do
          person.addresses.california
        end

        it "applies the criteria to the documents" do
          expect(addresses).to eq([ address_one ])
        end
      end

      context "with keyword arguments" do

        let(:addresses) do
          person.addresses.city_and_state(city: "Sacramento", state: "CA")
        end

        it "applies the criteria to the documents" do
          expect(addresses).to eq([])
        end
      end
    end

    context "when chaining criteria" do

      let(:addresses) do
        person.addresses.california.where(:street.in => [ "Market" ])
      end

      it "applies the criteria to the documents" do
        expect(addresses).to eq([ address_one ])
      end
    end

    context "when delegating methods" do

      describe "#distinct" do

        it "returns the distinct values for the fields" do
          expect(person.addresses.distinct(:street)).to eq([ "Market",  "Madison"])
        end
      end
    end
  end

  describe "#min" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new(number: 5)
    end

    let(:address_two) do
      Address.new(number: 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:min) do
      person.addresses.min do |a,b|
        a.number <=> b.number
      end
    end

    it "returns the min value of the supplied field" do
      expect(min).to eq(address_one)
    end
  end

  describe "#min_by" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new(number: 5)
    end

    let(:address_two) do
      Address.new(number: 10)
    end

    before do
      person.addresses.push(address_one, address_two)
    end

    let(:min) do
      person.addresses.min_by(&:number)
    end

    it "returns the min value of the supplied field" do
      expect(min).to eq(address_one)
    end
  end

  describe "#pop" do

    let(:person) do
      Person.create!
    end

    context "when no argument is provided" do

      let!(:address_one) do
        person.addresses.create!(street: "sonnenallee")
      end

      let!(:address_two) do
        person.addresses.create!(street: "hermannstr")
      end

      let!(:popped) do
        person.addresses.pop
      end

      it "returns the popped document" do
        expect(popped).to eq(address_two)
      end

      it "removes the document from the relation" do
        expect(person.addresses).to eq([ address_one ])
      end

      it "persists the pop" do
        expect(person.reload.addresses).to eq([ address_one ])
      end
    end

    context "when an integer is provided" do

      let!(:address_one) do
        person.addresses.create!(street: "sonnenallee")
      end

      let!(:address_two) do
        person.addresses.create!(street: "hermannstr")
      end

      context "when the number is zero" do

        let!(:popped) do
          person.addresses.pop(0)
        end

        it "returns an empty array" do
          expect(popped).to eq([])
        end

        it "does not remove the document from the relation" do
          expect(person.addresses).to eq([ address_one, address_two ])
        end

        it "does not persist the pop" do
          expect(person.reload.addresses).to eq([ address_one, address_two ])
        end
      end

      context "when the number is not larger than the relation" do

        let!(:popped) do
          person.addresses.pop(2)
        end

        it "returns the popped documents" do
          expect(popped).to eq([ address_one, address_two ])
        end

        it "removes the document from the relation" do
          expect(person.addresses).to be_empty
        end

        it "persists the pop" do
          expect(person.reload.addresses).to be_empty
        end
      end

      context "when the number is larger than the relation" do

        let!(:popped) do
          person.addresses.pop(4)
        end

        it "returns the popped documents" do
          expect(popped).to eq([ address_one, address_two ])
        end

        it "removes the document from the relation" do
          expect(person.addresses).to be_empty
        end

        it "persists the pop" do
          expect(person.reload.addresses).to be_empty
        end
      end
    end

    context "when the relation is empty" do

      context "when providing no number" do

        it "returns nil" do
          expect(person.addresses.pop).to be_nil
        end
      end

      context "when providing a number" do

        it "returns nil" do
          expect(person.addresses.pop(2)).to be_nil
        end
      end
    end
  end

  describe "#shift" do

    let(:person) do
      Person.create!
    end

    context "when no argument is provided" do

      let!(:address_one) do
        person.addresses.create!(street: "sonnenallee")
      end

      let!(:address_two) do
        person.addresses.create!(street: "hermannstr")
      end

      let!(:shifted) do
        person.addresses.shift
      end

      it "returns the shifted document" do
        expect(shifted).to eq(address_one)
      end

      it "removes the document from the relation" do
        expect(person.addresses).to eq([ address_two ])
      end

      it "persists the shift" do
        expect(person.reload.addresses).to eq([ address_two ])
      end
    end

    context "when an integer is provided" do

      let!(:address_one) do
        person.addresses.create!(street: "sonnenallee")
      end

      let!(:address_two) do
        person.addresses.create!(street: "hermannstr")
      end

      context "when the number is zero" do

        let!(:shifted) do
          person.addresses.shift(0)
        end

        it "returns an empty array" do
          expect(shifted).to eq([])
        end

        it "does not remove the document from the relation" do
          expect(person.addresses).to eq([ address_one, address_two ])
        end

        it "does not persist the shift" do
          expect(person.reload.addresses).to eq([ address_one, address_two ])
        end
      end

      context "when the number is not larger than the relation" do

        let!(:shifted) do
          person.addresses.shift(2)
        end

        it "returns the shifted documents" do
          expect(shifted).to eq([ address_one, address_two ])
        end

        it "removes the document from the relation" do
          expect(person.addresses).to be_empty
        end

        it "persists the shift" do
          expect(person.reload.addresses).to be_empty
        end
      end

      context "when the number is larger than the relation" do

        let!(:shifted) do
          person.addresses.shift(4)
        end

        it "returns the shifted documents" do
          expect(shifted).to eq([ address_one, address_two ])
        end

        it "removes the document from the relation" do
          expect(person.addresses).to be_empty
        end

        it "persists the shift" do
          expect(person.reload.addresses).to be_empty
        end
      end
    end

    context "when the relation is empty" do

      context "when providing no number" do

        it "returns nil" do
          expect(person.addresses.shift).to be_nil
        end
      end

      context "when providing a number" do

        it "returns nil" do
          expect(person.addresses.shift(2)).to be_nil
        end
      end
    end
  end

  describe "#scoped" do

    let(:person) do
      Person.new
    end

    let(:scoped) do
      person.addresses.scoped
    end

    it "returns the relation criteria" do
      expect(scoped).to be_a(Mongoid::Criteria)
    end

    it "returns with an empty selector" do
      expect(scoped.selector).to be_empty
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:addresses) do
      person.addresses
    end

    Array.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(addresses.respond_to?(method)).to be true
        end
      end
    end

    Mongoid::Association::Embedded::EmbedsMany::Proxy.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(addresses.respond_to?(method)).to be true
        end
      end
    end

    Address.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          expect(addresses.respond_to?(method)).to be true
        end
      end
    end

    it "supports 'include_private = boolean'" do
      expect { addresses.respond_to?(:Rational, true) }.not_to raise_error
    end
  end

  [ :size, :length ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.create!
      end

      before do
        person.addresses.create!(street: "Upper")
        person.addresses.build(street: "Bond")
      end

      it "returns the number of persisted documents" do
        expect(person.addresses.send(method)).to eq(2)
      end
    end
  end

  describe "#unscoped" do

    let(:person) do
      Person.new
    end

    let(:unscoped) do
      person.videos.unscoped
    end

    it "returns the relation criteria" do
      expect(unscoped).to be_a(Mongoid::Criteria)
    end

    it "returns with empty options" do
      expect(unscoped.options).to be_empty
    end

    it "returns with an empty selector" do
      expect(unscoped.selector).to be_empty
    end
  end

  describe "#update_all" do

    context "when there are no documents present" do

      let(:person) do
        Person.create!
      end

      it "updates nothing" do
        expect(person.addresses.update_all(street: "test")).to be false
      end
    end

    context "when documents are present" do

      let(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(street: "Hobrecht", number: 27)
      end

      context "when updating with a where clause" do

        before do
          person.addresses.
              where(street: "Hobrecht").
              update_all(number: 26, post_code: "12437")
        end

        it "resets the matching dirty flags" do
          expect(address).to_not be_changed
        end

        it "updates the first field" do
          expect(address.reload.number).to eq(26)
        end

        it "updates the second field" do
          expect(address.reload.post_code).to eq("12437")
        end

        it "does not wipe out other fields" do
          expect(address.reload.street).to eq("Hobrecht")
        end
      end
    end
  end

  context "when deeply embedding documents" do

    context "when updating the bottom level" do

      let!(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(street: "Joachimstr")
      end

      let!(:location) do
        address.locations.create!(name: "vacation", number: 0)
        address.locations.create!(name: "work", number: 3)
      end

      context "when updating with replacement of embedded array" do

        context "when updating with a hash" do

          before do
            address.update_attributes!(locations: [{ name: "home" }])
          end

          it "updates the attributes" do
            expect(address.locations.first.name).to eq("home")
          end

          it "overwrites the existing documents" do
            expect(address.locations.count).to eq(1)
          end

          it "persists the changes" do
            expect(address.reload.locations.count).to eq(1)
          end
        end
      end

      context "when updating a field in a document of the embedded array" do

        before do
          location.number = 7
          location.save!
        end

        let(:updated_location_number) do
          person.reload.addresses.first.locations.find(location.id).number
        end

        let(:updated_location_name) do
          person.reload.addresses.first.locations.find(location.id).name
        end

        it "the change is persisted" do
          expect(updated_location_number).to eq(7)
        end

        it "the other field remains unaffected" do
          expect(updated_location_name).to eq("work")
        end

      end
    end

    context "when building the tree through hashes" do

      let(:circus) do
        Circus.new(hash)
      end

      let(:animal) do
        circus.animals.first
      end

      let(:animal_name) do
        "Lion"
      end

      let(:tag_list) do
        "tigers, bears, oh my"
      end

      context "when the hash uses stringified keys" do

        let(:hash) do
          { 'animals' => [{ 'name' => animal_name, 'tag_list' => tag_list }] }
        end

        it "sets up the hierarchy" do
          expect(animal.circus).to eq(circus)
        end

        it "assigns the attributes" do
          expect(animal.name).to eq(animal_name)
        end

        it "uses custom writer methods" do
          expect(animal.tag_list).to eq(tag_list)
        end
      end

      context "when the hash uses symbolized keys" do

        let(:hash) do
          { animals: [{ name: animal_name, tag_list: tag_list }] }
        end

        it "sets up the hierarchy" do
          expect(animal.circus).to eq(circus)
        end

        it "assigns the attributes" do
          expect(animal.name).to eq(animal_name)
        end

        it "uses custom writer methods" do
          expect(animal.tag_list).to eq(tag_list)
        end
      end
    end

    context "when building the tree through pushes" do

      let(:quiz) do
        Quiz.new
      end

      let(:page) do
        Page.new
      end

      let(:page_question) do
        PageQuestion.new
      end

      before do
        quiz.pages << page
        page.page_questions << page_question
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      it "sets up the hierarchy" do
        expect(question).to eq(page_question)
      end
    end

    context "when building the tree through builds" do

      let!(:quiz) do
        Quiz.new
      end

      let!(:page) do
        quiz.pages.build
      end

      let!(:page_question) do
        page.page_questions.build
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      it "sets up the hierarchy" do
        expect(question).to eq(page_question)
      end
    end

    context "when creating a persisted tree" do

      let(:quiz) do
        Quiz.create!
      end

      let(:page) do
        Page.new
      end

      let(:page_question) do
        PageQuestion.new
      end

      let(:question) do
        quiz.pages.first.page_questions.first
      end

      before do
        quiz.pages << page
        page.page_questions << page_question
      end

      it "sets up the hierarchy" do
        expect(question).to eq(page_question)
      end

      context "when reloading" do

        let(:from_db) do
          quiz.reload
        end

        let(:reloaded_question) do
          from_db.pages.first.page_questions.first
        end

        it "reloads the entire tree" do
          expect(reloaded_question).to eq(question)
        end
      end
    end
  end

  context "when deeply nesting documents" do

    context "when all documents are new" do

      let(:person) do
        Person.new
      end

      let(:address) do
        Address.new
      end

      let(:location) do
        Location.new
      end

      before do
        address.locations << location
        person.addresses << address
      end

      context "when saving the root" do

        before do
          person.save!
        end

        it "persists the first level document" do
          expect(person.reload.addresses.first).to eq(address)
        end

        it "persists the second level document" do
          expect(person.reload.addresses[0].locations).to eq([ location ])
        end
      end
    end
  end

  context "when attempting nil pushes and substitutes" do

    let(:home_phone) do
      Phone.new(number: "555-555-5555")
    end

    let(:office_phone) do
      Phone.new(number: "666-666-6666")
    end

    describe "replacing the entire embedded list" do

      context "when an embeds many relationship contains nil as the first item" do

        let(:person) do
          Person.create!
        end

        let(:phone_list) do
          [nil, home_phone, office_phone]
        end

        before do
          person.phone_numbers = phone_list
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq([ home_phone, office_phone ])
        end
      end

      context "when an embeds many relationship contains nil in the middle of the list" do

        let(:person) do
          Person.create!
        end

        let(:phone_list) do
          [home_phone, nil, office_phone]
        end

        before do
          person.phone_numbers = phone_list
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq([ home_phone, office_phone ])
        end
      end

      context "when an embeds many relationship contains nil at the end of the list" do

        let(:person) do
          Person.create!
        end

        let(:phone_list) do
          [home_phone, office_phone, nil]
        end

        before do
          person.phone_numbers = phone_list
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq([ home_phone, office_phone ])
        end
      end
    end

    describe "appending to the embedded list" do

      context "when appending nil to the first position in an embedded list" do

        let(:person) do
          Person.create! phone_numbers: []
        end

        before do
          person.phone_numbers << nil
          person.phone_numbers << home_phone
          person.phone_numbers << office_phone
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq(person.phone_numbers)
        end
      end

      context "when appending nil into the middle of an embedded list" do

        let(:person) do
          Person.create! phone_numbers: []
        end

        before do
          person.phone_numbers << home_phone
          person.phone_numbers << nil
          person.phone_numbers << office_phone
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq(person.phone_numbers)
        end
      end

      context "when appending nil to the end of an embedded list" do

        let(:person) do
          Person.create! phone_numbers: []
        end

        before do
          person.phone_numbers << home_phone
          person.phone_numbers << office_phone
          person.phone_numbers << nil
          person.save!
        end

        it "ignores the nil and persist the remaining items" do
          reloaded = Person.find(person.id)
          expect(reloaded.phone_numbers).to eq(person.phone_numbers)
        end
      end
    end
  end

  context "when accessing the parent in a destroy callback" do

    let!(:league) do
      League.create!
    end

    let!(:division) do
      league.divisions.create!
    end

    before do
      league.destroy
    end

    it "retains the reference to the parent" do
      expect(league.name).to eq("Destroyed")
    end
  end

  context "when updating the parent with all attributes" do

    let!(:person) do
      Person.create!
    end

    let!(:address) do
      person.addresses.create!
    end

    before do
      person.update_attributes!(person.attributes)
    end

    it "does not duplicate the embedded documents" do
      expect(person.addresses).to eq([ address ])
    end

    it "does not persist duplicate embedded documents" do
      expect(person.reload.addresses).to eq([ address ])
    end
  end

  context "when embedding children named versions" do

    let(:acolyte) do
      Acolyte.create!(name: "test")
    end

    context "when creating a child" do

      let(:version) do
        acolyte.versions.create!(number: 1)
      end

      it "allows the operation" do
        expect(version.number).to eq(1)
      end

      context "when reloading the parent" do

        let(:from_db) do
          acolyte.reload
        end

        it "saves the child versions" do
          expect(from_db.versions).to eq([ version ])
        end
      end
    end
  end

  context "when validating the parent before accessing the child" do

    let!(:account) do
      Account.new(name: "Testing").tap do |acct|
        acct.memberships.build
        acct.save!
      end
    end

    let(:from_db) do
      Account.first
    end

    context "when saving" do

      before do
        account.name = ""
      end

      it "does not lose the parent reference" do
        expect(account.save).to eq false
        expect(from_db.memberships.first.account).to eq(account)
      end
    end

    context "when updating attributes" do

      before do
        from_db.update_attributes(name: "")
      end

      it "does not lose the parent reference" do
        expect(from_db.memberships.first.account).to eq(account)
      end
    end
  end

  context "when moving an embedded document from one parent to another" do

    let!(:person_one) do
      Person.create!
    end

    let!(:person_two) do
      Person.create!
    end

    let!(:address) do
      person_one.addresses.create!(street: "Kudamm")
    end

    before do
      person_two.addresses << address
    end

    it "adds the document to the new paarent" do
      expect(person_two.addresses).to eq([ address ])
    end

    it "sets the new parent on the document" do
      expect(address._parent).to eq(person_two)
    end

    context "when reloading the documents" do

      before do
        person_one.reload
        person_two.reload
      end

      it "persists the change to the new parent" do
        expect(person_two.addresses).to eq([ address ])
      end

      it "keeps the address on the previous document" do
        expect(person_one.addresses).to eq([ address ])
      end
    end
  end

  context "when the relation has a default scope" do

    let!(:person) do
      Person.create!
    end

    context "when the default scope is a sort" do

      let(:cough) do
        Symptom.new(name: "cough")
      end

      let(:headache) do
        Symptom.new(name: "headache")
      end

      let(:nausea) do
        Symptom.new(name: "nausea")
      end

      before do
        person.symptoms.concat([ nausea, cough, headache ])
      end

      context "when accessing the relation" do

        let(:symptoms) do
          person.reload.symptoms
        end

        it "applies the default scope" do
          expect(symptoms).to eq([ cough, headache, nausea ])
        end
      end

      context "when modifying the relation" do

        let(:constipation) do
          Symptom.new(name: "constipation")
        end

        before do
          person.symptoms.push(constipation)
        end

        context "when reloading" do

          let(:symptoms) do
            person.reload.symptoms
          end

          it "applies the default scope" do
            expect(symptoms).to eq([ constipation, cough, headache, nausea ])
          end
        end
      end

      context "when unscoping the relation" do

        let(:unscoped) do
          person.reload.symptoms.unscoped
        end

        it "removes the default scope" do
          expect(unscoped).to eq([ nausea, cough, headache ])
        end
      end
    end
  end

  context "when indexing the documents" do

    let!(:person) do
      Person.create!
    end

    context "when the documents have a limiting default scope" do

      let(:active) do
        Appointment.new
      end

      let(:inactive) do
        Appointment.new(active: false)
      end

      before do
        person.appointments.concat([ inactive, active ])
      end

      let(:relation) do
        person.reload.appointments
      end

      it "retains the unscoped index for the excluded document" do
        expect(relation.send(:_unscoped).first._index).to eq(0)
      end

      it "retains the unscoped index for the included document" do
        expect(relation.first._index).to eq(1)
      end

      context "when a reindexing operation occurs" do

        before do
          relation.send(:reindex)
        end

        it "retains the unscoped index for the excluded document" do
          expect(relation.send(:_unscoped).first._index).to eq(0)
        end

        it "retains the unscoped index for the included document" do
          expect(relation.first._index).to eq(1)
        end
      end
    end
  end

  context "when the embedded document has an array field" do

    let!(:person) do
      Person.create!
    end

    let!(:video) do
      person.videos.create!
    end

    context "when saving the array on a persisted document" do

      before do
        video.genres = [ "horror", "scifi" ]
        video.save!
      end

      it "sets the value" do
        expect(video.genres).to eq([ "horror", "scifi" ])
      end

      it "persists the value" do
        expect(video.reload.genres).to eq([ "horror", "scifi" ])
      end

      context "when reloading the parent" do

        let!(:loaded_person) do
          Person.find(person.id)
        end

        let!(:loaded_video) do
          loaded_person.videos.find(video.id)
        end

        context "when writing a new array value" do

          before do
            loaded_video.genres = [ "comedy" ]
            loaded_video.save!
          end

          it "sets the new value" do
            expect(loaded_video.genres).to eq([ "comedy" ])
          end

          it "persists the new value" do
            expect(loaded_video.reload.genres).to eq([ "comedy" ])
          end
        end
      end
    end
  end

  context "when destroying an embedded document" do

    let(:person) do
      Person.create!
    end

    let!(:address_one) do
      person.addresses.create!(street: "hobrecht")
    end

    let!(:address_two) do
      person.addresses.create!(street: "maybachufer")
    end

    before do
      address_one.destroy
    end

    it "destroys the document" do
      expect(address_one).to be_destroyed
    end

    it "reindexes the relation" do
      expect(address_two._index).to eq(0)
    end

    it "removes the document from the unscoped" do
      expect(person.addresses.send(:_unscoped)).to_not include(address_one)
    end

    context "when subsequently updating the next document" do

      before do
        address_two.update_attribute(:number, 10)
      end

      let(:addresses) do
        person.reload.addresses
      end

      it "updates the correct document" do
        expect(addresses.first.number).to eq(10)
      end

      it "does not add additional documents" do
        expect(addresses.count).to eq(1)
      end
    end
  end

  context "when destroying a document with multiple nil _ids" do
    let(:congress) { EmmCongress.create! }

    before do
      congress.legislators << EmmLegislator.new(_id: nil, a: 1)
      congress.legislators << EmmLegislator.new(_id: nil, a: 2)

      congress.legislators[0].destroy
    end

    it "deletes the correct document locally" do
      pending "MONGOID-5394"
      expect(congress.legislators.length).to eq(1)
      expect(congress.legislators.first.a).to eq(1)
    end

    it "only deletes the one document" do
      pending "MONGOID-5394"
      expect(congress.reload.legislators.length).to eq(1)
    end
  end

  context "when adding a document" do

    let(:person) do
      Person.new
    end

    let(:address_one) do
      Address.new(street: "hobrecht")
    end

    let(:first_add) do
      person.addresses.push(address_one)
    end

    context "when chaining a second add" do

      let(:address_two) do
        Address.new(street: "friedel")
      end

      let(:result) do
        first_add.push(address_two)
      end

      it "adds both documents" do
        expect(result).to eq([ address_one, address_two ])
      end
    end
  end

  context "when the association has an order defined" do

    let(:person) do
      Person.create!
    end

    let(:message_one) do
      Message.new(priority: 5, body: 'This is a test')
    end

    let(:message_two) do
      Message.new(priority: 10, body: 'This is a test')
    end

    let(:message_three) do
      Message.new(priority: 20, body: 'Zee test')
    end

    before do
      person.messages.push(message_one, message_two, message_three)
    end

    let(:criteria) do
      person.messages.order_by(:body.asc, :priority.desc)
    end

    it "properly orders the related objects" do
      expect(criteria.to_a).to eq([message_two, message_one, message_three])
    end

    context "when the field to order on is an array of documents" do

      before do
        person.aliases = [ { name: "A", priority: 3 }, { name: "B", priority: 4 }]
        person.save!
      end

      let!(:person2) do
        Person.create!( aliases: [ { name: "C", priority: 1 }, { name: "D", priority: 2 }])
      end

      it "allows ordering on a key of an embedded document" do
        expect(Person.all.order_by("aliases.0.priority" => 1).first).to eq(person2)
      end
    end
  end

  context "when using dot notation in a criteria" do

    let(:person) do
      Person.new
    end

    let!(:address) do
      person.addresses.build(street: "hobrecht")
    end

    let!(:location) do
      address.locations.build(number: 5)
    end

    let(:criteria) do
      person.addresses.where("locations.number" => { "$gt" => 3 })
    end

    it "allows the dot notation criteria" do
      expect(criteria).to eq([ address ])
    end
  end

  context "when updating multiple levels in one update" do

    let!(:person) do
      Person.create!(
          addresses: [
              { locations: [{ name: "home" }]}
          ]
      )
    end

    context "when updating with hashes" do

      let(:from_db) do
        Person.find(person.id)
      end

      before do
        from_db.update_attributes!(
            addresses: [
                { locations: [{ name: "work" }]}
            ]
        )
      end

      let(:updated) do
        person.reload.addresses.first.locations.first
      end

      it "updates the nested document" do
        expect(updated.name).to eq("work")
      end
    end
  end

  context "when the embedded relation sorts on a boolean" do

    let(:circuit) do
      Circuit.create!
    end

    let!(:bus_one) do
      circuit.buses.create!(saturday: true)
    end

    let!(:bus_two) do
      circuit.buses.create!(saturday: false)
    end

    it "orders properly with the boolean" do
      expect(circuit.reload.buses).to eq([ bus_two, bus_one ])
    end
  end

  context "when batch replacing multiple relations in a single update" do

    let(:document) do
      Person.create!
    end

    let(:person) do
      Person.find(document.id)
    end

    let!(:symptom_one) do
      person.symptoms.create!
    end

    let!(:symptom_two) do
      person.symptoms.create!
    end

    let!(:appointment_one) do
      person.appointments.create!
    end

    let!(:appointment_two) do
      person.appointments.create!
    end

    before do
      person.update_attributes!(
          appointments: [ appointment_one.as_document, appointment_two.as_document ],
          symptoms: [ symptom_one.as_document, symptom_two.as_document ]
      )
    end

    it "does not duplicate the first relation" do
      expect(person.reload.symptoms.count).to eq(2)
    end

    it "does not duplicate the second relation" do
      expect(person.reload.appointments.count).to eq(2)
    end
  end

  context "when pushing with a before_add callback" do

    let(:artist) do
      Artist.new
    end

    let(:song) do
      Song.new
    end

    context "when no errors are raised" do

      before do
        artist.songs << song
      end

      it "executes the callback" do
        expect(artist.before_add_called).to be true
      end

      it "executes the callback as proc" do
        expect(song.before_add_called).to be true
      end

      it "adds the document to the relation" do
        expect(artist.songs).to eq([song])
      end
    end

    context "with errors" do

      before do
        expect(artist).to receive(:before_add_song).and_raise
        begin; artist.songs << song; rescue; end
      end

      it "does not add the document to the relation" do
        expect(artist.songs).to be_empty
      end
    end
  end

  context "when pushing with an after_add callback" do

    let(:artist) do
      Artist.new
    end

    let(:label) do
      Label.new
    end

    it "executes the callback" do
      artist.labels << label
      expect(artist.after_add_called).to be true
    end

    context "when errors are raised" do

      before do
        expect(artist).to receive(:after_add_label).and_raise
        begin; artist.labels << label; rescue; end
      end

      it "adds the document to the relation" do
        expect(artist.labels).to eq([ label ])
      end
    end
  end

  context "#delete, or #clear, or #pop, or #shift with before_remove callback" do

    let(:artist) do
      Artist.new
    end

    let(:song) do
      Song.new
    end

    before do
      artist.songs << song
    end

    context "when no errors are raised" do

      describe "#delete" do

        before do
          artist.songs.delete(song)
        end

        it "executes the callback" do
          expect(artist.before_remove_embedded_called).to be true
        end

        it "removes the document from the relation" do
          expect(artist.songs).to be_empty
        end
      end

      describe "#clear" do

        before do
          artist.songs.clear
        end

        it "executes the callback" do
          expect(artist.before_remove_embedded_called).to be true
        end

        it "shoud clear the relation" do
          expect(artist.songs).to be_empty
        end
      end

      describe "#pop" do

        before do
          artist.songs.pop
        end

        it "executes the callback" do
          artist.songs.pop
          expect(artist.before_remove_embedded_called).to be true
        end
      end

      describe "#shift" do

        before do
          artist.songs.shift
        end

        it "executes the callback" do
          artist.songs.shift
          expect(artist.before_remove_embedded_called).to be true
        end
      end
    end

    context "when errors are raised" do

      before do
        expect(artist).to receive(:before_remove_song).and_raise
      end

      describe "#delete" do

        it "does not remove the document from the relation" do
          begin; artist.songs.delete(song); rescue; end
          expect(artist.songs).to eq([ song ])
        end
      end

      describe "#clear" do

        before do
          begin; artist.songs.clear; rescue; end
        end

        it "removes the documents from the relation" do
          expect(artist.songs).to eq([ song ])
        end
      end

      describe "#pop" do

        before do
          begin; artist.songs.pop; rescue; end
        end

        it "should remove from collection" do
          expect(artist.songs).to eq([ song ])
        end
      end

      describe "#shift" do

        before do
          begin; artist.songs.shift; rescue; end
        end

        it "should remove from collection" do
          expect(artist.songs).to eq([ song ])
        end
      end
    end
  end

  context "#delete, or #clear, or #pop, or #shift with after_remove callback" do

    let(:artist) do
      Artist.new
    end

    let(:label) do
      Label.new
    end

    before do
      artist.labels << label
    end

    context "when no errors are raised" do

      describe "#delete" do
        before do
          artist.labels.delete(label)
        end

        it "executes the callback" do
          expect(artist.after_remove_embedded_called).to be true
        end
      end

      describe "#clear" do

        before do
          artist.labels.clear
        end

        it "executes the callback" do
          artist.labels.clear
          expect(artist.after_remove_embedded_called).to be true
        end
      end

      describe "#pop" do

        before do
          artist.labels.pop
        end

        it "executes the callback" do
          artist.labels.pop
          expect(artist.after_remove_embedded_called).to be true
        end
      end

      describe "#shift" do

        before do
          artist.labels.shift
        end

        it "executes the callback" do
          artist.labels.shift
          expect(artist.after_remove_embedded_called).to be true
        end
      end
    end

    context "when errors are raised" do

      before do
        expect(artist).to receive(:after_remove_label).and_raise
      end

      describe "#delete" do

        before do
          begin; artist.labels.delete(label); rescue; end
        end

        it "removes the document from the relation" do
          expect(artist.labels).to be_empty
        end
      end

      describe "#clear" do

        before do
          begin; artist.labels.clear; rescue; end
        end

        it "should remove from collection" do
          expect(artist.labels).to be_empty
        end
      end

      describe "#pop" do

        before do
          begin; artist.labels.pop; rescue; end
        end

        it "should remove from collection" do
          expect(artist.labels).to be_empty
        end
      end

      describe "#shift" do

        before do
          begin; artist.labels.shift; rescue; end
        end

        it "should remove from collection" do
          expect(artist.labels).to be_empty
        end
      end
    end
  end

  context "when saving at the parent level" do

    let!(:server) do
      Server.new(name: "staging")
    end

    let!(:filesystem) do
      server.filesystems.build
    end

    context "when the parent has an after create callback" do

      before do
        server.save!
      end

      it "does not push the embedded documents twice" do
        expect(server.reload.filesystems.count).to eq(1)
      end
    end
  end

  context "when embedded documents are stored without ids" do

    let!(:band) do
      Band.create!(name: "Moderat")
    end

    before do
      band.collection.
          find(_id: band.id).
          update_one("$set" => { records: [{ _id: BSON::ObjectId.new, name: "Moderat" }]})
    end

    context "when loading the documents" do

      before do
        band.reload
      end

      let(:record) do
        band.records.first
      end

      it "creates proper documents from the db" do
        expect(record.name).to eq("Moderat")
      end

      it "assigns ids to the documents" do
        expect(record.id).to_not be_nil
      end

      context "when subsequently updating the documents" do

        before do
          record.update_attribute(:name, "Apparat")
        end

        it "updates the document" do
          expect(record.name).to eq("Apparat")
        end

        it "persists the change" do
          expect(record.reload.name).to eq("Apparat")
        end
      end
    end
  end

  context "deleting embedded documents" do

    it "able to delete embedded documents upon condition" do
      company = Company.new
      4.times { |i| company.staffs << Staff.new(age: 50 + i)}
      2.times { |i| company.staffs << Staff.new(age: 40)}
      company.save!
      company.staffs.delete_if {|x| x.age >= 50}
      expect(company.staffs.count).to eq(2)
    end
  end

  context "when substituting polymorphic documents" do

    before(:all) do
      class DNS; end

      class DNS::Zone
        include Mongoid::Document
        embeds_many :rrsets, class_name: 'DNS::RRSet',  inverse_of: :zone
        embeds_one  :soa,    class_name: 'DNS::Record', as: :container
      end

      class DNS::RRSet
        include Mongoid::Document
        embedded_in :zone, class_name: 'DNS::Zone',   inverse_of: :rrsets
        embeds_many :records, class_name: 'DNS::Record', as: :container
      end

      class DNS::Record
        include Mongoid::Document
        embedded_in :container, polymorphic: true
      end
    end

    after(:all) do
      Object.send(:remove_const, :DNS)
    end

    context "when the parent is new" do

      let(:zone) do
        DNS::Zone.new
      end

      let(:soa_1) do
        DNS::Record.new
      end

      context "when replacing the set document" do

        let(:soa_2) do
          DNS::Record.new
        end

        before do
          zone.soa = soa_1
        end

        it "properly sets the association metadata" do
          expect(zone.soa = soa_2).to eq(soa_2)
        end
      end

      context "when deleting the set document" do

        let(:soa_2) do
          DNS::Record.new
        end

        before do
          zone.soa = soa_1
        end

        it "properly sets the association metadata" do
          expect(zone.soa.delete).to be true
        end
      end
    end

    context "when the parent is persisted" do

      let(:zone) do
        DNS::Zone.create!
      end

      let(:soa_1) do
        DNS::Record.new
      end

      context "when replacing the set document" do

        let(:soa_2) do
          DNS::Record.new
        end

        before do
          zone.soa = soa_1
        end

        it "properly sets the association" do
          expect(zone.soa = soa_2).to eq(soa_2)
        end
      end

      context "when deleting the set document" do

        let(:soa_2) do
          DNS::Record.new
        end

        before do
          zone.soa = soa_1
        end

        it "properly sets the association" do
          expect(zone.soa.delete).to be true
        end
      end
    end
  end

  context "when trying to persist the empty list" do

    context "in an embeds_many relation" do

      let(:band) { Band.create! }

      before do
        band.labels = []
        band.save!
      end

      let(:reloaded_band) { Band.collection.find(_id: band._id).first }

      it "persists the empty list" do
        expect(reloaded_band).to have_key(:labels)
        expect(reloaded_band[:labels]).to eq []
      end
    end

    context "in a nested embeds_many relation" do

      let(:survey) { Survey.create!(questions: [Question.new]) }

      before do
        survey.questions.first.answers = []
        survey.save!
      end

      let(:reloaded_survey) { Survey.collection.find(_id: survey._id).first }

      it "persists the empty list" do
        expect(reloaded_survey).to have_key(:questions)
        expect(reloaded_survey[:questions][0]).to have_key(:answers)
        expect(reloaded_survey[:questions][0][:answers]).to eq []
      end
    end

    context "when not setting the embeds_many field" do

      let(:band) { Band.create! }

      let(:reloaded_band) { Band.collection.find(_id: band._id).first }

      it "does not persist the empty list" do
        expect(reloaded_band).to_not have_key(:labels)
      end
    end
  end

  context "when using assign_attributes with an already populated array" do
    let(:post) { EmmPost.create! }

    before do
      post.assign_attributes(company_tags: [{id: BSON::ObjectId.new, title: 'a'}],
        user_tags: [{id: BSON::ObjectId.new, title: 'b'}])
      post.save!
      post.reload
      post.assign_attributes(company_tags: [{id: BSON::ObjectId.new, title: 'c'}],
        user_tags: [])
      post.save!
      post.reload
    end

    it "has the correct embedded documents" do
      expect(post.company_tags.length).to eq(1)
      expect(post.company_tags.first.title).to eq("c")
    end
  end

  context "when the parent fails validation" do
    let(:school) { EmmSchool.new }
    let(:student) { school.students.new }

    before do
      student.save
    end

    it "does not mark the parent as persisted" do
      expect(school.persisted?).to be false
    end

    it "does not mark the child as persisted" do
      expect(student.persisted?).to be false
    end

    it "does not persist the parent" do
      expect(School.count).to eq(0)
    end
  end

  context "when doing assign_attributes then assignment" do

    let(:post) do
      EmmPost.create!(
        company_tags: [ EmmCompanyTag.new(title: "1"), EmmCompanyTag.new(title: "1") ],
        user_tags: [ EmmUserTag.new(title: "1"), EmmUserTag.new(title: "1") ]
      )
    end

    let(:from_db) { EmmPost.find(post.id) }

    before do
      post.assign_attributes(
        company_tags: [ EmmCompanyTag.new(title: '3'), EmmCompanyTag.new(title: '4') ]
      )
      post.user_tags = [ EmmUserTag.new(title: '3'), EmmUserTag.new(title: '4') ]
      post.save!
    end

    it "persists the associations correctly" do
      expect(from_db.user_tags.size).to eq(2)
      expect(from_db.company_tags.size).to eq(2)
    end
  end

  context "when assigning hashes" do
    let(:user) { EmmUser.create! }

    before do
      user.orders = [ { sku: 1 }, { sku: 2 } ]
    end

    it "creates the objects correctly" do
      expect(user.orders.first).to be_a(EmmOrder)
      expect(user.orders.last).to be_a(EmmOrder)

      expect(user.orders.map(&:sku).sort).to eq([ 1, 2 ])
    end
  end
end
