require 'json'
require 'net/http'

module NonRssFeeds
  module NorthernTrust
    class PostsDownloader
      NORTHERNTRUST_POSTS_URI = "https://www.northerntrust.com/api/gridSearch?&query=*&filterString=%5b%7B%22name%22%3A%22publications%22%2C%22values%22%3A%5B%22*%22%5D%7D%5d&region=united-states&start=1&pageSize=9"
      attr_reader :articles, :channel_data

      def initialize
        articles = get_posts['results'].select do |article|
          valid_item? "#{article['url']}#{['articleDate']}"
        end
        @articles = articles.collect do |article|
          HashWithIndifferentAccess.new(article)
        end
        @file_name = Rails.env.test? ? "northern_trust_test.rss" : "post_#{Time.now.to_i}.rss"
        @channel_data = {}
      end

      def call
        {xml_rss_feed: xml_rss_feed,
          are_items_present: @articles.present?,
          file_name: @file_name}
      end

      def xml_rss_feed
        return unless @articles.is_a?(Array)
        make_feed
      # rescue StandardError => error
      #   ::Rails.logger.error(
      #     "#{self.class.name}##{__method__} - ERROR! #{error}"
      #   )
      #   nil
      end

      def http_connection
        Faraday.new(options = {headers: {user_agent: 'Mozilla/5.0',
            Accept: '*/*', Connection: 'keep-alive'},
            url: NORTHERNTRUST_POSTS_URI})
      end

      private

        def make_feed
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
          channel.title "Northerntrust"
          channel.link "https://www.northerntrust.com​"
          channel.description "Northerntrust Article Data"
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
          item.guid "#{article[:url]}#{article[:articleDate]}"
          item.title article[:title]
          item.pubDate Time.zone.parse(
            article[:articleDate].to_s
          ).to_formatted_s(:rfc822) rescue ""
          item.link article[:articleURL]
          item.description ActionView::Base.full_sanitizer.sanitize(article[:articleDescription])
          # http://www.lowter.com/blogs/2008/2/9/rss-dccreator-author
          item.dc(:creator) do |dc|
            dc.text! article[:author_name]
          end if article[:author_name].present?
          item.media(
            :content,
            url: article[:post_url],
            fileSize: article[:image_size],
            type: article[:image_type]
          ) do |media_content|
            media_content.media(
              :credit,
              role: 'photographer',
              scheme: 'urn:ebu'
            ) do |media_credit|
              media_credit.text! article[:image_credit]
            end if article[:image_credit].present?
          end if article[:image_url].present?
          # https://developer.mozilla.org/en-US/docs/Web/RSS/
          # Article/Why_RSS_Content_Module_is_Popular_-_Including_HTML_Contents
          item.content(:encoded) do |content|
            content.cdata!(article[:summary])
          end
        end

        def get_posts
          response = http_connection.get()
          JSON.parse(response.body)
        end

        def valid_item?(guid)
          return false if ArticleItem.northern_trust.find_by(guid: guid)
          ArticleItem.northern_trust.create(guid: guid)
        end
    end
  end
end