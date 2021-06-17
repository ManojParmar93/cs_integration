# frozen_string_literal: true

module NonRssFeeds
  module DowJones
    # Takes the downloaded articles and splits them into buckets and generates
    # an XML RSS feed document.
    class ArticlesToSectionRssFeeder
      def initialize(articles, non_rss_feed)
        @articles = articles
        @non_rss_feed = non_rss_feed
      end

      def xml_rss_feeds
        return unless @articles.is_a?(Array)
        make_feeds
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        []
      end

      private

      def make_feeds
        article_sections = @articles.group_by { |article| article[:section] }
        article_sections.map do |section_title, section_articles|
          next if section_articles.blank?
          make_section_rss_feed(section_title, section_articles)
        end
      end

      def make_section_rss_feed(section_title, section_articles)
        title = "#{section_title}".strip
        NonRssFeeds::DowJones::ArticlesToRssFeeder.new(
          section_articles,
          title: title,
          link: @non_rss_feed.url,
          description: ''
        ).xml_rss_feed
      end
    end
  end
end
