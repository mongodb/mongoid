require "spec_helper"

describe String do

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
