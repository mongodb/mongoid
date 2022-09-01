# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Config::Defaults do

  let(:config) do
    Mongoid::Config
  end

  describe ".load_defaults" do

    shared_examples "turns off 7.4 flags" do
      it "turns off the 7.4 flags" do
        expect(Mongoid.broken_aggregables).to be true
        expect(Mongoid.broken_alias_handling).to be true
        expect(Mongoid.broken_and).to be true
        expect(Mongoid.broken_scoping).to be true
        expect(Mongoid.broken_updates).to be true
        expect(Mongoid.compare_time_by_ms).to be false
        expect(Mongoid.legacy_pluck_distinct).to be true
        expect(Mongoid.legacy_triple_equals).to be true
        expect(Mongoid.object_id_as_json_oid).to be true
      end
    end

    shared_examples "turns on 7.4 flags" do
      it "turns on the 7.4 flags" do
        expect(Mongoid.broken_aggregables).to be false
        expect(Mongoid.broken_alias_handling).to be false
        expect(Mongoid.broken_and).to be false
        expect(Mongoid.broken_scoping).to be false
        expect(Mongoid.broken_updates).to be false
        expect(Mongoid.compare_time_by_ms).to be true
        expect(Mongoid.legacy_pluck_distinct).to be false
        expect(Mongoid.legacy_triple_equals).to be false
        expect(Mongoid.object_id_as_json_oid).to be false
      end
    end

    shared_examples "turns off 7.5 flags" do
      it "turns off the 7.5 flags" do
        expect(Mongoid.legacy_attributes).to be true
        expect(Mongoid.overwrite_chained_operators).to be true
      end
    end

    shared_examples "turns on 7.5 flags" do
      it "turns on the 7.5 flags" do
        expect(Mongoid.legacy_attributes).to be false
        expect(Mongoid.overwrite_chained_operators).to be false
      end
    end

    shared_examples "turns off 8.0 flags" do
      it "turns off the 8.0 flags" do
        expect(Mongoid.map_big_decimal_to_decimal128).to be false
      end
    end

    shared_examples "turns on 8.0 flags" do
      it "turns on the 8.0 flags" do
        expect(Mongoid.map_big_decimal_to_decimal128).to be true
      end
    end

    context "when giving a valid version" do

      before do
        config.load_defaults(version)
      end

      after do
        Mongoid::Config.reset
      end

      context "when the given version is 7.3" do

        let(:version) { 7.3 }

        it_behaves_like "turns off 7.4 flags"
        it_behaves_like "turns off 7.5 flags"
        it_behaves_like "turns off 8.0 flags"
      end

      context "when the given version is 7.4" do

        let(:version) { 7.4 }

        it_behaves_like "turns on 7.4 flags"
        it_behaves_like "turns off 7.5 flags"
        it_behaves_like "turns off 8.0 flags"
      end

      context "when the given version is 7.5" do

        let(:version) { 7.5 }

        it_behaves_like "turns on 7.4 flags"
        it_behaves_like "turns on 7.5 flags"
        it_behaves_like "turns off 8.0 flags"
      end

      context "when the given version is 8.0" do

        let(:version) { 8.0 }

        it_behaves_like "turns on 7.4 flags"
        it_behaves_like "turns on 7.5 flags"
        it_behaves_like "turns on 8.0 flags"
      end

      context "when the given version is 8.1" do

        let(:version) { 8.0 }

        it_behaves_like "turns on 7.4 flags"
        it_behaves_like "turns on 7.5 flags"
        it_behaves_like "turns on 8.0 flags"
      end
    end

    context "when given version an invalid version" do
      let(:version) { 4.2 }

      it "raises an error" do
        expect do
          config.load_defaults(version)
        end.to raise_error(ArgumentError, /Unknown version: 4.2/)
      end
    end
  end
end
