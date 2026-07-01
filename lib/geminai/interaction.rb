module Geminai
  class Interaction
    attr_reader :id, :status, :usage, :created, :updated, :model, :steps, :raw_data

    def initialize(data)
      @raw_data = data
      @id = data[:id]
      @status = data[:status]
      @usage = data[:usage]
      @created = data[:created]
      @updated = data[:updated]
      @model = data[:model]

      @steps = (data[:steps] || []).map { |step_data| Step.new(step_data) }
    end

    def output_text
      text_parts = []
      @steps.each do |step|
        next unless step.model_output?
        (step.content || []).each do |part|
          text_parts << part[:text] if part[:type] == "text" && part[:text]
        end
      end

      text_parts.join("")
    end

    def output_images
      images = []
      @steps.each do |step|
        next unless step.model_output?
        (step.content || []).each do |part|
          if part[:type] == "image"
            images <<
              {
                data: part[:data],
                mime_type: part[:mime_type]
              }
          elsif part[:image]
            # Handle other possible image shapes in responses if applicable
            images <<
              {
                data: part[:image][:data] || part[:image][:image_bytes],
                mime_type: part[:image][:mime_type]
              }
          end
        end
      end

      images
    end

    def grounding_metadata
      queries = []
      citations = []
      suggestions = nil

      @steps.each do |step|
        if step.google_search_call?
          if step.arguments && step.arguments[:queries]
            queries.concat(step.arguments[:queries])
          end
        elsif step.google_search_result?
          if step.result
            (step.result || []).each do |res|
              if res[:search_suggestions]
                suggestions = res[:search_suggestions]
              end
            end
          end
        elsif step.model_output?
          (step.content || []).each do |part|
            if part[:type] == "text" && part[:annotations]
              part[:annotations].each do |ann|
                citations <<
                  {
                    start_index: ann[:start_index],
                    end_index: ann[:end_index],
                    url: ann[:url],
                    title: ann[:title],
                    type: ann[:type]
                  }
              end
            end
          end
        end
      end

      GroundingMetadata.new(
        web_search_queries: queries.uniq,
        citations: citations,
        search_suggestions: suggestions
      )
    end
  end
end
