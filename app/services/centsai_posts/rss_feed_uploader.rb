module CentsaiPosts
  class RssFeedUploader
    def initialize
    end

    def call
      centsai_details = CentsaiPosts::PostsDownloader.new().call
      unless centsai_details[:are_items_present]
        centsai_error_massage = "\n\n---No new articles available for centsai---\n\n"
        return centsai_error_massage
      end
      file_content = centsai_details[:xml_rss_feed]
      file_name = centsai_details[:file_name]
      file_location = "public/centsai/#{file_name}"
      File.open(file_location, 'a+') {|f| f.write(file_content) }

      bucket = S3_BUCKET.objects["centsai/#{file_name}"]
      bucket.write(
        region: 'us-east-1',
        file: file_location,
        acl: :public_read
      )
      uploaded_file = "https://#{ENV['S3_BUCKET']}.s3.ap-south-1.amazonaws.com/centsai/#{file_name}"
      return uploaded_file
      # File.delete(file_location)
    end
  end
end
