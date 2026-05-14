# frozen_string_literal: true

require 'mongoid/persistable/creatable'
require 'mongoid/persistable/deletable'
require 'mongoid/persistable/destroyable'
require 'mongoid/persistable/incrementable'
require 'mongoid/persistable/logical'
require 'mongoid/persistable/maxable'
require 'mongoid/persistable/minable'
require 'mongoid/persistable/multipliable'
require 'mongoid/persistable/poppable'
require 'mongoid/persistable/pullable'
require 'mongoid/persistable/pushable'
require 'mongoid/persistable/renamable'
require 'mongoid/persistable/savable'
require 'mongoid/persistable/settable'
require 'mongoid/persistable/updatable'
require 'mongoid/persistable/upsertable'
require 'mongoid/persistable/unsettable'

module Mongoid
  # Contains general behavior for persistence operations.
  module Persistable
    extend ActiveSupport::Concern
    include Creatable
    include Deletable
    include Destroyable
    include Incrementable
    include Logical
    include Maxable
    include Minable
    include Multipliable
    include Poppable
    include Positional
    include Pullable
    include Pushable
    include Renamable
    include Savable
    include Settable
    include Updatable
    include Upsertable
    include Unsettable

    # The atomic operations that deal with arrays or sets in the db.
    LIST_OPERATIONS = [ '$addToSet', '$push', '$pull', '$pullAll' ].freeze

    # Execute operations atomically (in a single database call) for everything
    # that would happen inside the block. When nested, inner calls merge into
    # the outermost changeset and flush together when that outermost block exits.
    #
    # Passing join_context: false persists operations independently — they are
    # not affected by a failure in the enclosing block. This usage is deprecated;
    # instead call save outside any enclosing changeset scope.
    #
    # @example Execute the operations atomically.
    #   document.atomically do
    #     document.set(name: "Tool").inc(likes: 10)
    #   end
    #
    # @example Execute some inner operations independently (deprecated).
    #   document.atomically do
    #     document.inc likes: 10
    #     document.atomically(join_context: false) do
    #       # Persisted immediately, unaffected by outer failure.
    #       document.unset :origin
    #     end
    #   end
    #
    # @param [ true | false | nil ] join_context When false, operations persist
    #   independently of any enclosing changeset (deprecated). Any other value
    #   joins the enclosing changeset (the default).
    #
    # @return [ true ] Always true.
    def atomically(join_context: nil)
      if join_context == false
        Mongoid::Warnings.warn_join_context_false_deprecated
        if block_given?
          doc = self
          _atomically_independent { yield doc }
        end
      elsif block_given?
        Mongoid.changeset { yield self }
      end
      true
    end

    # Raise an error if validation failed.
    #
    # @example Raise the validation error.
    #   Person.fail_due_to_validation!(person)
    #
    # @raise [ Errors::Validations ] The validation error.
    def fail_due_to_validation!
      raise Errors::Validations.new(self)
    end

    # Raise an error if a callback failed.
    #
    # @example Raise the callback error.
    #   Person.fail_due_to_callback!(person, :create!)
    #
    # @param [ Symbol ] method The method being called.
    #
    # @raise [ Errors::Callback ] The callback error.
    def fail_due_to_callback!(method)
      raise Errors::Callback.new(self.class, method)
    end

    private

    # Post process the persistence operation.
    #
    # @api private
    #
    # @example Post process the persistence operation.
    #   document.post_process_persist(true)
    #
    # @param [ Object ] result The result of the operation.
    # @param [ Hash ] options The options.
    #
    # @option options [ true | false ] :validate Whether or not to validate.
    #
    # @return [ true ] true.
    def post_process_persist(result, options = {})
      post_persist unless result == false
      errors.clear unless performing_validations?(options)
      Threaded.add_modified_document(_session, self) if in_transaction? && !Threaded.current_changeset
      true
    end

    # Persist the atomic operations by staging an update entry in the current
    # changeset. Called by touchable on the root document.
    #
    # @api private
    #
    # @example Persist the atomic operations.
    #   persist_atomic_operations(ops)
    #
    # @param [ Hash ] operations The atomic operations.
    def persist_atomic_operations(operations)
      return unless persisted? && operations && !operations.empty?

      selector = atomic_selector
      Mongoid.changeset do |cs|
        cs.add(
          type: :update,
          collection: collection(_root),
          selector: selector,
          payload: positionally(selector, operations),
          document: self,
          session: _session
        )
      end
    end

    # Run the given block in an independent changeset, temporarily hiding any
    # enclosing changeset so that the inner block flushes immediately on exit.
    #
    # @api private
    def _atomically_independent(&block)
      outer = Threaded.current_changeset
      Threaded.current_changeset = nil
      begin
        Mongoid.changeset(&block)
      ensure
        Threaded.current_changeset = outer
      end
    end
  end
end
