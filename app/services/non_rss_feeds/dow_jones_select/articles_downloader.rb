# frozen_string_literal: true

module NonRssFeeds
  module DowJonesSelect
    class ArticlesDownloader
      SELECT_URL = 'http://select.factiva.com/'

      def initialize(non_rss_feed)
        @non_rss_feed = non_rss_feed
      end

      def articles
        xml_articles = xml_articles_from_feed_files
        parsed_articles = xml_articles_to_parsed_articles(xml_articles)
        article_objects = description_from_paragraphs(parsed_articles)
        delete_xml_articles
        articles = article_objects_to_hash(article_objects)
        articles
      end

      private

      def xml_articles_from_feed_files
        feed_files.map do |file_name|
          get_single_xml_article(file_name)
        end.compact
      end

      def delete_xml_articles
        feed_files.map do |file_name|
          delete_single_xml_article(file_name)
        end
      rescue => e
        ::Rails.logger.warn("Deleting xml articles failed - error #{e}")
      end

      def description_from_paragraphs(articles)
        articles.each do |article|
          if article.try(:archive_doc).try(:first).try(:paragraphs).is_a?(Enumerable)
            article.description = article.archive_doc.first.paragraphs.join(
              '<br> <br>'
            )
          end
          if article.try(:summary_paragraphs).try(:first).try(:paragraphs).is_a?(Enumerable)
            article.summary = article.summary_paragraphs.first.paragraphs.join(
              ' '
            ).gsub(/\[.*\]\s*/, '')
          end
          article.archive_doc = nil
        end
      end

      def feed_files
        @feed_files ||= feed_files_in_csv.split(',')
      end

      def feed_files_in_csv
        http_connection.get("filelist.asp?user=#{username}").body
      rescue => e
        ::Rails.logger.warn("Dow Jones Select articles list call error #{e}")
        ''
      end

      def get_single_xml_article(file_name)
        http_connection.get("#{username}/#{file_name}").body
      rescue => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        nil
      end

      def delete_single_xml_article(file_name)
        http_delete(
          "filedel.asp?user=#{username}&files=#{file_name}"
        )
      end

      def http_connection
        conn = Faraday.new(url: SELECT_URL)
        conn.basic_auth(username, password)
        conn
      end

      def http_delete(url)
        http_connection.get(url).body
      end

      def xml_articles_to_parsed_articles(xml_articles)
        xml_articles.map do |xml|
          Feedjira::Feed.parse_with(
            NonRssFeeds::DowJonesSelect::FeedParser,
            xml
          )
        end
      end

      def check_for_new_articles(articles)
        Array.wrap(articles).uniq do |article|
          "#{article.title}#{article.published}"
        end
      end

      def logo_url(article)
        "#{article.logo_src}/#{article.logo_img}"
      end

      def article_objects_to_hash(article_objects)
        article_objects.map do |article|
          {
            id: article.article_id,
            title: article.title,
            published_at: article.published,
            author: article.author,
            summary: article.summary,
            content: article.description,
            section: article.section,
            folder: article.folder,
            source: article.source
          }
        end
      end

      def username
        @non_rss_feed.miscellaneous.try(:[], 'username')
      end

      def password
        @non_rss_feed.miscellaneous.try(:[], 'password')
      end
    end
  end
end
