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

      # Infer output shortcut from model name if not explicitly provided
      output = options.delete(:output)
      unless output
        if model.include?("-tts-") || model.include?("-audio")
          output = :audio
        elsif model.include?("-image")
          output = :image
        elsif model.include?("-video") || model.include?("-generate")
          output = :video
        end
      end

      # Handle output shortcut
      if output
        body[:response_format] = {type: output.to_s}
        body[:response_format][:aspect_ratio] = options.delete(:aspect_ratio) if options.key?(:aspect_ratio)
        body[:response_format][:image_size] = options.delete(:image_size) if options.key?(:image_size)
      end

      # Handle schema shortcut option
      schema = options.delete(:schema)
      if schema
        body[:response_format] = {
          type: "text",
          mime_type: "application/json",
          schema: SchemaBuilder.build(schema)
        }
      end

      if (voice = options.delete(:voice))
        body[:generation_config] = {speech_config: [{voice: voice}]}
      end

      # Merge other options, allowing them to override shortcuts if explicitly provided
      options.each do |k, v|
        if body[k].is_a?(Hash) && v.is_a?(Hash)
          body[k] = body[k].merge(v)
        else
          body[k] = v
        end
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
