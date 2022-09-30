# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Serializable do

  describe "#field_names" do

    let(:guitar) do
      Guitar.new
    end

    it "does not duplicate fields" do
      expect(guitar.send(:field_names, {})).to eq(guitar.fields.except("_type").keys.sort)
    end

    context "when using a custom discriminator_key" do
      before do
        Instrument.discriminator_key = "dkey"
      end

      after do
        Instrument.discriminator_key = nil
      end

      let(:guitar) do
        Guitar.new
      end

      it "includes _type but does not include the new discriminator key" do
        expect(guitar.send(:field_names, {})).to eq(guitar.fields.except("dkey").keys.sort)
      end
    end
  end

  %i(include_root_in_json include_root_in_json?).each do |meth|
    describe ".#{meth}" do

      before do
        reload_model(:Minim)
      end

      after do
        reload_model(:Minim)
      end

      context "when global config is set to true" do
        config_override :include_root_in_json, true

        it "returns true" do
          expect(Minim.public_send(meth)).to be true
        end

        context 'when value is overridden to false in the model class' do
          before do
            Minim.include_root_in_json = false
          end

          it 'returns false' do
            expect(Minim.public_send(meth)).to be false
          end
        end
      end

      context "when global config set to false" do
        config_override :include_root_in_json, false

        it "returns false" do
          expect(Minim.public_send(meth)).to be false
        end

        context 'when value is overridden to true in the model class' do
          before do
            Minim.include_root_in_json = true
          end

          it 'returns true' do
            expect(Minim.public_send(meth)).to be true
          end
        end
      end
    end

    describe "#include_root_in_json" do
      config_override :include_root_in_json, false

      before do
        reload_model(:Minim)
      end

      after do
        reload_model(:Minim)
      end

      let(:minim) do
        Minim.new
      end

      context "when global config is set to true" do

        before do
          Minim.include_root_in_json.should be false
          Mongoid.include_root_in_json = true
        end

        it "returns true" do
          expect(minim.public_send(meth)).to be true
        end

        context 'when value is overridden to false in the model class' do
          before do
            Minim.include_root_in_json = false
          end

          it 'returns false' do
            expect(minim.public_send(meth)).to be false
          end
        end
      end

      context "when global config set to false" do

        it "returns false" do
          expect(minim.public_send(meth)).to be false
        end

        context 'when value is overridden to true in the model class' do
          before do
            Minim.include_root_in_json = true
          end

          it 'returns true' do
            expect(minim.public_send(meth)).to be true
          end
        end
      end
    end
  end

  describe "#serializable_hash" do

    let(:person) do
      Person.new
    end

    context "when a dynamic attribute has the same name as a ruby method" do

      before do
        person[:loop] = "testing"
      end

      let(:attributes) do
        person.serializable_hash
      end

      it "grabs the attribute direct from the hash" do
        expect(attributes["loop"]).to eq("testing")
      end
    end

    context "when the method for a declared field is overridden" do

      before do
        person.override_me = 1
      end

      let(:attributes) do
        person.serializable_hash
      end

      it "uses the overridden method" do
        expect(attributes["override_me"]).to eq("1")
      end
    end

    context "when the model has embedded documents" do

      let!(:address) do
        person.addresses.build(street: "test")
      end

      context "when providing no custom options" do

        let(:attributes) do
          person.serializable_hash
        end

        it "includes the embedded documents" do
          expect(attributes["addresses"].first).to eq(address.serializable_hash)
        end
      end

      context "when providing options" do

        let(:attributes) do
          person.serializable_hash(methods: :id, except: :_id)
        end

        let(:address_attributes) do
          attributes["addresses"].first
        end

        it "uses the options" do
          expect(attributes["id"]).to eq(person.id)
        end

        it "uses the options on embedded documents" do
          expect(address_attributes["id"]).to eq(address.id)
        end
      end

      context "when nested multiple levels" do

        let!(:location) do
          address.locations.build(name: "home")
        end

        let(:attributes) do
          person.serializable_hash
        end

        it "includes the deeply nested document" do
          expect(attributes["addresses"][0]["locations"]).to_not be_empty
        end
      end
    end

    context "when the model has attributes that need conversion" do

      let(:date) do
        Date.new(1970, 1, 1)
      end

      before do
        person.dob = date
      end

      let(:attributes) do
        person.serializable_hash
      end

      it "converts the objects to the defined type" do
        expect(attributes["dob"]).to eq(date)
      end
    end

    context "when a model has defined fields" do

      let(:attributes) do
        { "title" => "President", "security_code" => "1234" }
      end

      before do
        person.write_attributes(attributes)
      end

      let(:field_names) do
        person.fields.keys.map(&:to_s) - ["_type"]
      end

      it "serializes assigned attributes" do
        expect(person.serializable_hash).to include attributes
      end

      it "includes all defined fields except _type" do
        expect(person.serializable_hash.keys).to include(*field_names)
      end

      it "does not include _type" do
        expect(person.serializable_hash.keys).to_not include "_type"
      end

      context "when providing options" do

        let(:options) do
          { only: :name }
        end

        before do
          person.serializable_hash(options)
        end

        it "does not modify the options in the argument" do
          expect(options[:except]).to be_nil
        end
      end

      context "when include_type_for_serialization is true" do
        config_override :include_type_for_serialization, true

        it "includes _type field" do
          expect(person.serializable_hash.keys).to include '_type'
        end
      end

      context "when specifying which fields to only include" do

        it "only includes the specified fields" do
          expect(person.serializable_hash(only: [:title])).to eq(
            { "title" => attributes["title"] }
          )
        end
      end

      context "when specifying extra inclusions" do

        it "includes the extra fields" do
          expect(person.serializable_hash(
            methods: [ :_type ]
          ).has_key?("_type")).to be true
        end
      end

      context "when specifying which fields to exclude" do

        it "excludes the specified fields" do
          expect(person.serializable_hash(except: [:title])).to_not include(
            "title" => attributes["title"]
          )
        end
      end

      context "when only two attributes are loaded" do
        before do
          person.save!
        end

        let(:from_db) do
          Person.only("_id", "username").first
        end

        let(:hash) do
          from_db.serializable_hash
        end

        it "returns those two attributes only" do
          expect(hash.keys).to eq(["_id", "username"])
        end
      end
    end

    context "when a model has dynamic fields" do

      let(:dynamic_field_name) do
        "dynamic_field_name"
      end

      let(:dynamic_value) do
        "dynamic_value"
      end

      before do
        person.write_attribute(dynamic_field_name, dynamic_value)
      end

      it "includes dynamic fields" do
        expect(person.serializable_hash[dynamic_field_name]).to eq(dynamic_value)
      end

      context "when specifying which dynamic fields to only include" do

        it "only includes the specified dynamic fields" do
          expect(person.serializable_hash(only: [dynamic_field_name])).to eq(
            { dynamic_field_name => dynamic_value }
          )
        end
      end

      context "when specified which dynamic fields to exclude" do

        it "excludes the specified fields" do
          expect(person.serializable_hash(except: [dynamic_field_name])).to_not include(
            dynamic_field_name => dynamic_value
          )
        end
      end
    end

    context "when a model has relations" do

      let(:attributes) do
        { "title" => "President", "security_code" => "1234" }
      end

      before do
        person.write_attributes(attributes)
      end

      context "when the model is saved before the relation is added" do

        before do
          person.save!
        end

        context "when a model has an embeds many" do

          let!(:address_one) do
            person.addresses.build(street: "Kudamm")
          end

          before do
            person.save!
          end

          it "includes the relation" do
            expect(person.serializable_hash.keys).to include('addresses')
          end
        end

        context "when a model has an embeds one" do
          let!(:name) do
            person.build_name(first_name: "Leo", last_name: "Marvin")
          end

          before do
            person.save!
          end

          it "includes the relation" do
            expect(person.serializable_hash.keys).to include('name')
          end
        end
      end

      context "when the model is saved after the relation is added" do

        context "when a model has an embeds many" do

          let!(:address_one) do
            person.addresses.build(street: "Kudamm")
          end

          before do
            person.save!
          end

          it "includes the relation" do
            expect(person.serializable_hash.keys).to include('addresses')
          end
        end

        context "when a model has an embeds one" do
          let!(:name) do
            person.build_name(first_name: "Leo", last_name: "Marvin")
          end

          before do
            person.save!
          end

          it "includes the relation" do
            expect(person.serializable_hash.keys).to include('name')
          end
        end
      end
    end

    context "when including methods" do

      it "includes the method result" do
        expect(person.serializable_hash(methods: [:foo])).to include(
          "foo" => person.foo
        )
      end
    end

    context "when including relations" do

      context "when including a single relation" do

        context "when including an embeds many" do

          let!(:address_one) do
            person.addresses.build(street: "Kudamm")
          end

          let!(:address_two) do
            person.addresses.build(street: "Tauentzienstr")
          end

          let(:relation_hash) do
            hash["addresses"]
          end

          context "when the ids were not loaded" do

            before do
              person.save!
            end

            let(:from_db) do
              Person.only("addresses.street").first
            end

            let(:hash) do
              from_db.serializable_hash
            end

            it "does not generate new ids" do
              pending
              fail
              expect(hash["addresses"].first["_id"]).to be_nil
            end
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(include: :addresses)
            end

            it "includes the first relation" do
              expect(relation_hash[0]).to include
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              expect(relation_hash[1]).to include
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :addresses ])
            end

            it "includes the first relation" do
              expect(relation_hash[0]).to include
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              expect(relation_hash[1]).to include
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as a hash" do

            context "when including one level deep" do

              let(:hash) do
                person.serializable_hash(include: { addresses: { except: :_id } })
              end

              it "includes the first relation sans exceptions" do
                expect(relation_hash[0]).to include({ "street" => "Kudamm" })
              end

              it "includes the second relation sans exceptions" do
                expect(relation_hash[1]).to include({ "street" => "Tauentzienstr" })
              end
            end

            context "when including multiple levels deep" do

              let!(:location) do
                address_one.locations.build(name: "Home")
              end

              let(:hash) do
                person.serializable_hash(
                  include: { addresses: {
                    except: :_id, include: { locations: { except: :_id } }
                  }
                })
              end

              it "includes the first relation" do
                expect(relation_hash[0]["locations"].any? do |location|
                  location["name"] == "Home"
                end).to be true
              end

              context "after retrieved from database" do

                let(:db_person) do
                  Person.all.last
                end

                let!(:second_location) do
                  address_two.locations.build(name: "Hotel")
                end

                let(:hash) do
                  db_person.serializable_hash(
                    include: { addresses: {
                      except: :_id, include: { locations: { except: :_id } }
                    }
                  })
                end

                before do
                  person.save!
                end

                it "includes the specific relations" do
                  expect(relation_hash[0]["locations"].map do |location|
                    location["name"]
                  end).to include "Home"
                  expect(relation_hash[1]["locations"].map do |location|
                    location["name"]
                  end).to include "Hotel"
                end
              end
            end

            context "when defining a default exclusion" do

              let!(:name) do
                person.build_name(first_name: "Sebastien")
              end

              let(:hash) do
                person.serializable_hash(
                  except: :_id,
                  include: [ :addresses, :name ]
                )
              end

              it "does not contain the root exclusion" do
                expect(hash["_id"]).to be_nil
              end

              it "does not include the embedded many exclusion" do
                expect(relation_hash[0]["_id"]).to be_nil
              end

              it "does not include the embedded one exclusion" do
                expect(hash["name"]["_id"]).to be_nil
              end
            end
          end
        end

        context "when including an embeds one" do

          let!(:name) do
            person.build_name(first_name: "Leo", last_name: "Marvin")
          end

          let(:relation_hash) do
            hash["name"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(include: :name)
            end

            it "includes the specified relation" do
              expect(relation_hash).to include
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :name ])
            end

            it "includes the specified relation" do
              expect(relation_hash).to include
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(include: { name: { except: :_id }})
            end

            it "includes the specified relation sans exceptions" do
              expect(relation_hash).to include
                { "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end
        end

        context "when including a references many" do

          let!(:post_one) do
            person.posts.build(title: "First")
          end

          let!(:post_two) do
            person.posts.build(title: "Second")
          end

          let(:relation_hash) do
            hash["posts"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(include: :posts)
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["title"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["title"]).to eq("Second")
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :posts ])
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["title"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["title"]).to eq("Second")
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(include: { posts: { except: :_id } })
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["title"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["title"]).to eq("Second")
            end

            it "does not include the first document exceptions" do
              expect(relation_hash[0]["_id"]).to be_nil
            end

            it "does not include the second document exceptions" do
              expect(relation_hash[1]["_id"]).to be_nil
            end
          end
        end

        context "when including a references many to many" do

          let!(:preference_one) do
            person.preferences.build(name: "First")
          end

          let!(:preference_two) do
            person.preferences.build(name: "Second")
          end

          let(:relation_hash) do
            hash["preferences"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(include: :preferences)
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["name"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["name"]).to eq("Second")
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :preferences ])
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["name"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["name"]).to eq("Second")
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(
                include: {
                  preferences: {
                    except: :_id
                  }
                },
                except: :preference_ids
              )
            end

            it "includes the specified relation" do
              expect(relation_hash).to_not be_nil
            end

            it "includes the first document related fields" do
              expect(relation_hash[0]["name"]).to eq("First")
            end

            it "includes the second document related fields" do
              expect(relation_hash[1]["name"]).to eq("Second")
            end

            it "does not include the first document exceptions" do
              expect(relation_hash[0]["_id"]).to be_nil
            end

            it "does not include the second document exceptions" do
              expect(relation_hash[1]["_id"]).to be_nil
            end

            it "does not include the root exceptions" do
              expect(hash["preference_ids"]).to be_nil
            end
          end
        end
      end
    end
  end

  describe "#to_json" do

    let(:account) do
      Account.new
    end

    context "when including root in json via Mongoid" do
      config_override :include_root_in_json, false

      before do
        account.include_root_in_json.should be false
        Mongoid.include_root_in_json = true
      end

      it "uses the mongoid configuration" do
        expect(JSON.parse(account.to_json)).to have_key("account")
      end
    end

    context "when including root in json via class" do

      before do
        account.include_root_in_json.should be false
        Account.include_root_in_json = true
      end

      after do
        Account.include_root_in_json = false
      end

      it "uses the class configuration" do
        expect(JSON.parse(account.to_json)).to have_key("account")
      end
    end

    context "when not including root in json" do

      before do
        account.include_root_in_json.should be false
      end

      it "uses the mongoid configuration" do
        expect(JSON.parse(account.to_json)).not_to have_key("account")
      end
    end

    let(:person) do
      Person.new
    end

    context "when serializing a relation directly" do

      context "when serializing an embeds many" do

        let!(:address) do
          person.addresses.build(street: "Kudamm")
        end

        let(:json) do
          person.addresses.to_json
        end

        it "serializes only the relation" do
          expect(json).to include(address.street)
        end
      end

      context "when serializing a references many" do

        let!(:post) do
          person.posts.build(title: "testing")
        end

        let(:json) do
          person.posts.to_json
        end

        it "serializes only the relation" do
          expect(json).to include(post.title)
        end
      end
    end
  end
end
