# frozen_string_literal: true
# run rake db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections
namespace :db do
  namespace :non_rss_feeds do
    task(
      :crawl_dow_jones_select_non_rss_feed_sections,
      [
        :non_rss_feed_name,
        :bucket_name,
        :file_path
      ] => :environment
    ) do |_, args|
      non_rss_feed_name = args.non_rss_feed_name
      bucket_name = args.bucket_name
      file_path = args.file_path

      [
        ['non_rss_feed_name', non_rss_feed_name],
        ['bucket_name', bucket_name],
        ['file_path', file_path]
      ].each do |k, v|
        raise "#{k} missing." if v.blank?
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections ' \
        "- INFO! Starting with args #{args.inspect}"
      )

      begin

        non_rss_feed = NonRssFeed.find_by(
          name: non_rss_feed_name
        )

        rss_feed_hashes = NonRssFeeds::DowJonesSelect::MultiRssFeedUploader.new(
          NonRssFeeds::DowJonesSelect::ArticlesToSectionRssFeeder.new(
            NonRssFeeds::DowJonesSelect::ArticlesDownloader.new(
              non_rss_feed
            ).articles,
            non_rss_feed
          ).xml_rss_feeds,
          bucket_name,
          file_path
        ).upload

        rss_feed_hashes.each do |rss_feed_hash|
          rss_feed_name = rss_feed_hash[:rss_feed_name].to_s
          rss_feed_description = rss_feed_hash[:rss_feed_description].to_s
          rss_feed_url = rss_feed_hash[:rss_feed_url].to_s

          if rss_feed_url.blank?
            ::Rails.logger.info(
              'db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections ' \
              'rss_feed_url is blank'
            )
            next
          end

          rss_feed = RssFeed.find_or_create_by(
            url: rss_feed_url
          )
          rss_feed.update_attributes!(
            name: rss_feed_description,
            rss_publisher: rss_feed_name,
            needs_sanitize: false,
            is_scan_summary_for_image: false,
            is_proxy_needed: false,
            is_mobile_proxy_needed: false,
            is_diffbot_enabled: false,
            is_favor_pismo_over_diffbot: false,
            is_pismo_enabled: false,
            custom_rss_feed: false,
            allow_bot_access: false,
            allow_no_entry_url: true,
            max_articles_per_crawl: 1000,
            # Should really be false
            # since the articles are only
            # located in our database
            # and have no outside location.
            # However, this will trigger
            # logic on the front end
            # to display the interstitial webpage.
            external_only: true,
            is_premium: true,
            non_rss_feed: non_rss_feed
          )
          non_rss_feed.update_attributes!(
            updated_at: Time.zone.now,
            rss_feed_id: rss_feed.id
          )
          ::Rails.logger.info(
            'db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections ' \
            " - INFO! #{rss_feed.inspect}"
          )
        end
      rescue StandardError => error
        ::Rails.logger.info(
          'db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections ' \
          "- ERROR! #{error}"
        )
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:crawl_dow_jones_select_non_rss_feed_sections ' \
        '- INFO! Done.'
      )
    end
  end
end
