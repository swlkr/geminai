require_relative "geminai/version"
require_relative "geminai/step"
require_relative "geminai/grounding_metadata"
require_relative "geminai/interaction"
require_relative "geminai/client"
require_relative "geminai/schema_builder"
require_relative "geminai/configuration"

module Geminai
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  # Helper to construct a client
  def self.new(api_key = nil, base_url: nil)
    Client.new(api_key: api_key, base_url: base_url)
  end
end
