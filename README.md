# geminai

A gem for gemini's interactions api

* **Built-in Tools**: Native search grounding (`google_search`), mapping citations, and suggestions.
* **Image Generation**: High-fidelity native image generation (`gemini-3.1-flash-image`) with direct config like `aspect_ratio` and `image_size`.
* **Stateful Conversations**: Seamless multi-turn conversations managed server-side via `previous_interaction_id`.
* **Stateless Conversations**: Client-managed conversation paths using `store: false`.
* **Zero Dependencies**: Pure Ruby standard library (`net/http` and `json`)

## Install

```ruby
# Gemfile
gem 'geminai'
```

## Setup

```ruby
require 'geminai'

ai = Geminai.new(ENV['GEMINI_API_KEY'])
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
  tools: [{ type: 'google_search' }],
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

interaction = client.generate_image(
  "An image of a pelican riding a bicycle",
  model: 'gemini-3.1-flash-image',
  aspect_ratio: '1:1',
  image_size: '1K',
  store: false
)

# Extract and save generated images
interaction.output_images.each_with_index do |img, index|
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

## Running Tests

To run the integration tests (which execute live requests to the API), verify your `GEMINI_API_KEY` is present in your environment and run:

```bash
ruby -Ilib test/geminai_test.rb
```
