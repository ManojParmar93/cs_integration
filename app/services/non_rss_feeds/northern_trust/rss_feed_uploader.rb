module NonRssFeeds
  module NorthernTrust
    class RssFeedUploader
      def initialize(options = {})
        @file_name = options[:file_name]
      end

      def call
        file_details = NonRssFeeds::NorthernTrust::PostsDownloader.new({file_name: @file_name}).call

        unless file_details[:are_items_present]
          northerntrust_error_massage = "\n\n---No new articles available for Northern Trust---\n\n"
          return northerntrust_error_massage
        end


        file_content = file_details[:xml_rss_feed]
        file_name = file_details[:file_name]
        file_location = "public/northerntrust/#{file_name}"
        File.open(file_location, 'a+') {|f| f.write(file_content) }

        bucket = S3_BUCKET.objects["northerntrust/#{file_name}"]

        bucket.write(
          file: file_location,
          acl: :public_read
        )

        File.delete(file_location)
        uploaded_file = "https://#{ENV['S3_BUCKET']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/northerntrust/#{file_name}"
        return uploaded_file
      end
    end
  end
end
