# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Config

    # This module provides a way to inspect not only the defined configuration
    # settings and their defaults (which are available via
    # `Mongoid::Config.settings`), but also the documentation about them. It
    # does this by scraping the `mongoid/config.rb` file with a regular
    # expression to match comments with options.
    #
    # @api private
    module Introspection
      extend self

      # A helper class to represent an individual option, its name, its
      # default value, and the comment that documents it.
      class Option
        # The name of this option.
        #
        # @return [ String ] The name of the option
        attr_reader :name

        # The default value of this option.
        #
        # @return [ Object ] The default value of the option, typically a
        #   String, Symbol, nil, true, or false.
        attr_reader :default

        # The comment that describes this option, as scraped from
        # mongoid/config.rb.
        #
        # @return [ String ] The (possibly multi-line) comment. Each line is
        #   prefixed with the Ruby comment character ("#").
        attr_reader :comment

        # Instantiate an option from an array of Regex captures.
        #
        # @param [ Array<String> ] captures The array with the Regex captures
        #   to use to instantiate the option. The element at index 1 must be
        #   the comment, at index 2 must be the name, and at index 3 must be
        #   the default value.
        #
        # @return [ Option ] The newly instantiated Option object.
        def self.from_captures(captures)
          new(captures[2], captures[3], captures[1])
        end

        # Create a new Option instance with the given name, default value,
        # and comment.
        #
        # @param [ String ] name The option's name.
        # @param [ String ] default The option's default value, as a String
        #   representing the actual Ruby value.
        # @param [ String ] comment The multi-line comment describing the
        #   option.
        def initialize(name, default, comment)
          @name, @default, @comment = name, default, unindent(comment)
        end

        # Indent the comment by the requested amount, optionally indenting the
        # first line, as well.
        #
        # param [ Integer ] indent The number of spaces to indent each line
        #   (Default: 2)
        # param [ true | false ] indent_first_line Whether or not to indent
        #   the first line of the comment (Default: false)
        #
        # @return [ String ] the reformatted comment
        def indented_comment(indent: 2, indent_first_line: false)
          comment.gsub(/^/, " " * indent).tap do |result|
            result.strip! unless indent_first_line
          end
        end

        # Reports whether or not the text "(Deprecated)" is present in the
        # option's comment.
        #
        # @return [ true | false ] whether the option is deprecated or not.
        def deprecated?
          comment.include?("(Deprecated)")
        end

        # Compare self with the given option.
        #
        # @return [ true | false ] If name, default, and comment are all the
        #   same, return true. Otherwise, false.
        def ==(option)
          name == option.name &&
            default == option.default &&
            comment == option.comment
        end

        private

        # Removes any existing whitespace from the beginning of each line in
        # the text.
        #
        # @param [ String ] text The text to unindent.
        #
        # @return [ String ] the unindented text.
        def unindent(text)
          text.strip.gsub(/^\s+/, "")
        end
      end

      # A regular expression that looks for option declarations of the format:
      #
      #   # one or more lines of comments,
      #   # followed immediately by an option
      #   # declaration with a default value:
      #   option :option_name, default: "something"
      #
      # The regex produces three captures:
      #
      #   1: the (potentially multiline) comment
      #   2: the option's name
      #   3: the option's default value
      OPTION_PATTERN = %r{
        (
          ((?:^\s*\#.*\n)+)  # match one or more lines of comments
          ^\s+option\s+      # followed immediately by a line declaring an option
          :(\w+),\s+         # match the option's name, followed by a comma
          default:\s+(.*?)   # match the default value for the option
          (?:,.*?)?          # skip any other configuration
        \n)                  # end with a newline
      }x

      # The full path to the source file of the Mongoid::Config module.
      CONFIG_RB_PATH = File.absolute_path(File.join(
        File.dirname(__FILE__), "../config.rb"))

      # Extracts the available configuration options from the Mongoid::Config
      # source file, and returns them as an array of hashes.
      #
      # @param [ true | false ] include_deprecated Whether deprecated options
      #   should be included in the list. (Default: false)
      #
      # @return [ Array<Introspection::Option>> ] the array of option objects
      #   representing each defined option, in alphabetical order by name.
      def options(include_deprecated: false)
        src = File.read(CONFIG_RB_PATH)
        src.scan(OPTION_PATTERN)
          .map { |opt| Option.from_captures(opt) }
          .reject { |opt| !include_deprecated && opt.deprecated? }
          .sort_by { |opt| opt.name }
      end
    end

  end
end
