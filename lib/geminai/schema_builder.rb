module Geminai
  module SchemaBuilder
    def self.build(schema)
      case schema
      when Symbol, String
        { type: normalize_type(schema) }
      when Array
        { type: "array", items: build(schema.first) }
      when Hash
        if schema.key?(:type) || schema.key?("type")
          normalized = schema.transform_keys(&:to_sym)
          normalized[:properties] = normalized[:properties].transform_values { |v| build(v) } if normalized[:properties]
          normalized[:items] = build(normalized[:items]) if normalized[:items]
          normalized
        else
          properties = {}
          required = []
          schema.each do |key, val|
            properties[key] = build(val)
            required << key.to_s
          end
          {
            type: "object",
            properties: properties,
            required: required
          }
        end
      else
        raise ArgumentError, "Unsupported schema format: #{schema.inspect}"
      end
    end

    def self.normalize_type(type)
      type = type.to_s.downcase
      case type
      when "str", "string"
        "string"
      when "int", "integer"
        "integer"
      when "float", "number"
        "number"
      when "bool", "boolean"
        "boolean"
      else
        type
      end
    end
  end
end
