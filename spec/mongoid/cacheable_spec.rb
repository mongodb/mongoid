# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Cacheable do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Cacheable
      end
    end

    it "adds an cache_timestamp_format accessor" do
      expect(klass).to respond_to(:cache_timestamp_format)
    end

    it "defaults cache_timestamp_format to :nsec" do
      expect(klass.cache_timestamp_format).to be(:nsec)
    end
  end

  describe "#cache_key" do

    let(:document) do
      Dokument.new
    end

    context "when the document is new" do

      it "has a new key name" do
        expect(document.cache_key).to eq("dokuments/new")
      end
    end

    context "when persisted" do

      before do
        document.save!
      end

      context "with updated_at" do

        context "with the default cache_timestamp_format" do

          let!(:updated_at) do
            document.updated_at.utc.to_formatted_s(:nsec)
          end

          it "has the id and updated_at key name" do
            expect(document.cache_key).to eq("dokuments/#{document.id}-#{updated_at}")
          end
        end

        context "with a different cache_timestamp_format" do

          before do
            Dokument.cache_timestamp_format = :number
          end

          after do
            Dokument.cache_timestamp_format = :nsec
          end

          let!(:updated_at) do
            document.updated_at.utc.to_formatted_s(:number)
          end

          it "has the id and updated_at key name" do
            expect(document.cache_key).to eq("dokuments/#{document.id}-#{updated_at}")
          end
        end
      end

      context "without updated_at, with Timestamps" do

        before do
          document.updated_at = nil
        end

        it "has the id key name" do
          expect(document.cache_key).to eq("dokuments/#{document.id}")
        end
      end
    end

    context "when model dont have Timestamps" do

      let(:artist) do
        Artist.create!
      end

      it "should have the id key name" do
        expect(artist.cache_key).to eq("artists/#{artist.id}")
      end
    end

    context "when model has Short Timestamps" do

      let(:agent) do
        ShortAgent.create!
      end

      let!(:updated_at) do
        agent.updated_at.utc.to_formatted_s(:nsec)
      end

      it "has the id and updated_at key name" do
        expect(agent.cache_key).to eq("short_agents/#{agent.id}-#{updated_at}")
      end
    end
  end
end
