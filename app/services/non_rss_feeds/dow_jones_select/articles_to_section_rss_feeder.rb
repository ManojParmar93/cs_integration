# frozen_string_literal: true

module NonRssFeeds
  module DowJonesSelect
    # Takes the downloaded articles and splits them into buckets and generates
    # an XML RSS feed document.
    class ArticlesToSectionRssFeeder
      DEFAULT_LIMITS = {
        'MarketWatch' => 40,
        "Barron's Online" => 5,
        'The Wall Street Journal' => 3
      }.freeze

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
        article_sections = @articles.group_by { |article| article[:source] }
        article_limits.map do |publisher_name, publisher_limit|
          next if article_sections[publisher_name].blank?
          limited_articles = article_sections[publisher_name].slice(
            0,
            publisher_limit
          )
          limited_article_sections = limited_articles.group_by do |article|
            article[:section] || article[:folder]
          end

          limited_article_sections.map do |section_title, section_articles|
            next if section_articles.blank?
            title = publisher_name.to_s.strip
            make_section_rss_feed(title, section_title, section_articles)
          end
        end.flatten
      end

      def article_limits
        limits = @non_rss_feed.miscellaneous.try(:[], 'limits')
        return DEFAULT_LIMITS if limits.blank?
        limits
      end

      def make_section_rss_feed(title, section_title, section_articles)
        NonRssFeeds::DowJones::ArticlesToRssFeeder.new(
          section_articles,
          title: title,
          link: @non_rss_feed.url,
          description: section_title
        ).xml_rss_feed
      end
    end
  end
end
