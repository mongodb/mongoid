require 'singleton'

class SpecConfig
  include Singleton

  def initialize
    if ENV['MONGODB_URI']
      @mongodb_uri = Mongo::URI.new(ENV['MONGODB_URI'])
    end
  end

  def addresses
    if @mongodb_uri
      @mongodb_uri.servers
    else
      ['127.0.0.1']
    end
  end

  def mri?
    !jruby?
  end

  def jruby?
    RUBY_PLATFORM =~ /\bjava\b/
  end

  def platform
    RUBY_PLATFORM
  end

  def client_debug?
    %w(1 true yes).include?((ENV['CLIENT_DEBUG'] || '').downcase)
  end

  def ci?
    !!ENV['CI']
  end
end
