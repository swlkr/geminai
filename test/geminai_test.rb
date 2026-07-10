require "minitest/autorun"

require_relative "../lib/geminai"

class GeminaiTest < Minitest::Test
  def setup
    @api_key = ENV["GEMINI_API_KEY"]
    unless @api_key
      skip("GEMINI_API_KEY environment variable is not set. Skipping integration tests.")
    end

    @client = Geminai.new(@api_key)
  end

  def test_client_initialization
    assert_equal("https://generativelanguage.googleapis.com", @client.base_url)
    assert_equal(@api_key, @client.api_key)
  end

  def test_stateless_interact
    interaction = @client.interact(
      model: "gemini-3.5-flash",
      input: "Solve this equation: 3 + 4 = ?",
      store: false
    )

    assert_instance_of(Geminai::Interaction, interaction)
    assert_match(/7/, interaction.output_text)
    assert_equal("completed", interaction.status)
    assert_equal("gemini-3.5-flash", interaction.model)
  end

  def test_search_grounding
    prompt = "what is alphabet's stock price today?"

    interaction = @client.interact(
      model: "gemini-3.5-flash",
      input: prompt,
      tools: [{type: "google_search"}],
      store: false
    )

    assert_instance_of(Geminai::Interaction, interaction)

    output = interaction.output_text
    refute_nil(output)
    refute_empty(output)

    # Asserting that search grounding happened
    metadata = interaction.grounding_metadata
    refute_nil(metadata)
    refute_empty(metadata.web_search_queries)

    # Check that search query keywords are relevant
    has_query = metadata.web_search_queries.any?
    assert(has_query)

    # Validate citations
    refute_empty(metadata.citations, "Expected some web citations in the grounding metadata")

    has_citations = metadata.citations.any?
    assert(has_citations)
  end

  def test_image_generation
    interaction = @client.interact(
      model: "gemini-3.1-flash-image",
      input: "A clean aesthetic representation of the word 'GEMINAI' written on a black penny tile floor",
      aspect_ratio: "1:1",
      image_size: "1K",
      store: false
    )

    assert_instance_of(Geminai::Interaction, interaction)

    # Check simplified file access
    if interaction.base64
      assert_instance_of(String, interaction.base64)
    end
  end

  def test_stateful_multi_turn
    # Turn 1: Store the interaction to get a previous_interaction_id
    interaction_1 = @client.interact(
      model: "gemini-3.5-flash",
      input: "My favorite color is green. Remember this.",
      store: true
    )

    assert_instance_of(Geminai::Interaction, interaction_1)
    refute_nil(interaction_1.id)

    # Turn 2: Retrieve the response referencing Turn 1
    interaction_2 = @client.interact(
      model: "gemini-3.5-flash",
      input: "What is my favorite color?",
      previous_interaction_id: interaction_1.id,
      store: true
    )

    assert_instance_of(Geminai::Interaction, interaction_2)
    assert_match(/green/i, interaction_2.output_text)
  end

  def test_audio_generation
    interaction = @client.interact(
      model: "gemini-3.1-flash-tts-preview",
      input: "Have a wonderful day!",
      voice: "Kore",
      store: false
    )

    assert_instance_of(Geminai::Interaction, interaction)

    # Verify simplified audio access
    if interaction.base64
      assert_instance_of(String, interaction.base64)
    end
  end

  def test_global_configuration
    original_config = Geminai.configuration

    # Reset configuration for the test
    Geminai.configuration = nil

    Geminai.configure do |config|
      config.api_key = "configured_key"
      config.base_url = "configured_url"
    end

    assert_equal("configured_key", Geminai.configuration.api_key)
    assert_equal("configured_url", Geminai.configuration.base_url)

    # Geminai.new without args should use global config
    client = Geminai.new
    assert_equal("configured_key", client.api_key)
    assert_equal("configured_url", client.base_url)

    # Geminai.new with explicit args should override global config
    client_override = Geminai.new("override_key", base_url: "override_url")
    assert_equal("override_key", client_override.api_key)
    assert_equal("override_url", client_override.base_url)
  ensure
    # Restore original configuration
    Geminai.configuration = original_config
  end
end
