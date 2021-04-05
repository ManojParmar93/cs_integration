module FmexDirect
  class RssFeedUploader
    def initialize
    end

    def call
      file_details = FmexDirect::PostsDownloader.new().call
      file_content = file_details[:xml_rss_feed]
      file_name = file_details[:file_name]
      file_location = "public/fmax_direct/#{file_name}"
      File.open(file_location, 'a+') {|f| f.write(file_content) }

      bucket = S3_BUCKET.objects["fmax_direct/#{file_name}"]

      bucket.write(
        file: file_location,
        acl: :public_read
      )

      puts "https://#{ENV['S3_BUCKET']}.s3.ap-south-1.amazonaws.com/fmax_direct/#{file_name}"
      File.delete(file_location)
    end
  end
end
