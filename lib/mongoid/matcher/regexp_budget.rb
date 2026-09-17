# frozen_string_literal: true

require 'timeout'

module Mongoid
  module Matcher
    # Bounds the time spent executing regular expressions while evaluating a
    # single in-memory match operation.
    #
    # A query condition can carry an application-supplied pattern, and the
    # in-memory matcher compiles and runs that pattern in the caller's thread.
    # Both the cost of one match and the number of matches performed are under
    # the control of whoever supplied the condition, so the limit is cumulative
    # over an entire operation rather than per match.
    #
    # The budget is held in thread- or fiber-local storage, so concurrent
    # queries are accounted for independently.
    #
    # @api private
    module RegexpBudget
      # Whether a per-Regexp timeout can be relied on to reach Regexp.new.
      #
      # MRI added them in 3.2. JRuby 10.0.6 defines Regexp::TimeoutError,
      # reports Ruby 3.4, and does honour a timeout that reaches it, but its
      # Regexp.new accepts the keyword only for the first couple of calls
      # through a given call site and raises ArgumentError from then on.
      # Because that breakage is per call site, no load-time probe can predict
      # it: a probe at its own call site reports a capability that the call in
      # Budget#compile does not have. So non-MRI engines are excluded outright
      # and use the Timeout fallback, which does interrupt a Joni match already
      # under way. Worth revisiting if JRuby fixes the keyword handling.
      PER_REGEXP_TIMEOUT =
        if RUBY_ENGINE == 'ruby' && defined?(::Regexp::TimeoutError)
          true
        else
          false
        end

      # The exception raised by a per-Regexp timeout. Tied to the constant
      # rather than to the probe, so that a timeout set some other way (an
      # application assigning Regexp.timeout, say) is still translated. On
      # Rubies with no such constant, a class that is never raised stands in.
      TIMEOUT_ERROR = defined?(::Regexp::TimeoutError) ? ::Regexp::TimeoutError : Class.new(StandardError)

      # Raised by Timeout on Rubies without per-Regexp timeouts, and converted
      # immediately. It is private to this module so that an application's own
      # Timeout, firing inside our block, is never mistaken for ours.
      class TimedOut < StandardError; end

      # The marker stored in thread-local storage when a scope is open but has
      # no budget to enforce. A nil-valued thread variable reads as absent
      # (Thread.current[:key] returns nil for a missing key), so an
      # open-but-unbounded scope has to store a real marker; a nested call
      # checks for the key and joins the enclosing scope rather than deciding
      # again for itself.
      NO_BUDGET = Object.new

      # The state of one open budget: what is left of the limit, and the
      # patterns compiled under it.
      #
      # @api private
      class Budget
        # @return [ Float ] The limit this budget started with.
        attr_reader :limit

        # @return [ Float ] The seconds left before the budget is spent.
        attr_reader :remaining

        # @param [ Float ] limit The seconds this budget may spend.
        def initialize(limit)
          @limit = limit
          @remaining = limit
          @cache = {}
          # A per-Regexp timeout bounds one match; the cumulative budget bounds
          # the operation. So the timeout is fixed for the life of the scope
          # rather than following the drawdown, which is what lets a pattern be
          # compiled once instead of once per match. It means a match that
          # starts with almost nothing left can still run for a whole limit, so
          # an operation can overshoot by at most one limit -- bounded, which is
          # the point, and far cheaper than recompiling.
          #
          # An application that has set a stricter global Regexp.timeout keeps
          # it: baking in a larger value would leave it less protected than it
          # asked to be. A timeout set on one individual pattern is a different
          # matter, and is not preserved -- Budget#compile rebuilds the pattern
          # from its source and flags, neither of which carries one, so this
          # value takes its place. Only trusted code can supply such a pattern:
          # a condition decoded from JSON or BSON arrives as a string or a
          # BSON::Regexp::Raw, with no timeout of its own.
          @timeout = [ limit, ::Regexp.timeout ].compact.min if PER_REGEXP_TIMEOUT
        end

        # Draws the elapsed time down from the budget.
        #
        # @param [ Float ] elapsed The seconds to charge.
        def charge(elapsed)
          @remaining -= elapsed
        end

        # @return [ true | false ] Whether the budget is spent.
        def exhausted?
          @remaining <= 0
        end

        # Returns the condition as a Regexp which, where the Ruby in use
        # supports it, gives up once its timeout is spent.
        #
        # The condition is taken uncompiled so that the cache can answer before
        # any compiling happens. A BSON::Regexp::Raw memoizes its own compile,
        # but FieldExpression builds a fresh one for every $regex it evaluates,
        # so that memo is worth nothing across documents and the source would
        # otherwise be compiled once per document.
        #
        # @param [ Regexp | BSON::Regexp::Raw ] condition The condition.
        #
        # @return [ Regexp ] The compiled pattern.
        def compile(condition)
          @cache[cache_key(condition)] ||= bake(RegexpBudget.coerce(condition))
        end

        private

        # BSON::Regexp::Raw aliases eql? to == but leaves hash alone, so two
        # equal instances hash differently and cannot key the cache. What they
        # are equal by can. Anything else keys on itself and is left to coerce
        # to reject.
        def cache_key(condition)
          case condition
          when BSON::Regexp::Raw then [ condition.pattern, condition.options ]
          else condition
          end
        end

        # Rebuilds the pattern with the budget's timeout, where the Ruby in use
        # has them.
        def bake(regexp)
          return regexp unless PER_REGEXP_TIMEOUT

          ::Regexp.new(regexp.source, regexp.options, timeout: @timeout)
        end
      end

      class << self
        # Opens a budget scope for the duration of the block.
        #
        # Nested calls join the enclosing budget instead of starting a new one,
        # which is what lets a scan over many documents share a single limit.
        # It also keeps the recursion in Expression.matches? (through
        # $elemMatch, $and, $or and $nor) from resetting the budget.
        #
        # No budget is opened for a selector that carries no regular
        # expression. There would be nothing for it to bound, and on the
        # Timeout path it would put a deadline on in-memory work that has
        # nothing to do with regular expressions.
        #
        # The scope covers everything nested inside the block, a selector other
        # than this one included: a nested call joins the scope rather than
        # deciding for itself, which is what keeps a scan from walking the
        # selector once per document. Where the scope has nothing to bound, that
        # means nested selectors are not bounded either -- so do not open one
        # around work that can run application code. Loading documents runs find
        # callbacks, and a query in one of those brings its own selector.
        #
        # Where a selector does carry one, the Timeout path still measures the
        # whole scope rather than the matching alone, so a long scan can trip
        # the limit with a cheap pattern. That imprecision is accepted: the
        # alternative is a Timeout around each individual match, which was
        # measured at about nine seconds per million matches, and the limit
        # exists to bound a scan of exactly that size. The error message is
        # worded to hold either way, and Rubies with per-Regexp timeouts --
        # every supported MRI from 3.2 on -- do not take this path at all.
        #
        # Code inside the block that mutates state should be wrapped in
        # .protect, since on Rubies without a per-Regexp timeout the budget is
        # enforced with an asynchronous exception that can land anywhere.
        #
        # @param [ Hash ] selector The selector about to be evaluated.
        #
        # @return [ Object ] The value of the block.
        def open(selector, &block)
          # The key is present (holding NO_BUDGET) where an enclosing scope
          # found nothing to bound, so that a nested call does not scan the
          # selector again. Deciding before this check, in a default argument
          # say, would walk the selector once per document on a scan. The
          # storage is Thread.current directly, matching this branch's Threaded
          # conventions; only the key is shared with Threaded.
          return yield if Thread.current[Threaded::REGEXP_BUDGET_KEY]

          open_with(limit_for(selector), &block)
        end

        # Opens a budget scope for a limit the caller has already decided on.
        #
        # A caller that rearranges its work around the decision -- loading
        # documents up front so that nothing is mutated before the scan
        # finishes, say -- has to make it before it can act on it, and must not
        # then make it a second time. Asking .limit_for and letting .open ask
        # again reads the configured limit twice, and the two reads can differ:
        # a limit that becomes positive in between would establish a budget in
        # the branch that was chosen for not needing one, and on the Timeout
        # path that arms a deadline over work the branch never made
        # interruptible.
        #
        # See .open for what the scope does and does not bound, and for the
        # note about mutating state inside it.
        #
        # @param [ Float | nil ] limit The seconds the scope may spend, or nil
        #   for a scope with nothing to bound.
        #
        # @return [ Object ] The value of the block.
        def open_with(limit, &block)
          return yield if Thread.current[Threaded::REGEXP_BUDGET_KEY]

          budget = Budget.new(limit) if limit&.positive?

          begin
            # Set inside the begin so that an asynchronous exception from an
            # enclosing timeout cannot leave the key behind on a pooled thread.
            Thread.current[Threaded::REGEXP_BUDGET_KEY] = budget || NO_BUDGET

            if budget.nil? || PER_REGEXP_TIMEOUT
              yield
            else
              begin
                Timeout.timeout(budget.limit, TimedOut, &block)
              rescue TimedOut
                raise timeout_error(budget)
              end
            end
          ensure
            # Setting nil on the way out removes the key on MRI, and reading a
            # nil value back is treated as absent regardless, so a lingering
            # nil on JRuby is harmless too.
            Thread.current[Threaded::REGEXP_BUDGET_KEY] = nil
          end
        end

        # The limit a scope evaluating this selector would be bounded by.
        #
        # A caller that has to rearrange its work to make the scan
        # interruptible -- loading documents up front so that nothing is
        # mutated before the scan finishes, say -- can ask this first and skip
        # the rearrangement, and whatever it costs, when there is no pattern to
        # bound. It then passes what it got to .open_with, so that the decision
        # it acted on is the one the scope is opened with. Callers with nothing
        # to rearrange should just call .open, which asks this itself.
        #
        # @param [ Hash ] selector The selector about to be evaluated.
        #
        # @return [ Float | nil ] The limit, or nil where there is nothing to
        #   bound.
        def limit_for(selector)
          # nil.to_f is 0.0, so an unset limit and a limit of zero or less are
          # the same thing here: no limit. Zero is a common way to spell
          # "disabled", and taking it literally would mean a budget that is
          # spent before the first match and a query that can never run.
          limit = Mongoid::Config.in_memory_regexp_time_limit.to_f
          return nil unless limit.positive?

          limit if contains_regexp?(selector)
        end

        # Matches a value against a regular expression condition, charging the
        # time it takes against the open budget.
        #
        # @param [ Object ] value The value to match.
        # @param [ Regexp | BSON::Regexp::Raw ] condition The condition.
        #
        # @raise [ Errors::InMemoryRegexpTimeout ] if the budget is exhausted.
        #
        # @return [ Integer | nil ] The offset of the match, or nil.
        def match?(value, condition)
          budget = current
          return value =~ coerce(condition) unless budget

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          pattern = nil
          begin
            raise timeout_error(budget) if budget.exhausted?

            # Compiling is charged too. It is not free, and for a pattern with
            # very many branches it costs far more than running the pattern
            # does, so leaving it out would leave a way to spend unbounded time
            # without the budget ever noticing.
            pattern = budget.compile(condition)
            value =~ pattern
          rescue TIMEOUT_ERROR
            # Name the limit that actually fired, which is not always the
            # budget's. A baked pattern carries it: the smaller of the budget's
            # limit and any global Regexp.timeout the application has set.
            # Where nothing was baked -- an engine that raises this error but
            # will not take a per-Regexp timeout, which is JRuby -- the global
            # is the only thing that can have fired, and the pattern reports
            # nil. Naming the budget's limit in either case would state a time
            # that was never spent and send the reader after a setting that is
            # not the one in the way.
            #
            # Both readers arrived together with Regexp::TimeoutError, so every
            # engine that can reach this rescue at all has them.
            raise timeout_error(budget, pattern&.timeout || ::Regexp.timeout || budget.limit)
          ensure
            budget.charge(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
          end
        end

        # Runs the block without letting a scope timeout tear it in half.
        #
        # Where the budget is enforced with Timeout, the exception is raised
        # asynchronously and can arrive at any point. Wrapping a mutation in
        # this holds the exception back until the block has finished, so the
        # interruption is deferred rather than given up.
        #
        # @return [ Object ] The value of the block.
        def protect(&block)
          Thread.handle_interrupt(TimedOut => :never, &block)
        end

        # The time left in the open budget, or nil when no budget is open.
        #
        # @return [ Float | nil ] The remaining seconds.
        def remaining
          current&.remaining
        end

        # Returns the condition as a Regexp, without a timeout.
        #
        # @param [ Regexp | BSON::Regexp::Raw ] condition The condition.
        #
        # @return [ Regexp ] The pattern.
        def coerce(condition)
          case condition
          when ::Regexp then condition
          when BSON::Regexp::Raw then condition.compile
          else raise ArgumentError, "Not a regular expression: #{condition.inspect}"
          end
        end

        private

        # The budget for the open scope, if there is one.
        #
        # A scope with nothing to bound leaves NO_BUDGET in storage, which reads
        # as no budget.
        #
        # @return [ Budget | nil ] The open budget.
        def current
          budget = Thread.current[Threaded::REGEXP_BUDGET_KEY]
          budget unless budget.equal?(NO_BUDGET)
        end

        # Whether evaluating the selector could run a regular expression.
        #
        # A string under $regex counts: FieldExpression turns it into a pattern
        # at match time.
        def contains_regexp?(object)
          case object
          when ::Regexp, BSON::Regexp::Raw
            true
          when Hash
            object.any? do |k, v|
              k.to_s == '$regex' || contains_regexp?(v)
            end
          when Array
            object.any? { |v| contains_regexp?(v) }
          else
            false
          end
        end

        # Builds the error with the scope timeout held back.
        #
        # Composing the message goes through I18n, which reads locale files the
        # first time it runs. An asynchronous TimedOut landing in the middle of
        # that is caught by I18n and reraised as a locale-loading failure, so
        # the real error never surfaces.
        #
        # @param [ Budget ] budget The open budget.
        # @param [ Float ] limit The limit that was exceeded. Defaults to the
        #   budget's own, which is the right one to name everywhere the budget
        #   itself ran out.
        def timeout_error(budget, limit = budget.limit)
          protect do
            Errors::InMemoryRegexpTimeout.new(limit)
          end
        end
      end
    end
  end
end
