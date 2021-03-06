# frozen_string_literal: true

module NonRssFeeds
  module Morningstar
    # Takes the downloaded
    # articles and generates
    # an XML RSS feed document.
    class ArticlesToRssFeeder
      def initialize(articles, channel_data = {})
        @articles = articles
        @channel_data = channel_data
      end

      def xml_rss_feed
        return unless @articles.is_a?(Array)
        make_feed
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        nil
      end

      private

      def make_feed # rubocop:disable MethodLength
        xml = Builder::XmlMarkup.new
        xml.instruct!(:xml, version: '1.0', encoding: 'UTF-8')
        xml.rss(
          version: 2.0,
          'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
          'xmlns:media' => 'http://search.yahoo.com/mrss/'
        ) do |_|
          xml.channel do |channel|
            make_channel(channel)
          end
        end
      end

      def make_channel(channel)
        channel.title @channel_data[:title]
        channel.link @channel_data[:link]
        channel.description @channel_data[:description]
        channel.pubDate DateTime.now.utc.to_formatted_s(:rfc822)
        make_items(channel)
      end

      def make_items(channel)
        @articles.each do |article|
          channel.item do |item|
            make_item(item, article)
          end
        end
      end

      def make_item(item, article) # rubocop:disable MethodLength, AbcSize
        item.guid article[:id]
        item.title article[:title]
        if article[:published_at].to_s.present?
          item.pubDate Time.zone.parse(
            article[:published_at].to_s
          ).to_formatted_s(:rfc822)
        end
        # http://www.lowter.com/blogs/2008/2/9/rss-dccreator-author
        item.dc(:creator) do |dc|
          dc.text! article[:author]
        end if article[:author].present?
        item.description article[:summary]
        # Note that RSS 2.0 spec
        # does not validate with HTTPS.
        # These URLs are HTTPS from
        # the Morningstar SFTP server.
        # https://github.com/rubys/feedvalidator/issues/16
        # This is why enclosure was not used.
        # FeedJira will pick this up.
        item.media(
          :content,
          url: article[:image_url],
          fileSize: article[:image_size],
          type: article[:image_type]
        ) if article[:image_url].present?
        # https://developer.mozilla.org/en-US/docs/Web/RSS/
        # Article/Why_RSS_Content_Module_is_Popular_-_Including_HTML_Contents
        item.content(:encoded) do |content|
          content.cdata!(article[:content])
        end
      end
    end
  end
end
