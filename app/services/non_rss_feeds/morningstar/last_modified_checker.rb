# frozen_string_literal: true

module NonRssFeeds
  module Morningstar
    class LastModifiedChecker # rubocop:disable Documentation
      attr_reader :last_modified_time

      def initialize(morningstar_non_rss_feed)
        @non_rss_feed = morningstar_non_rss_feed
      end

      def up_to_date?
        return false unless @non_rss_feed.is_a?(NonRssFeed)
        @non_rss_feed.updated_at.to_i >= last_modified_date_time.to_i
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        false
      end

      private

      def last_modified_date_time
        return Time.zone.at(0) if time.blank?
        Time.zone.at(time)
      end

      def args
        [
          @non_rss_feed.url,
          @non_rss_feed.miscellaneous['user_id'],
          password: @non_rss_feed.miscellaneous['password']
        ]
      end

      def time
        @time ||= request_modified_time
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        nil
      end

      def request_modified_time
        time = nil
        Net::SFTP.start(*args) do |sftp|
          sftp.dir.glob('/', 'data') do |entry|
            time = entry.attributes.mtime
          end
        end
        time
      end
    end
  end
end
