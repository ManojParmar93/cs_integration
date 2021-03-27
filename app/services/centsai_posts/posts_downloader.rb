require 'json'
require 'net/http'

module CentsaiPosts
  class PostsDownloader
    CENTSAI_POSTS_URI = 'https://centsai.com/api/centsai-api.php'

    def initilize
    end

    def call
      response = http_connection.get()
      records = parse_posts(JSON.parse(response.body))
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
        {GUID: post_object["post_id"],
        Title: post_object["post_title"],
        content: post_object["post_content"],
        Dc: post_object["author_name"],
        Media: {url: post_object["post_image"]}}
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
  end
end