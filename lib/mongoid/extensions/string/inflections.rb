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
          gsub(" ", "_").gsub(/\W/, "").dasherize.downcase
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
