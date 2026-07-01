module Geminai
  class GroundingMetadata
    attr_reader :web_search_queries, :citations, :search_suggestions

    def initialize(web_search_queries: [], citations: [], search_suggestions: nil)
      @web_search_queries = web_search_queries
      @citations = citations
      @search_suggestions = search_suggestions
    end

    def empty?
      @web_search_queries.empty? && @citations.empty? && @search_suggestions.nil?
    end
  end
end
