require "spec_helper"

describe String do
  using Mongoid::Refinements

  describe "#evolve_object_id" do

    context "when the string is blank" do

      it "returns the empty string" do
        expect("".evolve_object_id).to be_empty
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      it "returns the object id" do
        expect(object_id.to_s.evolve_object_id).to eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        expect(string.evolve_object_id).to eq(string)
      end
    end
  end

  describe "#mongoize_object_id" do

    context "when the string is blank" do

      it "returns nil" do
        expect("".mongoize_object_id).to be_nil
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      it "returns the object id" do
        expect(object_id.to_s.mongoize_object_id).to eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        expect(string.mongoize_object_id).to eq(string)
      end
    end
  end

  describe "#mongoize_time" do

    context "when using active support's time zone" do

      before do
        Mongoid.use_activesupport_time_zone = true
        ::Time.zone = "Tokyo"
      end

      after do
        ::Time.zone = "Berlin"
      end

      context "when the string is a valid time" do

        let(:string) do
          "2010-11-19 00:24:49 +0900"
        end

        let(:time) do
          string.mongoize_time
        end

        it "converts to a time" do
          expect(time).to eq(Time.configured.parse(string))
        end

        it "converts to the as time zone" do
          expect(time.zone).to eq("JST")
        end
      end

      context "when the string is an invalid time" do

        let(:string) do
          "shitty string"
        end

        it "raises an error" do
          expect {
            string.mongoize_time
          }.to raise_error(ArgumentError)
        end
      end
    end

    context "when not using active support's time zone" do

      before do
        Mongoid.use_activesupport_time_zone = false
      end

      after do
        Mongoid.use_activesupport_time_zone = true
        Time.zone = nil
      end

      context "when the string is a valid time" do

        let(:string) do
          "2010-11-19 00:24:49 +0900"
        end

        let(:time) do
          string.mongoize_time
        end

        it "converts to a time" do
          expect(time).to eq(Time.parse(string))
        end
      end

      context "when the string is an invalid time" do

        let(:string) do
          "shitty string"
        end

        it "raises an error" do
          expect {
            string.mongoize_time
          }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#collectionize" do

    context "when class is namepaced" do

      module Medical
        class Patient
          include Mongoid::Document
        end
      end

      it "returns an underscored tableized name" do
        expect(Medical::Patient.name.collectionize).to eq("medical_patients")
      end
    end

    context "when class is not namespaced" do

      it "returns an underscored tableized name" do
        expect(MixedDrink.name.collectionize).to eq("mixed_drinks")
      end
    end
  end

  describe ".demongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        expect(String.demongoize(:test)).to eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(String.demongoize(nil)).to be_nil
      end
    end
  end

  describe ".mongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        expect(String.mongoize(:test)).to eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(String.mongoize(nil)).to be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect("test".mongoize).to eq("test")
    end
  end

  describe "#reader" do

    context "when string is a reader" do

      it "returns self" do
        expect("attribute".reader).to eq("attribute")
      end
    end

    context "when string is a writer" do

      it "returns the reader" do
        expect("attribute=".reader).to eq("attribute")
      end
    end

    context "when the string is before_type_cast" do

      it "returns the reader" do
        expect("attribute_before_type_cast".reader).to eq("attribute")
      end
    end
  end

  describe "#numeric?" do

    context "when the string is an integer" do

      it "returns true" do
        expect("1234".numeric?).to be true
      end
    end

    context "when string is a float" do

      it "returns true" do
        expect("1234.123".numeric?).to be true
      end
    end

    context "when the string is has exponents" do

      it "returns true" do
        expect("1234.123123E4".numeric?).to be true
      end
    end

    context "when the string is non numeric" do

      it "returns false" do
        expect("blah".numeric?).to be false
      end
    end
  end

  describe "#singularize" do

    context "when string is address" do

      it "returns address" do
        expect("address".singularize).to eq("address")
      end
    end

    context "when string is address_profiles" do

      it "returns address_profile" do
        expect("address_profiles".singularize).to eq("address_profile")
      end
    end
  end

  describe "#writer?" do

    context "when string is a reader" do

      it "returns false" do
        expect("attribute".writer?).to be false
      end
    end

    context "when string is a writer" do

      it "returns true" do
        expect("attribute=".writer?).to be true
      end
    end
  end

  describe "#before_type_cast?" do

    context "when string is a reader" do

      it "returns false" do
        expect("attribute".before_type_cast?).to be false
      end
    end

    context "when string is before_type_cast" do

      it "returns true" do
        expect("attribute_before_type_cast".before_type_cast?).to be true
      end
    end
  end

  describe "#__evolve_date__" do

    context "when the string is verbose" do

      let(:date) do
        "1st Jan 2010"
      end

      let(:evolved) do
        date.__evolve_date__
      end

      it "returns the strings as a times" do
        expect(evolved).to eq(Time.new(2010, 1, 1, 0, 0, 0, 0).utc)
      end
    end

    context "when the string is in international format" do

      let(:date) do
        "2010-1-1"
      end

      let(:evolved) do
        date.__evolve_date__
      end

      it "returns the strings as a times" do
        expect(evolved).to eq(Time.new(2010, 1, 1, 0, 0, 0, 0).utc)
      end
    end
  end

  describe "#__evolve_time__" do

    context "when the string is verbose" do

      let(:date) do
        "1st Jan 2010 12:00:00+01:00"
      end

      let(:evolved) do
        date.__evolve_time__
      end

      it "returns the string as a utc time" do
        expect(evolved).to eq(Time.new(2010, 1, 1, 11, 0, 0, 0).utc)
      end
    end

    context "when the string is in international format" do

      let(:date) do
        "2010-01-01 12:00:00+01:00"
      end

      let(:evolved) do
        date.__evolve_time__
      end

      it "returns the string as a utc time" do
        expect(evolved).to eq(Time.new(2010, 1, 1, 11, 0, 0, 0).utc)
      end
    end
  end

  describe "#__sort_option__" do

    context "when the string contains ascending" do

      let(:option) do
        "field_one ascending, field_two ascending".__sort_option__
      end

      it "returns the ascending sort option hash" do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context "when the string contains asc" do

      let(:option) do
        "field_one asc, field_two asc".__sort_option__
      end

      it "returns the ascending sort option hash" do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context "when the string contains ASCENDING" do

      let(:option) do
        "field_one ASCENDING, field_two ASCENDING".__sort_option__
      end

      it "returns the ascending sort option hash" do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context "when the string contains ASC" do

      let(:option) do
        "field_one ASC, field_two ASC".__sort_option__
      end

      it "returns the ascending sort option hash" do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context "when the string contains descending" do

      let(:option) do
        "field_one descending, field_two descending".__sort_option__
      end

      it "returns the descending sort option hash" do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context "when the string contains desc" do

      let(:option) do
        "field_one desc, field_two desc".__sort_option__
      end

      it "returns the descending sort option hash" do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context "when the string contains DESCENDING" do

      let(:option) do
        "field_one DESCENDING, field_two DESCENDING".__sort_option__
      end

      it "returns the descending sort option hash" do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context "when the string contains DESC" do

      let(:option) do
        "field_one DESC, field_two DESC".__sort_option__
      end

      it "returns the descending sort option hash" do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end
  end

  describe "#__expr_part__" do

    let(:specified) do
      "field".__expr_part__(10)
    end

    it "returns the string with the value" do
      expect(specified).to eq({ "field" => 10 })
    end

    context "with a regexp" do

      let(:specified) do
        "field".__expr_part__(/test/)
      end

      it "returns the symbol with the value" do
        expect(specified).to eq({ "field" => /test/ })
      end

    end

    context "when negated" do

      context "with a regexp" do

        let(:specified) do
          "field".__expr_part__(/test/, true)
        end

        it "returns the string with the value negated" do
          expect(specified).to eq({ "field" => { "$not" => /test/ } })
        end

      end

      context "with anything else" do

        let(:specified) do
          "field".__expr_part__('test', true)
        end

        it "returns the string with the value negated" do
          expect(specified).to eq({ "field" => { "$ne" => "test" }})
        end
      end
    end
  end

  describe "#to_direction" do

    context "when ascending" do

      it "returns 1" do
        expect("ascending".to_direction).to eq(1)
      end
    end

    context "when asc" do

      it "returns 1" do
        expect("asc".to_direction).to eq(1)
      end
    end

    context "when ASCENDING" do

      it "returns 1" do
        expect("ASCENDING".to_direction).to eq(1)
      end
    end

    context "when ASC" do

      it "returns 1" do
        expect("ASC".to_direction).to eq(1)
      end
    end

    context "when descending" do

      it "returns -1" do
        expect("descending".to_direction).to eq(-1)
      end
    end

    context "when desc" do

      it "returns -1" do
        expect("desc".to_direction).to eq(-1)
      end
    end

    context "when DESCENDING" do

      it "returns -1" do
        expect("DESCENDING".to_direction).to eq(-1)
      end
    end

    context "when DESC" do

      it "returns -1" do
        expect("DESC".to_direction).to eq(-1)
      end
    end
  end

  describe ".evolve" do

    context "when provided a regex" do

      let(:regex) do
        /^[123]/
      end

      let(:evolved) do
        described_class.evolve(regex)
      end

      it "returns the regex" do
        expect(evolved).to eq(regex)
      end
    end

    context "when provided an object" do

      let(:object) do
        1234
      end

      let(:evolved) do
        described_class.evolve(object)
      end

      it "returns the object as a string" do
        expect(evolved).to eq("1234")
      end
    end
  end
end
