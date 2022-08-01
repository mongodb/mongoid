# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Options do

  describe "#__deep_copy__" do

    let(:sort) do
      [[ :name, :asc ]]
    end

    let(:options) do
      described_class.new
    end

    before do
      options[:sort] = sort
    end

    let(:cloned) do
      options.__deep_copy__
    end

    it "returns an equal copy" do
      expect(cloned).to eq(options)
    end

    it "performs a deep copy" do
      expect(cloned[:sort]).to_not equal(sort)
    end
  end

  describe "#fields" do

    let(:options) do
      described_class.new
    end

    context "when field options exist" do

      before do
        options[:fields] = { name: 1 }
      end

      it "returns the field options" do
        expect(options.fields).to eq({ "name" => 1 })
      end
    end

    context "when field options do not exist" do

      it "returns nil" do
        expect(options.fields).to be_nil
      end
    end
  end

  describe "#limit" do

    let(:options) do
      described_class.new
    end

    context "when limit options exist" do

      before do
        options[:limit] = 20
      end

      it "returns the limit options" do
        expect(options.limit).to eq(20)
      end
    end

    context "when limit options do not exist" do

      it "returns nil" do
        expect(options.limit).to be_nil
      end
    end
  end

  describe "#skip" do

    let(:options) do
      described_class.new
    end

    context "when skip options exist" do

      before do
        options[:skip] = 100
      end

      it "returns the skip options" do
        expect(options.skip).to eq(100)
      end
    end

    context "when skip options do not exist" do

      it "returns nil" do
        expect(options.skip).to be_nil
      end
    end
  end

  describe "#sort" do

    let(:options) do
      described_class.new
    end

    context "when sort options exist" do

      before do
        options[:sort] = { name: 1 }
      end

      it "returns the sort options" do
        expect(options.sort).to eq({ "name" => 1 })
      end
    end

    context "when sort options do not exist" do

      it "returns nil" do
        expect(options.sort).to be_nil
      end
    end
  end

  [ :store, :[]= ].each do |method|

    describe "##{method}" do

      context "when aliases are provided" do

        context "when the alias has no serializer" do

          let(:options) do
            described_class.new({ "id" => "_id" })
          end

          before do
            options.send(method, :sort, { :id => 1 })
          end

          it "stores the field in the options by database name" do
            expect(options[:sort]).to eq({ "_id" => 1 })
          end
        end
      end

      context "when no serializers are provided" do

        let(:options) do
          described_class.new
        end

        context "when provided a standard object" do

          context "when the keys are strings" do

            it "does not serialize values" do
              expect(options.send(method, "limit", "5")).to eq("5")
            end
          end

          context "when the keys are symbols" do

            it "does not serialize values" do
              expect(options.send(method, :limit, "5")).to eq("5")
            end
          end
        end
      end

      context "when serializers are provided" do

        context "when the serializer is not localized" do

          before(:all) do
            class Field
              def localized?
                false
              end
            end
          end

          after(:all) do
            Object.send(:remove_const, :Field)
          end

          let(:options) do
            described_class.new({}, { "key" => Field.new })
          end

          context "when the criterion is simple" do

            before do
              options.send(method, :limit, 1)
            end

            it "does not localize the keys" do
              expect(options[:limit]).to eq(1)
            end
          end

          context "when the criterion is complex" do

            before do
              options.send(method, :sort, { :key => 1 })
            end

            it "does not localize the keys" do
              expect(options[:sort]).to eq({ "key" => 1 })
            end
          end
        end

        context "when the serializer is localized" do
          with_default_i18n_configs

          before(:all) do
            class Field
              def localized?
                true
              end
            end
          end

          after(:all) do
            Object.send(:remove_const, :Field)
          end

          let(:options) do
            described_class.new({}, { "key" => Field.new })
          end

          before do
            ::I18n.locale = :de
          end

          context "when the criterion is simple" do

            before do
              options.send(method, :limit, 1)
            end

            it "does not localize the keys" do
              expect(options[:limit]).to eq(1)
            end
          end

          context "when the criterion is complex" do

            before do
              options.send(method, :sort, { :key => 1 })
            end

            it "does not localize the keys" do
              expect(options[:sort]).to eq({ "key.de" => 1 })
            end
          end
        end
      end
    end
  end

  describe "#to_pipeline" do

    let(:options) do
      described_class.new
    end

    context "when no options exist" do

      let(:pipeline) do
        options.to_pipeline
      end

      it "returns an empty array" do
        expect(pipeline).to be_empty
      end
    end

    context "when multiple options exist" do

      before do
        options[:fields] = { "name" => 1 }
        options[:skip] = 10
        options[:limit] = 10
        options[:sort] = { "name" => 1 }
      end

      let(:pipeline) do
        options.to_pipeline
      end

      it "converts the option to a $sort" do
        expect(pipeline).to eq([
          { "$skip" => 10 },
          { "$limit" => 10 },
          { "$sort" => { "name" => 1 }}
        ])
      end
    end

    context "when a sort exists" do

      before do
        options[:sort] = { "name" => 1 }
      end

      let(:pipeline) do
        options.to_pipeline
      end

      it "converts the option to a $sort" do
        expect(pipeline).to eq([
          { "$sort" => { "name" => 1 }}
        ])
      end
    end

    context "when a limit exists" do

      before do
        options[:limit] = 10
      end

      let(:pipeline) do
        options.to_pipeline
      end

      it "converts the option to a $sort" do
        expect(pipeline).to eq([
          { "$limit" => 10 }
        ])
      end
    end

    context "when a skip exists" do

      before do
        options[:skip] = 10
      end

      let(:pipeline) do
        options.to_pipeline
      end

      it "converts the option to a $sort" do
        expect(pipeline).to eq([
          { "$skip" => 10 }
        ])
      end
    end
  end
end
