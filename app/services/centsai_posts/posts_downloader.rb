require 'json'
require 'net/http'

module CentsaiPosts
  class PostsDownloader
    include ApplicationHelper
    CENTSAI_POSTS_URI = 'https://centsai.com/api/centsai-api.php'

    def initialize(channel_data = {})
      articles = get_posts["posts"]
      @articles = articles.collect{|article| HashWithIndifferentAccess.new(article)}
      @channel_data = {}
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

    def http_connection
      conn = Faraday.new(url: CENTSAI_POSTS_URI)
      conn.basic_auth(ENV['USER_NAME'], ENV['PASSWORD'])
      conn
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
        channel.title @channel_data[:title]
        channel.link @channel_data[:link]
        channel.description @channel_data[:description]
        channel.pubDate DateTime.now.utc.to_formatted_s(:rfc822) rescue ""
        make_items(channel)
      end

      def make_items(channel)
        @articles.each do |article|
          channel.item do |item|
            make_item(item, article)
          end
        end
      end

      def make_item(item, article)
        item.guid article[:post_id]
        item.title article[:post_title]
        item.pubDate Time.zone.parse(
          article[:published_at].to_s
        ).to_formatted_s(:rfc822) rescue ""
        # http://www.lowter.com/blogs/2008/2/9/rss-dccreator-author
        item.dc(:creator) do |dc|
          dc.text! article[:author_name]
        end if article[:author_name].present?
        item.description remove_html_content(article[:post_content])
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
            media_credit.text! article[:author_image]
          end if article[:author_image].present?
        end if article[:post_image].present?
        # https://developer.mozilla.org/en-US/docs/Web/RSS/
        # Article/Why_RSS_Content_Module_is_Popular_-_Including_HTML_Contents
        item.content(:encoded) do |content|
          content.cdata!(remove_html_content(article[:post_content]))
        end
      end

      def get_posts
        response = http_connection.get()
        JSON.parse(response.body)
      end
  end
end
