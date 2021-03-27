module NonRssFeeds
  module Morningstar
    # Downloads articles from the Morningstar ftp server
    # using credentials stores in the non_rss_feed
    class ArticlesParser
      def initialize(articles)
        @articles = articles
      end

      def parse
        parse_articles
      end

      private

      def parse_articles
        @articles.map do |article|
          article_parser = parser(article)
          next if article_parser.try(:text).blank?
          article_hash(article_parser)
        end.compact
      end

      def article_hash(article_parser)
        {
          id: id(article_parser),
          title: title(article_parser),
          author: author(article_parser),
          summary: summary(article_parser),
          published_at: published_at(article_parser),
          content: content(article_parser),
          section: section(article_parser)
        }
      end

      def parser(article)
        Nokogiri::XML(article)
      rescue => e
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{e}"
        )
        nil
      end

      def title(parser)
        parser.xpath('//title').text
      end

      def content(parser)
        parser.xpath('//body').to_s
      end

      def author(parser)
        parser.xpath('//author').text
      end

      def published_at(parser)
        parser.xpath('//publish_date').text
      end

      def summary(parser)
        parser.xpath('//deck').text
      end

      def section(parser)
        parser.xpath('//collection').text
      end

      def id(parser)
        parser.xpath('/article').attribute('id').value
      end
    end
  end
end
