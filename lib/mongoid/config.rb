# encoding: utf-8
require "mongoid/config/environment"
require "mongoid/config/options"
require "mongoid/config/validators"

module Mongoid #:nodoc

  # This module defines all the configuration options for Mongoid, including the
  # database connections.
  module Config
    extend self
    extend Options
    include ActiveModel::Observing

    option :allow_dynamic_fields, default: true
    option :identity_map_enabled, default: false
    option :include_root_in_json, default: false
    option :include_type_for_serialization, default: false
    option :preload_models, default: false
    option :protect_sensitive_fields, default: true
    option :raise_not_found_error, default: true
    option :scope_overwrite_exception, default: false
    option :skip_version_check, default: false
    option :time_zone, default: nil
    option :use_activesupport_time_zone, default: true
    option :use_utc, default: false

    # Return field names that could cause destructive things to happen if
    # defined in a Mongoid::Document.
    #
    # @example Get the destructive fields.
    #   config.destructive_fields
    #
    # @return [ Array<String> ] An array of bad field names.
    def destructive_fields
      Components.prohibited_methods
    end

    # Load the settings from a compliant mongoid.yml file. This can be used for
    # easy setup with frameworks other than Rails.
    #
    # @example Configure Mongoid.
    #   Mongoid.load!("/path/to/mongoid.yml")
    #
    # @param [ String ] path The path to the file.
    # @param [ String, Symbol ] environment The environment to load.
    #
    # @since 2.0.1
    def load!(path, environment = nil)
      Environment.load_yaml(path, environment).tap do |settings|
        load_configuration(settings) if settings.present?
      end
    end

    # Connect to the provided database name on the default session.
    #
    # @note Use only in development or test environments for convenience.
    #
    # @example Set the database to connect to.
    #   config.connect_to("mongoid_test")
    #
    # @param [ String ] name The database name.
    #
    # @since 3.0.0
    def connect_to(name)
      self.sessions = {
        default: {
          database: name,
          hosts: [ "localhost:27017" ]
        }
      }
    end

    # Purge all data in all collections, including indexes.
    #
    # @todo Durran: clean up.
    #
    # @example Purge all data.
    #   Mongoid::Config.purge!
    #
    # @return [ true ] true.
    #
    # @since 2.0.2
    def purge!
      session = Sessions.default
      session.use sessions[:default][:database]
      collections = session["system.namespaces"].find(name: { "$not" => /system|\$/ }).to_a
      collections.each do |collection|
        _, name = collection["name"].split(".", 2)
        session[name].drop
      end
      true
    end

    # Set the configuration options. Will validate each one individually.
    #
    # @example Set the options.
    #   config.options = { raise_not_found_error: true }
    #
    # @param [ Hash ] options The configuration options.
    #
    # @since 3.0.0
    def options=(options)
      if options
        options.each_pair do |option, value|
          Validators::Option.validate(option)
          send("#{option}=", value)
        end
      end
    end

    # Get the session configuration or an empty hash.
    #
    # @example Get the sessions configuration.
    #   config.sessions
    #
    # @return [ Hash ] The sessions configuration.
    #
    # @since 3.0.0
    def sessions
      @sessions ||= {}
    end

    # Set the session configuration options.
    #
    # @example Set the session configuration options.
    #   config.sessions = { default: { hosts: [ "localhost:27017" ] }}
    #
    # @param [ Hash ] sessions The configuration options.
    #
    # @since 3.0.0
    def sessions=(sessions)
      sessions.with_indifferent_access.tap do |sess|
        Validators::Session.validate(sess)
        @sessions = sess
      end
    end

    private

    # From a hash of settings, load all the configuration.
    #
    # @example Load the configuration.
    #   config.load_configuration(settings)
    #
    # @param [ Hash ] settings The configuration settings.
    #
    # @since 3.0.0
    def load_configuration(settings)
      configuration = settings.with_indifferent_access
      self.options = configuration[:options]
      self.sessions = configuration[:sessions]
    end
  end
end
