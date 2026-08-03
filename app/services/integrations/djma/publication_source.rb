require "net/http"
require "nokogiri"
require "shellwords"
require "tempfile"

module Integrations
  module Djma
    class PublicationSource
      Result = Struct.new(:text, :url, keyword_init: true)

      def initialize(url: ENV["DJMA_PUBLICATIONS_URL"])
        @url = url.to_s
      end

      def fetch
        raise ArgumentError, "DJMA_PUBLICATIONS_URL ausente" if url.blank?

        response = Net::HTTP.get_response(URI(url))
        raise "Falha ao baixar DJMA: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        Result.new(text: extract_text(response.body, response["Content-Type"].to_s), url: url)
      end

      private

      attr_reader :url

      def extract_text(body, content_type)
        return extract_pdf_text(body) if content_type.include?("pdf") || url.downcase.end_with?(".pdf")

        Nokogiri::HTML(body).text.squish
      end

      def extract_pdf_text(body)
        Tempfile.create([ "djma-publication", ".pdf" ], binmode: true) do |file|
          file.write(body)
          file.flush
          `pdftotext -layout #{Shellwords.escape(file.path)} -`
        end
      end
    end
  end
end
