namespace :db do
  namespace :non_rss_feeds do
    task(
      :centsai_post_non_rss_feed,
      [
        :bucket_name,
        :file_path,
        :url_query
      ] => :environment
    ) do |_, args|
      bucket_name = args.bucket_name
      file_path = args.file_path
      [
        ['bucket_name', bucket_name],
        ['file_path', file_path],
        ['url_query', url_query]
      ].each do |k, v|
      raise "#{k} missing." if v.blank?
    end
    begin
      NonRssFeeds::CentsaiPosts::RssFeedUploader.new().call
    rescue StandardError => error
      ::Rails.logger.info(
        'db:non_rss_feeds:crawl_dow_jones_non_rss_feed ' \
        "- ERROR! #{error}"
      )
    end
  end
end
end