module NonRssFeeds
  module DowJones
    # Takes multiple rss feeds as input and uploads them to a bucket
    class MultiRssFeedUploader
      def initialize(xml_rss_feeds, bucket_name, default_path)
        @xml_rss_feeds = xml_rss_feeds
        @default_path = default_path
        @bucket_name = bucket_name
      end

      def upload
        @xml_rss_feeds.map do |xml_rss_feed|
          {
            rss_feed_name: xml_rss_feed_title(xml_rss_feed),
            rss_feed_url: NonRssFeeds::DowJones::RssFeedUploader.new(
              xml_rss_feed,
              @bucket_name,
              path(xml_rss_feed)
            ).upload
          }
        end
      end

      private

      def path(xml_rss_feed)
        title = xml_rss_feed_title(xml_rss_feed)
        return @default_path if title.blank?
        title.to_s.to_url.underscore + '.xml'
      end

      def xml_rss_feed_title(xml_rss_feed)
        Feedjira::Feed.parse(xml_rss_feed).title
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        ''
      end
    end
  end
end
