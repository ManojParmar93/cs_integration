# frozen_string_literal: true
namespace :db do
  namespace :non_rss_feeds do
    task(
      :provision_morningstar_non_rss_feed,
      [
        :name,
        :url,
        :userid,
        :password,
      ] => :environment
    ) do |_, args|
      name = args.name
      url = args.url
      userid = args.userid
      password = args.password

      [
        ['name', name],
        ['url', url],
        ['userid', userid],
        ['password', password]
      ].each do |k, v|
        raise "#{k} missing." if v.blank?
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:provision_morningstar_non_rss_feed ' \
        "- INFO! Starting with args #{args.inspect}"
      )

      morningstar = NonRssFeed.find_or_create_by(
        name: name
      )
      morningstar.url = url
      morningstar.miscellaneous = {
        'user_id' => userid,
        'password' => password
      }
      morningstar.is_premium = true
      morningstar.save!
      ::Rails.logger.info(
        'db:non_rss_feeds:provision_morningstar_non_rss_feed ' \
        '- INFO! Done.'
      )
    end
  end
end
