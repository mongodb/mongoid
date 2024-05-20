# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Config::Defaults do

  let(:config) do
    Mongoid::Config
  end

  describe ".load_defaults" do

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
        expect(Mongoid.legacy_persistence_context_behavior).to be true
        expect(Mongoid.around_callbacks_for_embeds).to be true
        expect(Mongoid.prevent_multiple_calls_of_embedded_callbacks).to be false
      end
    end

    shared_examples "does not use settings for 8.1" do
      it "does not use settings for 8.1" do
        expect(Mongoid.immutable_ids).to be true
        expect(Mongoid.legacy_persistence_context_behavior).to be false
        expect(Mongoid.around_callbacks_for_embeds).to be false
        expect(Mongoid.prevent_multiple_calls_of_embedded_callbacks).to be true
      end
    end

    context "when giving a valid version" do

      before do
        config.load_defaults(version)
      end

      after do
        Mongoid::Config.reset
      end

      context "when the given version is 8.0" do

        let(:version) { 8.0 }

        it_behaves_like "uses settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 8.1" do

        let(:version) { 8.1 }

        it_behaves_like "does not use settings for 8.0"
        it_behaves_like "uses settings for 8.1"
      end

      context "when the given version is 9.0" do

        let(:version) { 9.0 }

        it_behaves_like "does not use settings for 8.0"
        it_behaves_like "does not use settings for 8.1"
      end
    end

    context "when given version a version which is no longer supported" do
      let(:version) { 7.5 }

      it "raises an error" do
        expect do
          config.load_defaults(version)
        end.to raise_error(ArgumentError, 'Version no longer supported: 7.5')
      end
    end

    context "when given version an invalid version" do
      let(:version) { '4,2' }

      it "raises an error" do
        expect do
          config.load_defaults(version)
        end.to raise_error(ArgumentError, 'Unknown version: 4,2')
      end
    end
  end
end
