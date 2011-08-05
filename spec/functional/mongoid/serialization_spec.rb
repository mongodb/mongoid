require "spec_helper"

describe Mongoid::Serialization do

  before do
    Person.delete_all
  end

  describe "#serializable_hash" do

    let(:person) do
      Person.new
    end

    context "when including relations" do

      context "when including a single relation" do

        context "when including an embeds many" do

          let!(:address_one) do
            person.addresses.build(:street => "Kudamm")
          end

          let!(:address_two) do
            person.addresses.build(:street => "Tauentzienstr")
          end

          let(:relation_hash) do
            hash["addresses"]
          end

          context "when the ids were not loaded" do

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
              person.serializable_hash(:include => :addresses)
            end

            it "includes the first relation" do
              relation_hash[0].should ==
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              relation_hash[1].should ==
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(:include => [ :addresses ])
            end

            it "includes the first relation" do
              relation_hash[0].should ==
                { "_id" => "kudamm", "street" => "Kudamm" }
            end

            it "includes the second relation" do
              relation_hash[1].should ==
                { "_id" => "tauentzienstr", "street" => "Tauentzienstr" }
            end
          end

          context "when providing the include as a hash" do

            context "when including one level deep" do

              let(:hash) do
                person.serializable_hash(:include => { :addresses => { :except => :_id } })
              end

              it "includes the first relation sans exceptions" do
                relation_hash[0].should == { "street" => "Kudamm" }
              end

              it "includes the second relation sans exceptions" do
                relation_hash[1].should == { "street" => "Tauentzienstr" }
              end
            end

            context "when including multiple levels deep" do

              let!(:location) do
                address_one.locations.build(:name => "Home")
              end

              let(:hash) do
                person.serializable_hash(
                  :include => { :addresses => {
                    :except => :_id, :include => { :locations => { :except => :_id } }
                  }
                })
              end

              it "includes the first relation" do
                relation_hash[0]["locations"].should == [{ "name" => "Home" }]
              end

              context "after retrieved from database" do

                let(:db_person) { Person.all.last }

                let!(:second_location) do
                  address_two.locations.build(:name => "Hotel")
                end

                let(:hash) do
                  db_person.serializable_hash(
                    :include => { :addresses => {
                      :except => :_id, :include => { :locations => { :except => :_id } }
                    }
                  })
                end

                before do
                  person.save
                end

                it "includes the specific ralations" do
                  relation_hash[0]["locations"].should == [{ "name" => "Home" }]
                  relation_hash[1]["locations"].should == [{ "name" => "Hotel" }]
                end
              end
            end

            context "when defining a default exclusion" do

              let!(:name) do
                person.build_name(:first_name => "Sebastien")
              end

              let(:hash) do
                person.serializable_hash(
                  :except => :_id,
                  :include => [ :addresses, :name ]
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
            person.build_name(:first_name => "Leo", :last_name => "Marvin")
          end

          let(:relation_hash) do
            hash["name"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(:include => :name)
            end

            it "includes the specified relation" do
              relation_hash.should ==
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(:include => [ :name ])
            end

            it "includes the specified relation" do
              relation_hash.should ==
                { "_id" => "leo-marvin", "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(:include => { :name => { :except => :_id }})
            end

            it "includes the specified relation sans exceptions" do
              relation_hash.should ==
                { "first_name" => "Leo", "last_name" => "Marvin" }
            end
          end
        end

        context "when including a references many" do

          let!(:post_one) do
            person.posts.build(:title => "First")
          end

          let!(:post_two) do
            person.posts.build(:title => "Second")
          end

          let(:relation_hash) do
            hash["posts"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(:include => :posts)
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should == "Second"
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(:include => [ :posts ])
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should == "Second"
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(:include => { :posts => { :except => :_id } })
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["title"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["title"].should == "Second"
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
            person.preferences.build(:name => "First")
          end

          let!(:preference_two) do
            person.preferences.build(:name => "Second")
          end

          let(:relation_hash) do
            hash["preferences"]
          end

          context "when providing the include as a symbol" do

            let(:hash) do
              person.serializable_hash(:include => :preferences)
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should == "Second"
            end
          end

          context "when providing the include as an array" do

            let(:hash) do
              person.serializable_hash(:include => [ :preferences ])
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should == "Second"
            end
          end

          context "when providing the include as a hash" do

            let(:hash) do
              person.serializable_hash(
                :include => {
                  :preferences => {
                    :except => :_id
                  }
                },
                :except => :preference_ids
              )
            end

            it "includes the specified relation" do
              relation_hash.should_not be_nil
            end

            it "includes the first document related fields" do
              relation_hash[0]["name"].should == "First"
            end

            it "includes the second document related fields" do
              relation_hash[1]["name"].should == "Second"
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
  end

  describe "#to_xml" do
    
    context "BSON::ObjectId" do
      let(:person) { Person.new }

      it "serializes as string" do
        person.to_xml.should include("<_id>#{person.id}</_id>")
      end
    end

    context "when an Array field is defined" do

      let(:person) do
        Person.new(
          :aliases => [ "Kelly", "Machine Gun" ]
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
          :map => { :lat => 24.5, :long => 22.1 }
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
