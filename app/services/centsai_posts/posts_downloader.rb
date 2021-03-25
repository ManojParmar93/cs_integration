require 'json'
require 'net/http'

module CentsaiPosts
  class PostsDownloader
    CENTSAI_POSTS_URI = URI('https://centsai.com/api/centsai-api.php')

    def initilize
    end

    def call 
      request = Net::HTTP::Get.new(CENTSAI_POSTS_URI)
      http = Net::HTTP.new(request.uri.host, request.uri.port)
      http.use_ssl = true
      request.basic_auth(ENV['CENTSAI_USERNAME'], ENV['CENTSAI_PASSWORD'])
      response = http.start {|http| http.request(request)}

      JSON.parse(response.body)
    end
  end
end