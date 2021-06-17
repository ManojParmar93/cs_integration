require 'net/sftp'

module NonRssFeeds
  module Morningstar
    # Downloads articles from the Morningstar ftp server
    # using credentials stores in the non_rss_feed
    class ArticlesDownloader
      def initialize(non_rss_feed)
        @non_rss_feed = non_rss_feed
      end

      def articles
        download_articles
      end

      private

      def download_articles
        @articles = []
        Net::SFTP.start(*args) do |sftp|
          xml_file_names(sftp).each do |file_name|
            download_files(sftp, file_name)
          end
        end
        @articles
      end

      def args
        [
          @non_rss_feed.url,
          @non_rss_feed.miscellaneous['user_id'],
          password: @non_rss_feed.miscellaneous['password']
        ]
      end

      def xml_file_names(sftp)
        file_names = []
        sftp.dir.foreach('/data') do |e|
          next if !e.name.include?('.xml')
          file_names << e.name
        end
        file_names
      end

      def download_files(sftp, file_name)
        article = sftp.download!("/data/#{file_name}")
        @articles << article
      rescue => e
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{e}"
        )
      end
    end
  end
end
