# frozen_string_literal: true

module NonRssFeeds
  module DowJones
    module Mixins
      module DowJonesCrawlerHelperMixin # rubocop:disable Documentation
        def code_encrypted_token_query_params
          return {} if @non_rss_feed.blank?
          {
            code: code,
            encryptedToken: encrypted_token
          }
        end

        def code
          @non_rss_feed.try(
            :miscellaneous
          ).try(:[], 'code').presence || 'NP_Lifestyle_1'
        end

        def encrypted_token
          @non_rss_feed.try(:miscellaneous).try(:[], 'encrypted_token')
        end
      end
    end
  end
end
