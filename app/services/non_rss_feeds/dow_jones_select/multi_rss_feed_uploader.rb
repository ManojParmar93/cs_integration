# frozen_string_literal: true

module NonRssFeeds
  module DowJonesSelect
    # Takes multiple rss feeds as input and uploads them to a bucket
    class MultiRssFeedUploader
      def initialize(xml_rss_feeds, bucket_name, default_path)
        @xml_rss_feeds = xml_rss_feeds
        @default_path = default_path
        @bucket_name = bucket_name
      end

      def upload # rubocop:disable MethodLength
        Array.wrap(@xml_rss_feeds).map do |xml_rss_feed|
          name, description, path = name_description_path(xml_rss_feed)
          {
            rss_feed_name: name,
            rss_feed_description: description,
            rss_feed_url: NonRssFeeds::DowJones::RssFeedUploader.new(
              xml_rss_feed,
              @bucket_name,
              path
            ).upload
          }
        end
      end

      private

      def name_description_path(xml_rss_feed)
        parsed = feedjira_feed_parsed(xml_rss_feed)
        name = parsed.try(:title).presence || ''
        description = parsed.try(:description).presence || ''
        path = "#{name} #{description}".strip.presence || @default_path
        path = "#{path.to_s.to_url.underscore}.xml"
        [name, description, path]
      end

      def feedjira_feed_parsed(xml_rss_feed)
        Feedjira::Feed.parse(xml_rss_feed)
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        Hashie::Mash.new(title: '', description: '')
      end
    end
  end
end
