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

    def files
      files = []
      @steps.each do |step|
        next unless step.model_output?
        (step.content || []).each do |part|
          file_data = extract_file_data(part)
          files << file_data if file_data
        end
      end

      # Also include top-level outputs (like output_audio) if present in raw data
      @raw_data.each do |key, value|
        if key.to_s.start_with?("output_") && value.is_a?(Hash) && (value[:data] || value[:uri])
          files << value.merge(type: key.to_s.sub("output_", ""))
        end
      end

      files
    end

    alias_method :output_files, :files

    def base64(type = nil)
      file = if type
        files.find { |f| f[:type] == type.to_s && f[:data] }
      else
        files.find { |f| f[:data] }
      end

      file ? file[:data] : nil
    end

    alias_method :base64_file, :base64

    def uri(type = nil)
      file = if type
        files.find { |f| f[:type] == type.to_s && f[:uri] }
      else
        files.find { |f| f[:uri] }
      end

      file ? file[:uri] : nil
    end

    alias_method :uri_file, :uri

    # Deprecated specific helpers kept for compatibility but powered by generic methods
    def output_images
      files.select { |f| f[:type] == "image" }
    end

    def output_videos
      files.select { |f| f[:type] == "video" }
    end

    def output_video
      output_videos.first
    end

    def output_audio
      files.select { |f| f[:type] == "audio" }.first
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

    private

    def extract_file_data(part)
      # Check part[:type]
      if %w[image video audio file].include?(part[:type])
        return {
          type: part[:type],
          data: part[:data],
          uri: part[:uri],
          mime_type: part[:mime_type]
        }
      end

      # Check for keys like :image, :video, :audio
      [:image, :video, :audio].each do |key|
        if part[key]
          data = part[key]
          return {
            type: key.to_s,
            data: data[:data] || data[:image_bytes] || data[:video_bytes] || data[:audio_bytes],
            uri: data[:uri],
            mime_type: data[:mime_type]
          }
        end
      end

      nil
    end
  end
end
