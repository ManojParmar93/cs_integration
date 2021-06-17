# frozen_string_literal: true

module NonRssFeeds
  module Morningstar
    # Takes the RSS feed
    # and uploads it to a bucket
    # in AWS S3.
    class RssFeedUploader
      def initialize(xml_rss_feed, bucket_name, object_location)
        @xml_rss_feed = xml_rss_feed
        @bucket_name = bucket_name
        @object_location = object_location
      end

      def upload
        return unless parsable?
        write
        object.public_url.to_s
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        nil
      end

      private

      def write
        object.write(@xml_rss_feed, content_type: 'text/xml')
      end

      def object
        bucket.objects[@object_location]
      end

      def bucket
        s3.buckets[@bucket_name]
      end

      def s3
        @s3 ||= AWS::S3.new(
          access_key_id: S3::Config.config['access_key_id'],
          secret_access_key: S3::Config.config['secret_access_key']
        )
      end

      def parsable?
        return false if Feedjira::Feed.parse(
          @xml_rss_feed
        ).entries.first.title.blank?
        true
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        false
      end
    end
  end
end
