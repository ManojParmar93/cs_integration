# frozen_string_literal: true

module NonRssFeeds
  module DowJones
    class LastModifiedChecker # rubocop:disable Documentation
      include ::NonRssFeeds::DowJones::Mixins::DowJonesCrawlerHelperMixin

      def initialize(dow_jones_non_rss_feed)
        @non_rss_feed = dow_jones_non_rss_feed
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
        return Time.zone.at(0) if json.blank?
        Time.zone.parse(
          "#{json['LastModifiedDate']}T#{json['LastModifiedTime']}"
        )
      end

      def json
        JSON.parse(
          request_collection_code.body
        )['Collections'].first
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        {}
      end

      def request_collection_code
        Faraday.get(
          last_modified_api,
          code_encrypted_token_query_params,
          {}
        )
      end

      def last_modified_api
        'https://api.dowjones.com/api/public/2.0/Collection/Code/json'
      end
    end
  end
end
