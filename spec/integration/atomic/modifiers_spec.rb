# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Atomic::Modifiers do

  let(:modifiers) do
    described_class.new
  end

  context 'when performing multiple operations with similar keys' do

    let(:pushes) do
      { "addresses.0.locations" => { "street" => "Bond St" } }
    end

    let(:similar1) do
      { "dresses" => { "color" => "red" } }
    end

    let(:similar2) do
      { "ses.0.foo" => { "baz" => "qux" } }
    end

    before do
      modifiers.send(operation, pushes)
      modifiers.send(operation, similar1)
      modifiers.send(operation, similar2)
    end

    context "push" do
      let(:operation) { :push }

      it "adds all modifiers to top level" do
        expect(modifiers).to eq({ "$push" => {
                                    "addresses.0.locations" => { '$each' => [{ "street" => "Bond St" }] },
                                    "dresses" => { '$each' => [{ "color" => "red" }] },
                                    "ses.0.foo" => { '$each' => [{ "baz" => "qux" }] }
                                 } })
      end
    end

    context "pull" do
      let(:operation) { :pull }

      it "adds all modifiers to top level" do
        expect(modifiers).to eq({ "$pull" => {
                                    "addresses.0.locations" => { "street" => "Bond St" },
                                    "dresses" => { "color" => "red" },
                                    "ses.0.foo" => { "baz" => "qux" },
                                 } })
      end
    end

    context "pull_all" do
      let(:operation) { :pull_all }

      it "adds all modifiers to top level" do
        expect(modifiers).to eq({ "$pullAll" => {
                                    "addresses.0.locations" => { "street" => "Bond St" },
                                    "dresses" => { "color" => "red" },
                                    "ses.0.foo" => { "baz" => "qux" },
                                 } })
      end
    end

    context "add_to_set" do
      let(:operation) { :add_to_set }

      it "adds all modifiers to top level" do
        expect(modifiers).to eq({ "$addToSet" => {
                                    "addresses.0.locations" => { '$each' => { "street" => "Bond St" } },
                                    "dresses" => { '$each' => { "color" => "red" } },
                                    "ses.0.foo" => { '$each' => { "baz" => "qux" } }
                                 } })
      end
    end

    context "set" do
      let(:operation) { :set }

      it "adds all modifiers to top level" do
        expect(modifiers).to eq({ "$set" => {
                                    "addresses.0.locations" => { "street" => "Bond St" },
                                    "dresses" => { "color" => "red" },
                                    "ses.0.foo" => { "baz" => "qux" },
                                 } })
      end
    end

    context "unset" do
      let(:operation) { :unset }

      let(:pushes) do
        [:foobar]
      end

      let(:similar1) do
        [:foo]
      end

      let(:similar2) do
        [:bar]
      end

      it "adds all modifiers to top level" do
        expect(modifiers).to eq("$unset" => {
          foobar: true,
          foo: true,
          bar: true,
        })
      end
    end
  end

end
