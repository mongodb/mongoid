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
          cloned.id.should_not eq(1234)
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
          copy.desc.should eq("descrição")
        end

        it "sets the english version" do
          I18n.locale = :en
          copy.desc.should eq("description")
        end

        it "sets to nil an nonexistent lang" do
          I18n.locale = :fr
          copy.desc.should be_nil
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
          copy.changes["age"].should eq([ nil, 100 ])
        end

        it "flags the document as changed" do
          copy.should be_changed
        end

        it "copies protected fields" do
          copy.owner_id.should eq(5)
        end
      end

      context "when the document is new" do

        context "when versions exist" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { number: 1 } ]
          end

          it "returns a new document" do
            copy.should_not be_persisted
          end

          it "has an id" do
            copy.id.should_not be_nil
          end

          it "flags the document as changed" do
            copy.should be_changed
          end

          it "marks fields as dirty" do
            copy.changes["age"].should eq([ nil, 100 ])
          end

          it "has a different id from the original" do
            copy.id.should_not eq(person.id)
          end

          it "does not copy the versions" do
            copy[:versions].should be_nil
          end

          it "resets the document version" do
            copy.version.should eq(1)
          end

          it "returns a new instance" do
            copy.should_not be_eql(person)
          end

          it "copys embeds many documents" do
            copy.addresses.should eq(person.addresses)
          end

          it "sets the embedded many documents as new" do
            copy.addresses.first.should be_new_record
          end

          it "creates new embeds many instances" do
            copy.addresses.should_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            copy.name.should eq(person.name)
          end

          it "flags the embeds one documents as new" do
            copy.name.should be_new_record
          end

          it "creates a new embeds one instance" do
            copy.name.should_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            copy.posts.should be_empty
          end

          it "does not copy references one documents" do
            copy.game.should be_nil
          end

          it "copies localized fields" do
            copy.desc.should eq("description")
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save(validate: false)
            end

            it "persists the attributes" do
              reloaded.title.should eq("Sir")
            end

            it "persists the embeds many relation" do
              reloaded.addresses.should eq(person.addresses)
            end

            it "persists the embeds one relation" do
              reloaded.name.should eq(person.name)
            end
          end
        end
      end

      context "when the document is not new" do

        before do
          person.new_record = false
        end

        context "when versions exist" do

          let(:copy) do
            person.send(method)
          end

          before do
            person[:versions] = [ { number: 1 } ]
          end

          it "flags the document as changed" do
            copy.should be_changed
          end

          it "marks fields as dirty" do
            copy.changes["age"].should eq([ nil, 100 ])
          end

          it "returns a new document" do
            copy.should_not be_persisted
          end

          it "has an id" do
            copy.id.should_not be_nil
          end

          it "has a different id from the original" do
            copy.id.should_not eq(person.id)
          end

          it "does not copy the versions" do
            copy[:versions].should be_nil
          end

          it "returns a new instance" do
            copy.should_not be_eql(person)
          end

          it "copys embeds many documents" do
            copy.addresses.should eq(person.addresses)
          end

          it "creates new embeds many instances" do
            copy.addresses.should_not equal(person.addresses)
          end

          it "copys embeds one documents" do
            copy.name.should eq(person.name)
          end

          it "creates a new embeds one instance" do
            copy.name.should_not equal(person.name)
          end

          it "does not copy referenced many documents" do
            copy.posts.should be_empty
          end

          it "does not copy references one documents" do
            copy.game.should be_nil
          end

          context "when saving the copy" do

            let(:reloaded) do
              copy.reload
            end

            before do
              copy.save(validate: false)
            end

            it "persists the attributes" do
              reloaded.title.should eq("Sir")
            end

            it "persists the embeds many relation" do
              reloaded.addresses.should eq(person.addresses)
            end

            it "persists the embeds one relation" do
              reloaded.name.should eq(person.name)
            end
          end
        end
      end

      context "when the document is frozen" do

        let!(:copy) do
          person.freeze.send(method)
        end

        it "returns a new document" do
          copy.should_not be_persisted
        end

        it "has an id" do
          copy.id.should_not be_nil
        end

        it "has a different id from the original" do
          copy.id.should_not eq(person.id)
        end

        it "returns a new instance" do
          copy.should_not be_eql(person)
        end

        it "copys embeds many documents" do
          copy.addresses.should eq(person.addresses)
        end

        it "creates new embeds many instances" do
          copy.addresses.should_not equal(person.addresses)
        end

        it "copys embeds one documents" do
          copy.name.should eq(person.name)
        end

        it "creates a new embeds one instance" do
          copy.name.should_not equal(person.name)
        end

        it "does not copy referenced many documents" do
          copy.posts.should be_empty
        end

        it "does not copy references one documents" do
          copy.game.should be_nil
        end

        it "keeps the original attributes frozen" do
          person.attributes.should be_frozen
        end

        context "when saving the copy" do

          let(:reloaded) do
            copy.reload
          end

          before do
            copy.save(validate: false)
          end

          it "persists the attributes" do
            reloaded.title.should eq("Sir")
          end

          it "persists the embeds many relation" do
            reloaded.addresses.should eq(person.addresses)
          end

          it "persists the embeds one relation" do
            reloaded.name.should eq(person.name)
          end
        end
      end
    end
  end
end
