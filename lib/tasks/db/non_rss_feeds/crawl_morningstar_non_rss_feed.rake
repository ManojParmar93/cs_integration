# frozen_string_literal: true
# run rake db:non_rss_feeds:crawl_morningstar_non_rss_feed
namespace :db do
  namespace :non_rss_feeds do
    task(
      :crawl_morningstar_non_rss_feed,
      [
        :non_rss_feed_name,
        :rss_feed_publisher,
        :bucket_name,
        :file_path
      ] => :environment
    ) do |_, args|
      non_rss_feed_name = args.non_rss_feed_name
      rss_feed_publisher = args.rss_feed_publisher
      bucket_name = args.bucket_name
      file_path = args.file_path

      [
        ['non_rss_feed_name', non_rss_feed_name],
        ['rss_feed_publisher', rss_feed_publisher],
        ['bucket_name', bucket_name],
        ['file_path', file_path]
      ].each do |k, v|
        raise "#{k} missing." if v.blank?
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:crawl_morningstar_non_rss_feed ' \
        "- INFO! Starting with args #{args.inspect}"
      )

      begin
        non_rss_feed = NonRssFeed.find_by(
          name: non_rss_feed_name
        )

        Namespace = NonRssFeeds::Morningstar

        next ::Rails.logger.info(
          'db:non_rss_feeds:crawl_morningstar_non_rss_feed ' \
          ' - INFO! Non RSS feed is up to date.'
        ) if Namespace::LastModifiedChecker.new(
          non_rss_feed
        ).up_to_date?

        rss_feed_hashes = Namespace::MultiRssFeedUploader.new(
          Namespace::ArticlesToSectionRssFeeder.new(
            Namespace::ArticlesParser.new(
              Namespace::ArticlesDownloader.new(
                non_rss_feed
              ).articles
            ).parse,
            non_rss_feed
          ).xml_rss_feeds,
          bucket_name,
          file_path
        ).upload

        rss_feed_hashes.each do |rss_feed_hash|
          rss_feed_name = rss_feed_hash[:rss_feed_name].to_s
          rss_feed_url = rss_feed_hash[:rss_feed_url].to_s

          if rss_feed_url.blank?
            ::Rails.logger.info(
              'db:non_rss_feeds:crawl_morningstar_non_rss_feed_sections ' \
              'rss_feed_url is blank'
            )
            next
          end

          rss_feed = RssFeed.find_or_create_by(
            url: rss_feed_url
          )
          rss_feed.update_attributes!(
            name: rss_feed_name,
            rss_publisher: rss_feed_publisher,
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
            'db:non_rss_feeds:crawl_morningstar_non_rss_feed ' \
            " - INFO! #{rss_feed.inspect}"
          )
        end
      rescue StandardError => error
        ::Rails.logger.info(
          'db:non_rss_feeds:crawl_morningstar_non_rss_feed ' \
          "- ERROR! #{error}"
        )
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:crawl_morningstar_non_rss_feed ' \
        '- INFO! Done.'
      )
    end
  end
end