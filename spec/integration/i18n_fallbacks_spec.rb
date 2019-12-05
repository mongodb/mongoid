# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'i18n fallbacks' do
  # These tests modify the environment
  before(:all) do
    unless %w(yes true 1).include?((ENV['TEST_I18N_FALLBACKS'] || '').downcase)
      skip 'Set TEST_I18N_FALLBACKS=1 environment variable to run these tests'
    end
  end

  before(:all) do
    puts "I18n version: #{I18n::VERSION}"

    require "i18n/backend/fallbacks"
    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  end

  context 'when fallbacks are enabled with a locale list' do
    before do
      I18n.default_locale = :en
      I18n.fallbacks[:de] = [ :en ]
    end

    context 'when translation is present in active locale' do
      it 'uses active locale' do
        product = Product.new
        I18n.locale = :de
        product.description = "Marvelous in German"
        I18n.locale = :en
        product.description = "Marvelous!"
        I18n.locale = :de
        product.description.should == 'Marvelous in German'
      end
    end

    context 'when translation is missing in active locale and present in fallback locale' do

      it 'falls back on default locale' do
        product = Product.new
        I18n.locale = :en
        product.description = "Marvelous!"
        I18n.locale = :de
        product.description.should == 'Marvelous!'
      end

    end

    context 'when translation is missing in all locales' do

      context 'i18n >= 1.1' do

        before(:all) do
          unless Gem::Version.new(I18n::VERSION) >= Gem::Version.new('1.1')
            skip "Test requires i18n >= 1.1, we have #{I18n::VERSION}"
          end
        end

        it 'returns nil' do
          product = Product.new
          I18n.locale = :en
          product.description = "Marvelous!"
          I18n.locale = :ru
          product.description.should be nil
        end

      end

      context 'i18n 1.0' do

        before(:all) do
          unless Gem::Version.new(I18n::VERSION) < Gem::Version.new('1.1')
            skip "Test requires i18n < 1.1, we have #{I18n::VERSION}"
          end
        end

        it 'falls back on default locale' do
          product = Product.new
          I18n.locale = :en
          product.description = "Marvelous!"
          I18n.locale = :ru
          product.description.should == 'Marvelous!'
        end

      end
    end
  end
end
