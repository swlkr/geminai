# geminai

A gem for gemini's interactions api

## Install

```ruby
# Gemfile
gem 'geminai'
```

## Setup

### Option 1: Global Configuration (Recommended for Rails initializers)

You can configure the client settings globally (e.g. in `config/initializers/geminai.rb`):

```ruby
require 'geminai'

Geminai.configure do |config|
  config.api_key = ENV['GEMINI_API_KEY']
  # config.base_url = "https://generativelanguage.googleapis.com" # Optional, default value
end
```

Once configured globally, you can instantiate the client without passing arguments:

```ruby
ai = Geminai.new
```

### Option 2: Direct Instantiation

Alternatively, you can instantiate the client by passing the API key directly:

```ruby
require 'geminai'

ai = Geminai.new(ENV['GEMINI_API_KEY'])
# or with a custom base url:
ai = Geminai.new('YOUR_API_KEY', base_url: 'https://custom-url.com')
```

---

## Usage Examples

### 1. Google Search

Geminai enables Google Search by passing the `google_search` tool

```ruby
prompt = "what is the latest news on alphabet's stock price?"

interaction = client.interact(
  model: 'gemini-3.5-flash',
  input: prompt,
  tools: [:google_search],
  store: false # Operate statelessly
)

# 1. Output the generation
puts interaction.output_text

# 2. Extract grounding metadata
metadata = interaction.grounding_metadata

puts "\nWeb Search Queries Run:"
p metadata.web_search_queries
# => ["Bloomberg", ...]

puts "\nWeb Citations:"
metadata.citations.each do |citation|
  puts "- #{citation[:title]} @ #{citation[:url]} (indexes: #{citation[:start_index]}..#{citation[:end_index]})"
end
# => - bloomberge.com @ https://vertexaisearch.cloud.google.com/grounding-api-redirect/...
```

### 2. Image Generation

Geminai includes a helper method `generate_image` which calls the Interactions API specifying `type: "image"` under `response_format`.

```ruby
require 'base64'

interaction = client.interact(
  "An image of a pelican riding a bicycle",
  model: 'gemini-3.1-flash-image',
  aspect_ratio: '1:1',
  image_size: '1K',
  store: false
)

# Extract and save generated images
interaction.output_files.each_with_index do |img, index|
  File.binwrite("pelican#{index}.png", Base64.decode64(img[:data]))
  puts "Saved pelican_#{index}.png"
end
```

### 3. Multi-turn Stateful Conversations

The Interactions API handles conversation history server-side. To continue a thread, pass `store: true` on your turns and feed the `id` of the previous interaction back into your subsequent requests using `previous_interaction_id`.

```ruby
# Turn 1: Save the context on the server
interaction_1 = client.interact(
  model: 'gemini-3.5-flash',
  input: 'My favorite jihad is a butlerian jihad',
  store: true
)

# Turn 2: Query context referencing the first interaction ID
interaction_2 = client.interact(
  model: 'gemini-3.5-flash',
  input: 'What is my favorite jihad?',
  previous_interaction_id: interaction_1.id,
  store: true
)

puts interaction_2.output_text
# => "Your favorite jihad is a butlerian jihad."
```

### 4. Video generation

```ruby
# Generate a video
interaction = client.generate_video(
  "A beautiful sunset over a calm ocean.",
  model: "gemini-omni-flash-preview"
)

if interaction.output_video
  # Access base64 data
  video_data = interaction.output_video[:data]
  # Or access the URI if delivery: "uri" was used
  video_uri = interaction.output_video[:uri]
end

# Stateful video editing
edit_interaction = client.interact(
  model: "gemini-omni-flash-preview",
  input: "Make the sun more vibrant and red.",
  previous_interaction_id: interaction.id
)
```

### 5. Structured JSON Output (JSON Schema)

Geminai supports structured JSON output using JSON schemas. You can pass a schema layout to define target properties, types, and constraints for the model output:

```ruby
schema = {
  name: :string,
  price: :number,
  url: :string
}

interaction = client.interact(
  model: 'gemini-3.5-flash',
  input: 'Recommend a good mechanical keyboard with its name, estimated price in USD, and a manufacturer URL.',
  schema: schema,
  store: false
)

# The output text is guaranteed to be a JSON string adhering to the schema
puts interaction.output_text
# => "{\"name\":\"Keychron K2\",\"price\":79.99,\"url\":\"https://www.keychron.com/\"}"

# You can also request a top-level list/array by wrapping the schema in a Ruby Array:
array_schema = [
  {
    name: :string,
    price: :number,
    url: :string
  }
]

array_interaction = client.interact(
  model: 'gemini-3.5-flash',
  input: 'Recommend three good mechanical keyboards.',
  schema: array_schema,
  store: false
)

puts array_interaction.output_text
# => "[{\"name\":\"Keychron K2\",\"price\":79.99,\"url\":\"https://www.keychron.com/\"}, ...]"
```

## Running Tests

To run the integration tests (which execute live requests to the API), verify your `GEMINI_API_KEY` is present in your environment and run:

```bash
ruby -Ilib test/geminai_test.rb
```
