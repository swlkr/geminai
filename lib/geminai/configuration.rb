module Geminai
  class Configuration
    attr_accessor :api_key, :base_url

    def initialize
      @api_key = ENV["GEMINI_API_KEY"]
      @base_url = "https://generativelanguage.googleapis.com"
    end
  end
end
