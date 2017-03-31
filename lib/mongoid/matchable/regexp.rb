module Mongoid
  module Matchable

    # Defines behavior for handling regular expressions in embedded documents.
    class Regexp < Default

      # Does the supplied query match the attribute?
      #
      # @example Does this match?
      #   matcher.matches?(/^Em/)
      #   matcher.matches?(BSON::Regex::Raw.new("^Em"))
      #
      # @param [ BSON::Regexp::Raw, Regexp ] regexp The regular expression object.
      #
      # @return [ true, false ] True if matches, false if not.
      #
      # @since 5.2.1
      def matches?(regexp)
        if native_regexp = regexp.try(:compile)
          super(native_regexp)
        else
          super
        end
      end
    end
  end
end
