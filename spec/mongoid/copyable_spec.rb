# -*- coding: utf-8 -*-
require "spec_helper"

describe Mongoid::Copyable do

  [ :clone, :dup ].each do |method|

    describe "##{method}" do

      let(:person) do
        Person.new(
          title: "Sir",
          version: 4,
          created_at: Time.now,
          updated_at: Time.now,
          desc: "description"
        ) do |p|
          p.owner_id = 5
        end
      end

      let!(:address) do
        person.addresses.build(street: "Bond")
      end

      let!(:name) do
        person.build_name(first_name: "Judy")
      end

      let!(:posts) do
        person.posts.build(title: "testing")
      end

      let!(:game) do
        person.build_game(name: "Tron")
      end

      context "when the document has an id field in the database" do

        let!(:band) do
          Band.create(name: "Tool")
        end

        before do
          Band.collection.find(_id: band.id).update("$set" => { "id" => 1234 })
        end

        let!(:cloned) do
          band.reload.send(method)
        end

        it "does not set the id field as the _id" do
          expect(cloned.id).to_not eq(1234)
        end
      end

      context "when cloning a document with multiple languages field" do

        before do
          I18n.locale = 'pt_BR'
          person.desc = "descrição"
          person.save
        end

        after do
          I18n.locale = :en
        end

        let!(:from_db) do
          Person.find(person.id)
        end

        let(:copy) do
          from_db.send(method)
        end

        it "sets the pt_BR version" do
          I18n.locale = 'pt_BR'
          expect(copy.desc).to eq("descrição")
        end

        it "sets the english version" do
          I18n.locale = :en
          expect(copy.desc).to eq("description")
        end

        it "sets to nil an nonexistent lang" do
          I18n.locale = :fr
          expect(copy.desc).to be_nil
        end
      end

      context "when cloning a loaded document" do

        before do
          person.save
        end

        let!(:from_db) do
          Person.find(person.id)
        end

        let(:copy) do
          from_db.send(method)
        end

        it "marks the fields as dirty" do
          expect(copy.changes["age"]).to eq([ nil, 100 ])
        end

        it "flags the document as changed" do
          expect(copy).to be_changed
        end

        it "copies protected fields" do
          expect(copy.owner_id).to eq(5)
        end
      end

      context "when the document is new" do

        context "when there are changes" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { number: 1 } ]
          end

          it "returns a new document" do
            expect(copy).to_not be_persisted
          end

          it "has an id" do
            expect(copy.id).to_not be_nil
          end

          it "flags the document as changed" do
            expect(copy).to be_changed
          end

          it "marks fields as dirty" do
            expect(copy.changes["age"]).to eq([ nil, 100 ])
          end

          it "has a different id from the original" do
            expect(copy.id).to_not eq(person.id)
          end

          it "returns a new instance" do
            expect(copy).to_not be_eql(person)
          end

          it "copys embeds many documents" do
            expect(copy.addresses).to eq(person.addresses)
          end

          it "sets the embedded many documents as new" do
            expect(copy.addresses.first).to be_new_record
          end

          it "creates new embeds many instances" do
            expect(copy.addresses).to_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            expect(copy.name).to eq(person.name)
          end

          it "flags the embeds one documents as new" do
            expect(copy.name).to be_new_record
          end

          it "creates a new embeds one instance" do
            expect(copy.name).to_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            expect(copy.posts).to be_empty
          end

          it "does not copy references one documents" do
            expect(copy.game).to be_nil
          end

          it "copies localized fields" do
            expect(copy.desc).to eq("description")
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save(validate: false)
            end

            it "persists the attributes" do
              expect(reloaded.title).to eq("Sir")
            end

            it "persists the embeds many relation" do
              expect(reloaded.addresses).to eq(person.addresses)
            end

            it "persists the embeds one relation" do
              expect(reloaded.name).to eq(person.name)
            end
          end
        end
      end

      context "when the document is not new" do

        before do
          person.new_record = false
        end

        context "when a dynamic field exists and attributes are dynamic" do
          let(:copy) do
            person.send(method)
          end
          before do
            person[:unmapped_attribute] = true
          end
          it "copies the dynamic field" do
            expect(copy[:unmapped_attribute]).to eq(true)
          end
        end

        context "when a dynamic field exists and attributes are not dynamic" do
          let(:pet) do
            Animal.new
          end
          before do
            pet.new_record = false
            pet[:unmapped_attribute] = true
          end
          let(:copy) do
            pet.send(method)
          end
          it "does not raise an error" do
            expect { copy }.to_not raise_error
          end
          it "does not copy the dynamic field" do
            expect(copy[:unmapped_attribute]).to eq(nil)
          end
        end

        context "when there are changes" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { number: 1 } ]
          end

          it "flags the document as changed" do
            expect(copy).to be_changed
          end

          it "marks fields as dirty" do
            expect(copy.changes["age"]).to eq([ nil, 100 ])
          end

          it "returns a new document" do
            expect(copy).to_not be_persisted
          end

          it "has an id" do
            expect(copy.id).to_not be_nil
          end

          it "has a different id from the original" do
            expect(copy.id).to_not eq(person.id)
          end

          it "returns a new instance" do
            expect(copy).to_not be_eql(person)
          end

          it "copys embeds many documents" do
            expect(copy.addresses).to eq(person.addresses)
          end

          it "creates new embeds many instances" do
            expect(copy.addresses).to_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            expect(copy.name).to eq(person.name)
          end

          it "creates a new embeds one instance" do
            expect(copy.name).to_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            expect(copy.posts).to be_empty
          end

          it "does not copy references one documents" do
            expect(copy.game).to be_nil
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save(validate: false)
            end

            it "persists the attributes" do
              expect(reloaded.title).to eq("Sir")
            end

            it "persists the embeds many relation" do
              expect(reloaded.addresses).to eq(person.addresses)
            end

            it "persists the embeds one relation" do
              expect(reloaded.name).to eq(person.name)
            end
          end
        end
      end

      context "when the document is frozen" do

        let!(:copy) do
          person.freeze.send(method)
        end

        it "returns a new document" do
          expect(copy).to_not be_persisted
        end

        it "has an id" do
          expect(copy.id).to_not be_nil
        end

        it "has a different id from the original" do
          expect(copy.id).to_not eq(person.id)
        end

        it "returns a new instance" do
          expect(copy).to_not be_eql(person)
        end

        it "copys embeds many documents" do
          expect(copy.addresses).to eq(person.addresses)
        end

        it "creates new embeds many instances" do
          expect(copy.addresses).to_not equal(person.addresses)
        end

        it "copys embeds one documents" do
          expect(copy.name).to eq(person.name)
        end

        it "creates a new embeds one instance" do
          expect(copy.name).to_not equal(person.name)
        end

        it "does not copy referenced many documents" do
          expect(copy.posts).to be_empty
        end

        it "does not copy references one documents" do
          expect(copy.game).to be_nil
        end

        it "keeps the original attributes frozen" do
          expect(person.attributes).to be_frozen
        end

        context "when saving the copy" do

          let(:reloaded) do
            copy.reload
          end

          before do
            copy.save(validate: false)
          end

          it "persists the attributes" do
            expect(reloaded.title).to eq("Sir")
          end

          it "persists the embeds many relation" do
            expect(reloaded.addresses).to eq(person.addresses)
          end

          it "persists the embeds one relation" do
            expect(reloaded.name).to eq(person.name)
          end
        end
      end

      context "when cloning a document with embeds_one relation" do

        let(:clone) do
          person.clone
        end

        it "should clone embedded document" do
          expect(clone.name).to eq person.name
        end

        it "should clone embedded document's fields" do
          expect(clone.name.fields.keys).to eq person.name.fields.keys
        end

        it "should clone embedded document's dynamic fields" do
          class Name
            include Mongoid::Attributes::Dynamic
          end

          name[:unmapped_attribute] = true
          name.save!

          expect(clone.name[:unmapped_attribute]).to eq name[:unmapped_attribute]
        end

        it "should not clone embedded document's changed fields" do
          name = person.name
          name.unset('first_name')
          name.save!

          expect(clone.name.first_name).to eq nil
        end

        it "should not clone nil relation" do
          expect(person.pet).to eq nil
          expect(clone.pet).to eq nil
        end

      end

      context "when cloning a document" do

        let(:clone) do
          person.clone
        end

        it "should clone dynamic fields" do
          person[:unmapped_attribute] = true
          person.save!

          expect(clone[:unmapped_attribute]).to eq person[:unmapped_attribute]
        end

        it "should not clone changed fields" do
          person.unset('title')
          person.save!

          expect(clone.title).to eq nil
        end

      end

      context "when cloning a document with embeds_many relation" do

        let(:clone) do
          person.clone
        end

        it "should clone embedded documents" do
          expect(clone.addresses.size).to eq person.addresses.size
        end

        it "should clone embedded documents' fields" do
          expect(clone.addresses.first.fields.keys).to eq person.addresses.first.fields.keys
        end

        it "should clone embedded documents' dynamic fields" do
          class Address
            include Mongoid::Attributes::Dynamic
          end

          address[:unmapped_attribute] = true
          address.save!

          expect(clone.addresses.first[:unmapped_attribute]).to eq address[:unmapped_attribute]
        end

        it "should not clone embedded documents' changed fields" do
          address = person.addresses.first
          address.unset('street')
          address.save!

          expect(clone.addresses.first.street).to eq nil
        end

        it "should not clone empty relations" do
          expect(person.messages.empty?).to eq true
          expect(clone.messages.empty?).to eq true
        end
      end
    end
  end
end
