module CentsaiPosts
  class RssFeedUploader
    def initialize
    end

    def call
      file_content = CentsaiPosts::PostsDownloader.new().xml_rss_feed
      file_name = "post_#{Time.now.to_i}.rss"
      file_location = "public/centsai/#{file_name}"
      File.open(file_location, 'a+') {|f| f.write(file_content) }

      bucket = S3_BUCKET.objects["centsai/#{file_name}"]
      bucket.write(
        file: file_location,
        acl: :public_read
      )
      puts "https://#{ENV['S3_BUCKET']}.s3.ap-south-1.amazonaws.com/centsai/#{file_name}"
      File.delete(file_location)
    end
  end
end
