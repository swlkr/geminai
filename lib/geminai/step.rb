module Geminai
  class Step
    attr_reader :id, :type, :signature, :content, :arguments, :result, :raw_step

    def initialize(data)
      @raw_step = data
      @id = data[:id]
      @type = data[:type]
      @signature = data[:signature]
      @content = data[:content]
      @arguments = data[:arguments]
      @result = data[:result]
    end

    def thought?
      @type == "thought"
    end

    def model_output?
      @type == "model_output"
    end

    def google_search_call?
      @type == "google_search_call"
    end

    def google_search_result?
      @type == "google_search_result"
    end
  end
end
