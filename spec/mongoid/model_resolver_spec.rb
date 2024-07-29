# frozen_string_literal: true

require "spec_helper"

MONGOID_MODEL_RESOLVER_KEY__ = :__separate_instance_spec_key
Mongoid::ModelResolver.register_resolver Mongoid::ModelResolver.new, MONGOID_MODEL_RESOLVER_KEY__

describe Mongoid::ModelResolver do
  shared_examples 'a resolver' do |**kwargs|
    it 'includes the class name when asked for all keys of the given model' do
      expect(resolver.keys_for(model_class.new)).to include(model_class.name)
    end

    if kwargs[:with_aliases].nil?
      it 'uses the class name as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to be == model_class.name
      end
    elsif kwargs[:with_aliases].is_a?(Array)
      it 'uses the first alias as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to be == kwargs[:with_aliases].first
      end
    else
      it 'uses the alias as the default key for the given model' do
        expect(resolver.default_key_for(model_class.new)).to be == kwargs[:with_aliases]
      end
    end

    it 'returns the model class when queried with the class name' do
      expect(resolver.model_for(model_class.name)).to be == model_class
    end

    Array(kwargs[:with_aliases]).each do |model_alias|
      it "includes the alias #{model_alias.inspect} when asked for all keys of the given model" do
        expect(resolver.keys_for(model_class.new)).to include(model_alias)
      end

      it "returns the model class when queried with #{model_alias.inspect}" do
        expect(resolver.model_for(model_alias)).to be == model_class
      end
    end
  end

  context 'when using the default instance' do
    let(:resolver) { described_class.instance }
      
    context 'when an alias is not specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::DefaultInstance
          class Vanilla
            include Mongoid::Document
          end
        end

        Mongoid::ModelResolver::DefaultInstance::Vanilla
      end

      it_behaves_like 'a resolver'
    end

    context 'when one alias is specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::DefaultInstance
          class Aliased
            include Mongoid::Document
            identify_as 'aliased'
          end
        end

        Mongoid::ModelResolver::DefaultInstance::Aliased
      end

      it_behaves_like 'a resolver', with_aliases: 'aliased'
    end

    context 'when multiple aliases are specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::DefaultInstance
          class AliasedMultiple
            include Mongoid::Document
            identify_as 'aliased', 'alias2', 'alias3'
          end
        end

        Mongoid::ModelResolver::DefaultInstance::AliasedMultiple
      end

      it_behaves_like 'a resolver', with_aliases: %w[ aliased alias2 alias3 ]
    end
  end

  context 'when using a separate instance' do
    let(:resolver) { described_class.resolver(MONGOID_MODEL_RESOLVER_KEY__) }

    it 'does not refer to the default instance' do
      expect(resolver).not_to be == described_class.instance
    end

    context 'when an alias is not specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::SeparateInstance
          class Vanilla
            include Mongoid::Document
            identify_as resolver: MONGOID_MODEL_RESOLVER_KEY__
          end
        end

        Mongoid::ModelResolver::SeparateInstance::Vanilla
      end

      it_behaves_like 'a resolver'
    end

    context 'when one alias is specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::SeparateInstance
          class Aliased
            include Mongoid::Document
            identify_as 'aliased', resolver: MONGOID_MODEL_RESOLVER_KEY__
          end
        end

        Mongoid::ModelResolver::SeparateInstance::Aliased
      end

      it_behaves_like 'a resolver', with_aliases: 'aliased'
    end

    context 'when multiple aliases are specified' do
      let(:model_class) do
        module Mongoid::ModelResolver::SeparateInstance
          class AliasedMultiple
            include Mongoid::Document
            identify_as 'aliased', 'alias2', 'alias3', resolver: MONGOID_MODEL_RESOLVER_KEY__
          end
        end

        Mongoid::ModelResolver::SeparateInstance::AliasedMultiple
      end

      it_behaves_like 'a resolver', with_aliases: %w[ aliased alias2 alias3 ]
    end
  end
end
