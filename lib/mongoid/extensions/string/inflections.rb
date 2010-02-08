# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Inflections #:nodoc:

        ActiveSupport::Inflector.inflections do |inflect|
          inflect.singular("address", "address")
          inflect.singular("addresses", "address")
          inflect.irregular("canvas", "canvases")
        end

        # Represents how special characters will get converted when creating a
        # composite key that should be unique and part of a url.
        CHAR_CONV = {
          " " => "-",
          "!" => "-excl-",
          "\"" => "-bckslsh-",
          "#" => "-hash-",
          "$" => "-dol-",
          "%" => "-perc-",
          "&" => "-and-",
          "'" => "-quo-",
          "(" => "-oparen-",
          ")" => "-cparen-",
          "*" => "-astx-",
          "+" => "-plus-",
          "," => "-comma-",
          "-" => "-dash-",
          "." => "-period-",
          "/" => "-fwdslsh-",
          ":" => "-colon-",
          ";" => "-semicol-",
          "<" => "-lt-",
          "=" => "-eq-",
          ">" => "-gt-",
          "?" => "-ques-",
          "@" => "-at-",
          "[" => "-obrck-",
          "\\" => "-bckslsh-",
          "]" => "-clbrck-",
          "^" => "-carat-",
          "_" => "-undscr-",
          "`" => "-bcktick-",
          "{" => "-ocurly-",
          "|" => "-pipe-",
          "}" => "-clcurly-",
          "~" => "-tilda-"
        }

        REVERSALS = {
          "asc" => "desc",
          "ascending" => "descending",
          "desc" => "asc",
          "descending" => "ascending"
        }

        def collectionize
          tableize.gsub("/", "_")
        end

        def identify
          if Mongoid.parameterize_keys
            key = ""
            each_char { |c| key += (CHAR_CONV[c] || c.downcase) }; key
          else
            self
          end
        end

        def labelize
          underscore.humanize
        end

        def invert
          REVERSALS[self]
        end

        def singular?
          singularize == self
        end

        def plural?
          pluralize == self
        end

        def reader
          writer? ? gsub("=", "") : self
        end

        def writer?
          include?("=")
        end
      end
    end
  end
end
