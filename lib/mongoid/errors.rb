# encoding: utf-8
require "mongoid/errors/mongoid_error"
require "mongoid/errors/document_not_found"
require "mongoid/errors/invalid_collection"
require "mongoid/errors/invalid_database"
require "mongoid/errors/invalid_field"
require "mongoid/errors/invalid_options"
require "mongoid/errors/invalid_type"
require "mongoid/errors/too_many_nested_attribute_records"
require "mongoid/errors/unsupported_version"
require "mongoid/errors/validations"

I18n.load_path << File.join(
  File.dirname(__FILE__), "errors", "locale", "en.yml"
)
