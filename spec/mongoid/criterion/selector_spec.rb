require "spec_helper"

describe Mongoid::Criterion::Selector do

  let(:selector) do
    described_class.new(Person)
  end

  describe "#initialize" do

    it "stores the class" do
      described_class.new(Person).klass.should eq(Person)
    end
  end

  describe "#[]=" do

    context "when providing the correct type" do

      before do
        selector["age"] = 45
      end

      it "stores the provided value" do
        selector["age"].should eq(45)
      end
    end

    context "when providing a typecastable value" do

      before do
        selector["age"] = "45"
      end

      it "typecasts the provided values" do
        selector["age"].should eq(45)
      end
    end

    context "when providing a complex criterion" do

      before do
        selector["age"] = { "$gt" => "45" }
      end

      it "casts the values in the criterion" do
        selector["age"].should eq({ "$gt" => 45 })
      end
    end

    context "when the field is localized" do

      let(:selector) do
        described_class.new(Product)
      end

      context "when no locale is defined" do

        before do
          selector["description"] = "testing"
        end

        it "converts to dot notation with the default locale" do
          selector["description.en"].should eq("testing")
        end
      end

      context "when a locale is defined" do

        before do
          ::I18n.locale = :de
          selector["description"] = "testing"
        end

        after do
          ::I18n.locale = :en
        end

        it "converts to dot notation with the set locale" do
          selector["description.de"].should eq("testing")
        end
      end
    end
  end

  [ :merge!, :update ].each do |method|

    describe "##{method}" do

      context "when providing the correct type" do

        before do
          selector.send(method, { "age" => 45 })
        end

        it "stores the provided value" do
          selector["age"].should eq(45)
        end
      end

      context "when providing a typecastable value" do

        before do
          selector.send(method, { "age" => "45" })
        end

        it "typecasts the provided values" do
          selector["age"].should eq(45)
        end
      end
    end
  end

  describe "#try_to_typecast" do

    context "when the key is $or or $and" do

      let(:value) do
        { "age" => "45"  }
      end

      context "when the value is not an array" do

        it "returns the value" do
          selector.send(:try_to_typecast, "$or", value).should eq(value)
        end
      end

      context "when the value is an array containing hashes" do

        context "when the keys are not declared" do

          let(:value) do
            { "new_age" => "45" }
          end

          it "returns the array" do
            selector.send(:try_to_typecast, "$or", [value]).should eq([value])
          end
        end

        context "when the keys are declared" do

          it "returns the typecasted array" do
            selector.send(:try_to_typecast, "$or", [value]).should eq(["age" => 45])
          end
        end
      end
    end

    context "when the key is not a declared field" do

      it "returns the value" do
        selector.send(:try_to_typecast, "new_age", "45").should eq("45")
      end
    end

    context "when the key is a declared field" do

      it "returns the typecast value" do
        selector.send(:try_to_typecast, "age", "45").should eq(45)
      end
    end
  end

  describe "#proper_and_or_value?" do

    context "when the key is not $or or $and" do

      it "returns false" do
        selector.send(:proper_and_or_value?, "fubar", nil).should be_false
      end
    end

    context "when the key is $or or $and" do

      context "when the value is not an array" do

        it "returns false" do
          selector.send(:proper_and_or_value?, "$or", nil).should be_false
        end
      end

      context "when the value is an array" do

        context "when the entries are no hashes" do

          it "returns false" do
            selector.send(:proper_and_or_value?, "$or", [nil]).should be_false
          end
        end

        context "when the array is empty" do

          it "returns true" do
            selector.send(:proper_and_or_value?, "$or", []).should be_true
          end
        end

        context "when the entries are hashes" do

          it "returns true" do
            selector.send(:proper_and_or_value?, "$or", [{}]).should be_true
          end
        end
      end
    end
  end

  describe "#handle_and_or_value" do

    let(:values) do
      [{ "age" => 45, "title" => "Chief Visionary" }]
    end

    it "preserves the structure" do
      selector.send(:handle_and_or_value, values).should eq(values)
    end
  end

  describe "#typecast_value_for" do

    context "when the value is a range" do

      let(:field) do
        Mongoid::Fields::Internal::Date.instantiate(:dob, type: Date)
      end

      let(:first) do
        Date.new(2000, 1, 1)
      end

      let(:last) do
        Date.new(2010, 1, 1)
      end

      let(:range) do
        first..last
      end

      let(:converted) do
        selector.send(:typecast_value_for, field, range)
      end

      it "returns a hash with gte and lte criteria" do
        converted.should eq({ "$gte" => first, "$lte" => last })
      end
    end

    context "when the value is simple" do

      let(:field) do
        Person.fields["age"]
      end

      it "delegates to the field to typecast" do
        selector.send(:typecast_value_for, field, "45").should eq(45)
      end
    end

    context "when the field is an array" do

      let(:field) do
        Person.fields["aliases"]
      end

      it "allows the simple value to be set" do
        selector.send(:typecast_value_for, field, "007").should eq("007")
      end
    end

    context "when the value is a regex" do

      let(:field) do
        Person.fields["age"]
      end

      it "returns the regex unmodified" do
        selector.send(:typecast_value_for, field, /Regex/).should eq(/Regex/)
      end
    end

    context "when the value is an array" do

      context "and the field type is array" do

        let(:field) do
          Person.fields["aliases"]
        end

        it "lets the field typecast the value" do
          selector.send(:typecast_value_for, field, []).should eq([])
        end
      end

      context "and the field type is not array" do

        let(:field) do
          Person.fields["age"]
        end

        it "typecasts each value" do
          selector.send(:typecast_value_for, field, ["1", "2"]).should eq([ 1, 2 ])
        end
      end
    end

    context "when the value is a hash" do

      context "and the field type is not hash" do

        let(:field) do
          Person.fields["age"]
        end

        let(:value) do
          {}
        end

        it "does not modify the original value" do
          selector.send(:typecast_value_for, field, value).should_not equal(value)
        end

        context "when the hash is an $exists query" do

          context "when the value is already cast" do

            let(:value) do
              { "$exists" => true }
            end

            it "does not typecast the hash" do
              selector.send(:typecast_value_for, field, value).should eq(value)
            end
          end

          context "when the value can be cast" do

            let(:value) do
              { "$exists" => "true" }
            end

            it "typecasts the value" do
              selector.send(:typecast_value_for, field, value).should eq(
                { "$exists" => true }
              )
            end
          end
        end

        context "when the hash is a $size query" do

          context "when the value is already cast" do

            let(:value) do
              { "$size" => 2 }
            end

            it "does not typecast the hash" do
              selector.send(:typecast_value_for, field, value).should eq(value)
            end
          end

          context "when the value can be cast" do

            let(:value) do
              { "$size" => "2" }
            end

            it "typecasts the value" do
              selector.send(:typecast_value_for, field, value).should eq(
                { "$size" => 2 }
              )
            end
          end
        end
      end

      context "and the field type is a hash" do

        let(:field) do
          Person.fields["map"]
        end

        let(:value) do
          { "name" => "John" }
        end

        it "lets the field typecast the value" do
          selector.send(:typecast_value_for, field, value).should eq(value)
        end
      end
    end
  end
end
