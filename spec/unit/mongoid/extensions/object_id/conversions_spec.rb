require "spec_helper"

describe Mongoid::Extensions::ObjectId::Conversions do

  let(:object_id) do
    BSON::ObjectId.new
  end

  let(:composite_key) do
    "21-jump-street"
  end

  describe ".convert" do

    context "when the class is using object ids" do

      context "when provided a single object id" do

        let(:converted) do
          BSON::ObjectId.convert(Person, object_id)
        end

        it "returns the object id" do
          converted.should == object_id
        end
      end

      context "when provided an array of object ids" do

        let(:other_id) do
          BSON::ObjectId.new
        end

        let(:converted) do
          BSON::ObjectId.convert(Person, [ object_id, other_id ])
        end

        it "returns the array of object ids" do
          converted.should == [ object_id, other_id ]
        end
      end

      context "when provided an array of nils" do

        let(:converted) do
          BSON::ObjectId.convert(Person, [ nil, nil ])
        end

        it "returns an empty array" do
          converted.should be_empty
        end
      end

      context "when provided an array of empty strings" do

        let(:converted) do
          BSON::ObjectId.convert(Person, [ "", "" ])
        end

        it "returns an empty array" do
          converted.should be_empty
        end
      end

      context "when provided a single string" do

        context "when the string is a valid object id" do

          let(:converted) do
            BSON::ObjectId.convert(Person, object_id.to_s)
          end

          it "converts to an object id" do
            converted.should == object_id
          end
        end

        context "when the string is not a valid object id" do

          it "raises an error" do
            expect {
              BSON::ObjectId.convert(Person, composite_key)
            }.to raise_error(BSON::InvalidObjectId)
          end
        end

        context "when the string is empty" do

          let(:converted) do
            BSON::ObjectId.convert(Person, "")
          end

          it "converts to nil" do
            converted.should be_nil
          end
        end
      end

      context "when providing an array of strings" do

        context "when the strings are valid object ids" do

          let(:other_id) do
            BSON::ObjectId.new
          end

          let(:converted) do
            BSON::ObjectId.convert(Person, [ object_id.to_s, other_id.to_s ])
          end

          it "converts to an array of object ids" do
            converted.should == [ object_id, other_id ]
          end
        end

        context "when the strings are not valid object ids" do

          let(:other_key) do
            "hawaii-five-o"
          end

          let(:converted) do
            BSON::ObjectId.convert(Person, [ composite_key, other_key ])
          end

          it "converts to an array of object ids" do
            expect {
              BSON::ObjectId.convert(Person, composite_key)
            }.to raise_error(BSON::InvalidObjectId)
          end
        end
      end

      context "when provided a hash" do

        context "when the hash key is _id" do

          context "when the value is an object id" do

            let(:hash) do
              { :_id => object_id }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { :_id => [ object_id, other_id ] }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { :_id => object_id.to_s }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash with converted value" do
              converted.should == { :_id => object_id }
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { :_id => [ object_id.to_s, other_id.to_s ] }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash with converted values" do
              converted.should == { :_id => [ object_id, other_id ] }
            end
          end
        end

        context "when the hash key is id" do

          context "when the value is an object id" do

            let(:hash) do
              { :id => object_id }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end

          context "when the value is an array of object ids" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { :id => [ object_id, other_id ] }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end

          context "when the value is a string" do

            let(:hash) do
              { :id => object_id.to_s }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash with converted value" do
              converted.should == { :id => object_id }
            end
          end

          context "when the value is an array of strings" do

            let(:other_id) do
              BSON::ObjectId.new
            end

            let(:hash) do
              { :id => [ object_id.to_s, other_id.to_s ] }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash with converted values" do
              converted.should == { :id => [ object_id, other_id ] }
            end
          end
        end

        context "when the hash key is not an id" do

          context "when the value is a string" do

            let(:hash) do
              { :key => composite_key }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end

          context "when the value is an array of strings" do

            let(:hash) do
              { :key => [ composite_key ] }
            end

            let(:converted) do
              BSON::ObjectId.convert(Person, hash)
            end

            it "returns the hash" do
              converted.should == hash
            end
          end
        end
      end
    end

    context "when the class is not using object ids" do

      context "when provided an object" do

        let(:converted) do
          BSON::ObjectId.convert(Address, 100)
        end

        it "returns the object" do
          converted.should == 100
        end
      end

      context "when provided an array" do

        let(:converted) do
          BSON::ObjectId.convert(Address, [ 100 ])
        end

        it "returns the array" do
          converted.should == [ 100 ]
        end
      end

      context "when provided a hash" do

        let(:converted) do
          BSON::ObjectId.convert(Address, { :key => 100 })
        end

        it "returns the hash" do
          converted.should == { :key => 100 }
        end
      end
    end
  end

  describe ".try_bson" do

    it "returns self" do
      BSON::ObjectId.try_bson(object_id).should == object_id
    end
  end

  describe ".from_bson" do

    let(:object_id_string) do
      "4c52c439931a90ab29000003"
    end

    context "with a blank string" do

      it "returns nil" do
        BSON::ObjectId.from_bson("").should be_nil
      end
    end

    context "with a populated string" do

      it "returns an object id" do
        BSON::ObjectId.from_bson(object_id_string).should ==
          BSON::ObjectId.from_string(object_id_string)
      end
    end

    context "with an object id" do

      it "returns self" do
        BSON::ObjectId.from_bson(object_id).should == object_id
      end
    end
  end
end
