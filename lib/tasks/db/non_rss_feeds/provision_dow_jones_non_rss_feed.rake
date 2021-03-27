# frozen_string_literal: true
namespace :db do
  namespace :non_rss_feeds do
    task(
      :provision_dow_jones_non_rss_feed,
      [
        :name,
        :url,
        :login_url,
        :userid,
        :password,
        :namespace,
        :code
      ] => :environment
    ) do |_, args|
      name = args.name
      url = args.url
      login_url = args.login_url
      userid = args.userid
      password = args.password
      namespacee = args.namespace
      code = args.code

      [
        ['name', name],
        ['url', url],
        ['login_url', login_url],
        ['userid', userid],
        ['password', password],
        ['namespace', namespacee],
        ['code', code]
      ].each do |k, v|
        raise "#{k} missing." if v.blank?
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:provision_dow_jones_non_rss_feed ' \
        "- INFO! Starting with args #{args.inspect}"
      )

      dow_jones = NonRssFeed.find_or_create_by(
        name: name
      )
      dow_jones.url = url

      response = Faraday.get(
        login_url,
        {
          userid: userid,
          password: password,
          namespace: namespacee,
          parts: 'encryptedToken'
        },
        {}
      )

      begin
        json = JSON.parse(response.body)
        miscellaneous = json.map { |k, v| [k.underscore, v] }.to_h
        dow_jones.miscellaneous = miscellaneous.merge('code' => code)
        dow_jones.is_premium = true
        dow_jones.save!
      rescue StandardError => error
        ::Rails.logger.info(
          'db:non_rss_feeds:provision_dow_jones_non_rss_feed ' \
          "- ERROR! #{error}"
        )
      end

      ::Rails.logger.info(
        'db:non_rss_feeds:provision_dow_jones_non_rss_feed ' \
        '- INFO! Done.'
      )
    end
  end
end
