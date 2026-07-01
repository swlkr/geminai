require "net/http"
require "uri"
require "json"

module Geminai
  class Client
    attr_reader :api_key, :base_url

    def initialize(api_key: nil, base_url: nil)
      @api_key = api_key || ENV["GEMINI_API_KEY"]
      @base_url = base_url || "https://generativelanguage.googleapis.com"

      if @api_key.nil? || @api_key.empty?
        raise ArgumentError, "API Key is required"
      end
    end

    def interact(model:, input:, **options)
      uri = URI.parse("#{@base_url}/v1beta/interactions")

      body = {
        model: model,
        input: input
      }

      # Forward all recognized interactions API request parameters
      [
        :system_instruction,
        :generation_config,
        :response_format,
        :tools,
        :previous_interaction_id,
        :stream,
        :store
      ].each do |opt|
        body[opt] = options[opt] if options.key?(opt)
      end

      # Handle any extra keys passed in options as well to be fully future-proof
      options.each do |k, v|
        next if body.key?(k)
        body[k] = v
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      # Net::HTTP defaults read timeout is 60s, but search grounding or image generation can take longer,
      # let's set a generous timeout.
      http.read_timeout = 120

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = @api_key
      request.body = JSON.generate(body)

      response = http.request(request)

      unless response.code == "200"
        raise(
          ApiError.new("API Request failed with code #{response.code}: #{response.body}", response.code, response.body)
        )
      end

      data = JSON.parse(response.body, symbolize_names: true)
      Interaction.new(data)
    end

    # Helper method for image generation using response_format
    def generate_image(prompt, model:, aspect_ratio: "1:1", image_size: "1K", **options)
      interact(
        model: model,
        input: prompt,
        response_format: {
          type: "image",
          aspect_ratio: aspect_ratio,
          image_size: image_size
        },
        **options
      )
    end
  end

  class ApiError < StandardError
    attr_reader :code, :response_body

    def initialize(message, code = nil, response_body = nil)
      super(message)
      @code = code
      @response_body = response_body
    end
  end
end
