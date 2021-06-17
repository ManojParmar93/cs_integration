# frozen_string_literal: true
module NonRssFeeds
  module DowJones
    # Downloads the headlines
    # and transforms them
    # for the ArticlesDownloader.
    class HeadlinesDownloader
      include ::NonRssFeeds::DowJones::Mixins::DowJonesCrawlerHelperMixin

      def initialize(dow_jones_non_rss_feed)
        @non_rss_feed = dow_jones_non_rss_feed
      end

      def headlines
        transform_raw_headlines
      end

      private

      def transform_raw_headlines
        headlines_raw.to_a.map do |raw_headline|
          transform_raw_headline(raw_headline)
        end.compact
      end

      def transform_raw_headline(raw_headline) # rubocop:disable AbcSize, MethodLength, LineLength
        {
          article_ref: 'article:archive/' + raw_headline.try(
            :[],
            'ParentArticle'
          ),
          title: raw_headline.try(
            :[],
            'Title'
          ).to_a.first.try(:[], 'Items').to_a.first.try(:[], 'Value'),
          author: raw_headline.try(:[], 'ByLine').try(
            :[],
            'Items'
          ).to_a.first.try(:[], 'Value').to_s.sub('By ', '').strip.presence,
          published_at: create_published_at_date_time(
            raw_headline['PublicationDateTime']
          ),
          summary: raw_headline.try(:[], 'Snippet').try(
            :[],
            'Items'
          ).to_a.first.try(:[], 'Value').to_s.strip.presence,
          encrypted_token: encrypted_token
        }.merge(
          image_data_hash(raw_headline)
        )
      rescue StandardError => error
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{error} #{raw_headline}"
        )
        nil
      end

      def image_data_hash(raw_headline)
        data = find_image_data_in_raw_headline(raw_headline)
        return {} if data.blank?
        {
          image_url: data['Link'],
          image_size: data['Size'],
          image_type: data['MIMEType'],
          image_credit: data['ImageCredit']
        }
      end

      def find_image_data_in_raw_headline(raw_headline)
        raw_headline['Metadata']['ContentItems'].find do |content_item|
          content_item['Type'].casecmp('dispix').zero?
        end
      rescue StandardError => error
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{error}"
        )
        nil
      end

      def create_published_at_date_time(json_date_string)
        Time.zone.at(
          json_date_string.sub('/Date(', '').sub(')/', '').to_i / 1000
        )
      rescue StandardError => error
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{error}"
        )
        Time.zone.now
      end

      def headlines_raw
        @headlines_raw ||= JSON.parse(
          request_raw_headlines.body
        )['Headlines']
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        []
      end

      def request_raw_headlines
        Faraday.get(
          headline_api_url,
          code_encrypted_token_query_params,
          {}
        )
      end

      def headline_api_url
        @non_rss_feed.url
      end
    end
  end
end
