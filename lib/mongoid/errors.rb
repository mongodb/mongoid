# frozen_string_literal: true

require "mongoid/errors/mongoid_error"
require "mongoid/errors/ambiguous_relationship"
require "mongoid/errors/callback"
require "mongoid/errors/criteria_argument_required"
require "mongoid/errors/document_not_destroyed"
require "mongoid/errors/document_not_found"
require "mongoid/errors/empty_config_file"
require "mongoid/errors/in_memory_collation_not_supported"
require "mongoid/errors/invalid_collection"
require "mongoid/errors/invalid_config_file"
require "mongoid/errors/invalid_config_option"
require "mongoid/errors/invalid_dependent_strategy"
require "mongoid/errors/invalid_field"
require "mongoid/errors/invalid_field_option"
require "mongoid/errors/invalid_field_type"
require "mongoid/errors/invalid_find"
require "mongoid/errors/invalid_includes"
require "mongoid/errors/invalid_index"
require "mongoid/errors/invalid_options"
require "mongoid/errors/invalid_path"
require "mongoid/errors/invalid_persistence_option"
require "mongoid/errors/invalid_query"
# Must be after invalid_query.
require "mongoid/errors/invalid_discriminator_key_target"
require "mongoid/errors/invalid_dot_dollar_assignment"
require "mongoid/errors/invalid_elem_match_operator"
require "mongoid/errors/invalid_estimated_count_criteria"
require "mongoid/errors/invalid_expression_operator"
require "mongoid/errors/invalid_field_operator"
require "mongoid/errors/invalid_relation"
require "mongoid/errors/invalid_relation_option"
require "mongoid/errors/invalid_scope"
require "mongoid/errors/invalid_session_use"
require "mongoid/errors/invalid_set_polymorphic_relation"
require "mongoid/errors/invalid_storage_options"
require "mongoid/errors/invalid_storage_parent"
require "mongoid/errors/invalid_time"
require "mongoid/errors/invalid_value"
require "mongoid/errors/inverse_not_found"
require "mongoid/errors/mixed_relations"
require "mongoid/errors/mixed_client_configuration"
require "mongoid/errors/nested_attributes_metadata_not_found"
require "mongoid/errors/no_default_client"
require "mongoid/errors/no_environment"
require "mongoid/errors/no_map_reduce_output"
require "mongoid/errors/no_metadata"
require "mongoid/errors/no_parent"
require "mongoid/errors/no_client_config"
require "mongoid/errors/no_clients_config"
require "mongoid/errors/no_client_database"
require "mongoid/errors/no_client_hosts"
require "mongoid/errors/readonly_attribute"
require "mongoid/errors/readonly_document"
require "mongoid/errors/scope_overwrite"
require "mongoid/errors/too_many_nested_attribute_records"
require "mongoid/errors/unknown_attribute"
require "mongoid/errors/unknown_model"
require "mongoid/errors/unsaved_document"
require "mongoid/errors/unsupported_javascript"
require "mongoid/errors/validations"
require "mongoid/errors/delete_restriction"
