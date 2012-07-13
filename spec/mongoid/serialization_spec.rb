require "spec_helper"

describe Mongoid::Serialization do

  describe "#field_names" do

    let(:band) do
      Band.new
    end

    it "does not duplicate fields" do
      band.send(:field_names, {}).should eq(band.fields.except("_type").keys.sort)
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
        attributes["loop"].should eq("testing")
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
        attributes["override_me"].should eq("1")
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
          attributes["addresses"].first.should eq(address.serializable_hash)
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
          attributes["id"].should eq(person.id)
        end

        it "uses the options on embedded documents" do
          address_attributes["id"].should eq(address.id)
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
          attributes["addresses"][0]["locations"].should_not be_empty
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
        attributes["dob"].should eq(date)
      end
    end

    context "when a model has defined fields" do

      let(:attributes) do
        { "title" => "President", "security_code" => "1234" }
      end

      before do
        person.write_attributes(attributes, false)
      end

      let(:field_names) do
        person.fields.keys.map(&:to_s) - ["_type"]
      end

      it "serializes assigned attributes" do
        person.serializable_hash.should include attributes
      end

      it "includes all defined fields except _type" do
        person.serializable_hash.keys.should include(*field_names)
      end

      it "does not include _type" do
        person.serializable_hash.keys.should_not include "_type"
      end

      context "when providing options" do

        let(:options) do
          { only: :name }
        end

        before do
          person.serializable_hash(options)
        end

        it "does not modify the options in the argument" do
          options[:except].should be_nil
        end
      end

      context "when include_type_for_serialization is true" do

        before do
          Mongoid.include_type_for_serialization = true
        end

        after do
          Mongoid.include_type_for_serialization = false
        end

        it "includes _type field" do
          person.serializable_hash.keys.should include '_type'
        end
      end

      context "when specifying which fields to only include" do

        it "only includes the specified fields" do
          person.serializable_hash(only: [:title]).should eq(
            { "title" => attributes["title"] }
          )
        end
      end

      context "when specifying extra inclusions" do

        it "includes the extra fields" do
          person.serializable_hash(
            methods: [ :_type ]
          ).has_key?("_type").should be_true
        end
      end

      context "when specifying which fields to exclude" do

        it "excludes the specified fields" do
          person.serializable_hash(except: [:title]).should_not include(
            "title" => attributes["title"]
          )
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
        person.serializable_hash[dynamic_field_name].should eq(dynamic_value)
      end

      context "when specifying which dynamic fields to only include" do

        it "only includes the specified dynamic fields" do
          person.serializable_hash(only: [dynamic_field_name]).should eq(
            { dynamic_field_name => dynamic_value }
          )
        end
      end

      context "when specified which dynamic fields to exclude" do

        it "excludes the specified fields" do
          person.serializable_hash(except: [dynamic_field_name]).should_not include(
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
        person.write_attributes(attributes, false)
      end

      context "when the model is saved before the relation is added" do

        before do
          person.save
        end

        context "when a model has an embeds many" do

          let!(:address_one) do
            person.addresses.build(street: "Kudamm")
          end

          before do
            person.save
          end

          it "includes the relation" do
            person.serializable_hash.keys.should include('addresses')
          end
        end

        context "when a model has an embeds one" do
          let!(:name) do
            person.build_name(first_name: "Leo", last_name: "Marvin")
          end

          before do
            person.save
          end

          it "includes the relation" do
            person.serializable_hash.keys.should include('name')
          end
        end
      end

      context "when the model is saved after the relation is added" do

        context "when a model has an embeds many" do

          let!(:address_one) do
            person.addresses.build(street: "Kudamm")
          end

          before do
            person.save
          end

          it "includes the relation" do
            person.serializable_hash.keys.should include('addresses')
          end
        end

        context "when a model has an embeds one" do
          let!(:name) do
            person.build_name(first_name: "Leo", last_name: "Marvin")
          end

          before do
            person.save
          end

          it "includes the relation" do
            person.serializable_hash.keys.should include('name')
          end
        end
      end
    end

    context "when including methods" do

      it "includes the method result" do
        person.serializable_hash(methods: [:foo]).should include(
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

          pending "when the ids were not loaded" do

            before do
              person.save
            end

            let(:from_db) do
              Person.only("addresses.street").first
            end

            let(:hash) do
              from_db.serializable_hash
            end

            it "does not generate new ids" do
              hash["addresses"].first["_id"].should be_nil
            end
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(include: :addresses)
            end

            it "includes the first relation" do
              relation_hash[0].should include
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              relation_hash[1].should include
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :addresses ])
            end

            it "includes the first relation" do
              relation_hash[0].should include
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              relation_hash[1].should include
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as a hash" do

            context "when including one level deep" do

              let(:hash) do
                person.serializable_hash(include: { addresses: { except: :_id } })
              end

              it "includes the first relation sans exceptions" do
                relation_hash[0].should include({ "street" => "Kudamm" })
              end

              it "includes the second relation sans exceptions" do
                relation_hash[1].should include({ "street" => "Tauentzienstr" })
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
                relation_hash[0]["locations"].any? do |location|
                  location["name"] == "Home"
                end.should be_true
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
                  person.save
                end

                it "includes the specific ralations" do
                  relation_hash[0]["locations"].map do |location|
                    location["name"]
                  end.should include "Home"
                  relation_hash[1]["locations"].map do |location|
                    location["name"]
                  end.should include "Hotel"
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
                hash["_id"].should be_nil
              end

              it "does not include the embedded many exclusion" do
                relation_hash[0]["_id"].should be_nil
              end

              it "does not include the embedded one exclusion" do
                hash["name"]["_id"].should be_nil
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
              relation_hash.should include
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :name ])
            end

            it "includes the specified relation" do
              relation_hash.should include
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(include: { name: { except: :_id }})
            end

            it "includes the specified relation sans exceptions" do
              relation_hash.should include
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
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should eq("Second")
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :posts ])
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should eq("Second")
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(include: { posts: { except: :_id } })
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should eq("Second")
            end

            it "does not include the first document exceptions" do
              relation_hash[0]["_id"].should be_nil
            end

            it "does not include the second document exceptions" do
              relation_hash[1]["_id"].should be_nil
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
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should eq("Second")
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(include: [ :preferences ])
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should eq("Second")
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
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should eq("First")
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should eq("Second")
            end

            it "does not include the first document exceptions" do
              relation_hash[0]["_id"].should be_nil
            end

            it "does not include the second document exceptions" do
              relation_hash[1]["_id"].should be_nil
            end

            it "does not include the root exceptions" do
              hash["preference_ids"].should be_nil
            end
          end
        end
      end
    end
  end

  describe "#to_json" do

    let(:person) do
      Person.new
    end

    context "when including root in json" do

      before do
        Mongoid.include_root_in_json = true
      end

      it "uses the mongoid configuration" do
        person.to_json.should include("person")
      end
    end

    context "when not including root in json" do

      before do
        Mongoid.include_root_in_json = false
      end

      it "uses the mongoid configuration" do
        person.to_json.should_not include("person")
      end
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
          json.should include(address.street)
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
          json.should include(post.title)
        end
      end
    end
  end

  describe "#to_xml" do

    context "Moped::BSON::ObjectId" do

      let(:person) do
        Person.new
      end

      it "serializes as string" do
        person.to_xml.should include("<_id>#{person.id}</_id>")
      end
    end

    context "when an Array field is defined" do

      let(:person) do
        Person.new(
          aliases: [ "Kelly", "Machine Gun" ]
        )
      end

      it "properly types the array" do
        person.to_xml.should include("<aliases type=\"array\">")
      end

      it "serializes the array" do
        person.to_xml.should include("<alias>Kelly</alias>")
        person.to_xml.should include("<alias>Machine Gun</alias>")
      end
    end

    context "when a Hash field is defined" do

      let(:person) do
        Person.new(
          map: { lat: 24.5, long: 22.1 }
        )
      end

      it "properly types the hash" do
        person.to_xml.should include("<map>")
      end

      it "serializes the hash" do
        person.to_xml.should include("<lat type=\"float\">24.5</lat>")
        person.to_xml.should include("<long type=\"float\">22.1</long>")
      end
    end
  end
end
