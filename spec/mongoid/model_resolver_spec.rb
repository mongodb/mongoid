# frozen_string_literal: true

require 'spec_helper'
require 'support/feature_sandbox'

MONGOID_MODEL_RESOLVER_KEY__ = :__separate_instance_spec_key
Mongoid::ModelResolver.register_resolver Mongoid::ModelResolver.new, MONGOID_MODEL_RESOLVER_KEY__

def quarantine(context, &block)
  state = {}

  context.before(:context) do
    state[:quarantine] = FeatureSandbox.start_quarantine
    block&.call
  end

  context.after(:context) do
    FeatureSandbox.end_quarantine(state[:quarantine])
  end
end

describe Mongoid::ModelResolver do
  shared_examples 'a resolver' do |**kwargs|
    it 'includes the class name when asked for all keys of the given model' do
      expect(resolver.keys_for(model_class.new)).to include(model_class.name)
    end

    if kwargs[:with_aliases].nil?
      it 'uses the class name as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to eq model_class.name
      end
    elsif kwargs[:with_aliases].is_a?(Array)
      it 'uses the first alias as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to eq kwargs[:with_aliases].first
      end
    else
      it 'uses the alias as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to eq kwargs[:with_aliases]
      end
    end

    it 'returns the model class when queried with the class name' do
      expect(resolver.model_for(model_class.name)).to eq model_class
    end

    Array(kwargs[:with_aliases]).each do |model_alias|
      it "includes the alias #{model_alias.inspect} when asked for all keys of the given model" do
        expect(resolver.keys_for(model_class.new)).to include(model_alias)
      end

      it "returns the model class when queried with #{model_alias.inspect}" do
        expect(resolver.model_for(model_alias)).to eq model_class
      end
    end
  end

  context 'when using the default instance' do
    let(:resolver) { described_class.instance }

    context 'when an alias is not specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module DefaultInstance
            class Vanilla; include Mongoid::Document; end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::DefaultInstance::Vanilla }

      it_behaves_like 'a resolver'
    end

    context 'when one alias is specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module DefaultInstance
            class Aliased
              include Mongoid::Document
              identify_as 'aliased'
            end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::DefaultInstance::Aliased }

      it_behaves_like 'a resolver', with_aliases: 'aliased'
    end

    context 'when multiple aliases are specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module DefaultInstance
            class AliasedMultiple
              include Mongoid::Document
              identify_as 'aliased', 'alias2', 'alias3'
            end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::DefaultInstance::AliasedMultiple }

      it_behaves_like 'a resolver', with_aliases: %w[ aliased alias2 alias3 ]
    end
  end

  context 'when using a separate instance' do
    let(:resolver) { described_class.resolver(MONGOID_MODEL_RESOLVER_KEY__) }

    it 'does not refer to the default instance' do
      expect(resolver).not_to eq described_class.instance
    end

    context 'when an alias is not specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module SeparateInstance
            class Vanilla
              include Mongoid::Document
              identify_as resolver: MONGOID_MODEL_RESOLVER_KEY__
            end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::SeparateInstance::Vanilla }

      it_behaves_like 'a resolver'
    end

    context 'when one alias is specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module SeparateInstance
            class Aliased
              include Mongoid::Document
              identify_as 'aliased', resolver: MONGOID_MODEL_RESOLVER_KEY__
            end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::SeparateInstance::Aliased }

      it_behaves_like 'a resolver', with_aliases: 'aliased'
    end

    context 'when multiple aliases are specified' do
      quarantine(self) do
        Object.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          module Mongoid; module Specs; module SeparateInstance
            class AliasedMultiple
              include Mongoid::Document
              identify_as 'aliased', 'alias2', 'alias3', resolver: MONGOID_MODEL_RESOLVER_KEY__
            end
          end; end; end
        RUBY
      end

      let(:model_class) { Mongoid::Specs::SeparateInstance::AliasedMultiple }

      it_behaves_like 'a resolver', with_aliases: %w[ aliased alias2 alias3 ]
    end
  end
end
