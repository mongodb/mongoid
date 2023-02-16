# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Config::Defaults do

  let(:config) do
    Mongoid::Config
  end

  describe ".load_defaults" do

    shared_examples "uses settings for 7.3" do
      it "uses settings for 7.3" do
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

    shared_examples "does not use settings for 7.3" do
      it "does not use settings for 7.3" do
        expect(Mongoid.broken_aggregables).to be false
        expect(Mongoid.broken_alias_handling).to be false
        expect(Mongoid.broken_and).to be false
        expect(Mongoid.broken_scoping).to be false
        expect(Mongoid.broken_updates).to be false
        expect(Mongoid.compare_time_by_ms).to be true
        expect(Mongoid.legacy_pluck_distinct).to be false
        expect(Mongoid.legacy_triple_equals).to be false
      end
    end

    shared_examples "uses settings for 7.4" do
      it "uses settings for 7.4" do
        expect(Mongoid.legacy_attributes).to be true
        expect(Mongoid.overwrite_chained_operators).to be true
      end
    end

    shared_examples "does not use settings for 7.4" do
      it "does not use settings for 7.4" do
        expect(Mongoid.legacy_attributes).to be false
        expect(Mongoid.overwrite_chained_operators).to be false
      end
    end

    shared_examples "uses settings for 7.5" do
      it "uses settings for 7.5" do
        expect(Mongoid.map_big_decimal_to_decimal128).to be false
      end
    end

    shared_examples "does not use settings for 7.5" do
      it "does not use settings for 7.5" do
        expect(Mongoid.map_big_decimal_to_decimal128).to be true
      end
    end

    shared_examples "uses settings for 8.0" do
      it "uses settings for 8.0" do
        expect(Mongoid.legacy_readonly).to be true
      end
    end

    shared_examples "does not use settings for 8.0" do
      it "does not use settings for 8.0" do
        expect(Mongoid.legacy_readonly).to be false
      end
    end

    shared_examples "uses settings for 8.1" do
      it "uses settings for 8.1" do
        expect(Mongoid.immutable_ids).to be false
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

        it_behaves_like "uses settings for 7.3"
        it_behaves_like "uses settings for 7.4"
        it_behaves_like "uses settings for 7.5"
        it_behaves_like "uses settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 7.4" do

        let(:version) { 7.4 }

        it_behaves_like "does not use settings for 7.3"
        it_behaves_like "uses settings for 7.4"
        it_behaves_like "uses settings for 7.5"
        it_behaves_like "uses settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 7.5" do

        let(:version) { 7.5 }

        it_behaves_like "does not use settings for 7.3"
        it_behaves_like "does not use settings for 7.4"
        it_behaves_like "uses settings for 7.5"
        it_behaves_like "uses settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 8.0" do

        let(:version) { 8.0 }

        it_behaves_like "does not use settings for 7.3"
        it_behaves_like "does not use settings for 7.4"
        it_behaves_like "does not use settings for 7.5"
        it_behaves_like "uses settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 8.1" do

        let(:version) { 8.1 }

        it_behaves_like "does not use settings for 7.3"
        it_behaves_like "does not use settings for 7.4"
        it_behaves_like "does not use settings for 7.5"
        it_behaves_like "does not use settings for 8.0"
        it_behaves_like "uses settings for 8.1"
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
