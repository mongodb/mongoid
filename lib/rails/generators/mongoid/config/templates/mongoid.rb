Mongoid.configure do
  target_version = "<%= Mongoid::VERSION[/^\d+\.\d+/] %>"

  # Load Mongoid behavior defaults. This automatically sets
  # features flags (refer to documentation)
  config.load_defaults target_version
<%- mongoid_config_options.each do |opt| -%>

  <%= opt[:desc].strip %>
  # config.<%= opt[:name] %> = <%= opt[:default] %>
<%- end -%>
end
 
# Enable Mongo driver query cache for Rack
# Rails.application.config.middleware.use(Mongo::QueryCache::Middleware)
 
# Enable Mongo driver query cache for ActiveJob
# ActiveSupport.on_load(:active_job) do
#   include Mongo::QueryCache::Middleware::ActiveJob
# end
