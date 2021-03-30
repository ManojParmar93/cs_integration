require 'json'
require 'net/http'

module CentsaiPosts
  class PostsDownloader
    CENTSAI_POSTS_URI = 'https://centsai.com/api/centsai-api.php'
    TIME_FORMATE = '%a, %d %b %Y %H:%M:%S +0000'

    COMMON_XML_CONTENT = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <channel>
        <title>centsai</title>
        <language>en-US</language>
        <description>centsai</description>
        <lastBuildDate>Sat, 27 Mar 2021 09:08:45 +0000</lastBuildDate>
        <updatePeriod>hourly</updatePeriod>
        <updateFrequency type=\"integer\">1</updateFrequency>
        <generator>https://wordpress.org/?v=5.6.1</generator>
        POSTS_TO_BE_REPLACED
      </channel>"

    def initilize
    end

    
    def rss_field_xml_string
      COMMON_XML_CONTENT.gsub('POSTS_TO_BE_REPLACED', items_in_xml_formate)
    end

    def http_connection
      conn = Faraday.new(url: CENTSAI_POSTS_URI)
      conn.basic_auth('apiuser@vestorly.com', 'Vestorly@CentSaiAPI!')
      conn
    end

    private
      def parse_posts(records)
        post_data = records["posts"]
        post_data.map do |post|
          post_hash(post)
        end
      end

      def post_hash(post_object)
        {guid: post_object["post_id"],
        title: post_object["post_title"],
        content: post_object["post_content"].to_json,
        cc: post_object["author_name"],
        media: {url: post_object["post_image"]}}
        # {
        #   post_id: post_object["post_id"],
        #   post_template: post_object["post_template"],
        #   post_title: post_object["post_title"],
        #   post_content: post_object["post_content"],
        #   post_image: post_object["post_image"],
        #   post_url: post_object["post_url"],
        #   canonical_url: post_object["canonical_url"],
        #   post_date: post_object["post_date"],
        #   six_second_take: post_object["six_second_take"],
        #   author_id: post_object["author_id"],
        #   author_name: post_object["author_name"],
        #   author_url: post_object["author_url"],
        #   author_image: post_object["author_image"],
        #   category_id: post_object["category_id"],
        #   category_name: post_object["category_name"],
        #   category_link: post_object["category_link"],
        #   sponsored_content: post_object["sponsored_content"],
        #   sponsored_image: post_object["sponsored_image"],
        #   sponsored_url: post_object["sponsored_url"],
        #   video_url: post_object["video_url"],
        #   podcast_url: post_object["podcast_url"],
        #   featured_partner: post_object["featured_partner"],
        #   featured_partner_url: post_object["featured_partner_url"],
        #   featured_part_desc: post_object["featured_part_desc"],
        #   featured_part_img: post_object["featured_part_img"]
        # }
      end

      def get_posts
        response = http_connection.get()
        parse_posts(JSON.parse(response.body))
      end

      def items_in_xml_formate
        items_in_xml_string = []
        get_posts.each do |post|
          items_in_xml_string << 
            "<item>
              <title>#{post[:title]}</title>
              <pubDate>#{Time.now.utc.strftime(TIME_FORMATE)}</pubDate>
              <guid>#{post[:guid]}</guid>
              <content>#{post[:content]}</content>
              <cc>#{post[:author_name]}</cc>
              <media><url>#{post[:author_name]}</url></media>
            </item>"
        end

        items_in_xml_string.join('\n')
      end

  end
end