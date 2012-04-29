# encoding: utf-8
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular(/address$/, "address")
  inflect.singular("addresses", "address")
  inflect.irregular("canvas", "canvases")
end
