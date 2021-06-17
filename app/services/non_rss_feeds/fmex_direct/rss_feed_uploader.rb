module NonRssFeeds
  module FmexDirect
    class RssFeedUploader
      def initialize(options = {})
        @file_name = options[:file_name]
        @url_query = options[:url_query]
      end

      def call
        file_details = NonRssFeeds::FmexDirect::PostsDownloader.new({file_name: @file_name, url_query: @url_query}).call

        unless file_details[:are_items_present]
          fmexdirect_error_massage = "\n\n---No new articles available for Fmex Direct---\n\n"
          return fmexdirect_error_massage
        end


        file_content = file_details[:xml_rss_feed]
        file_name = file_details[:file_name]

        s3 ||= AWS::S3.new(
          access_key_id: S3::Config.config['access_key_id'],
          secret_access_key: S3::Config.config['secret_access_key']
        )

        bucket = s3.buckets[S3::Config.config['bucket_name']]

        object = bucket.objects["fmax_direct/#{file_name}"]

        object.write(
          file_content,
          acl: :public_read,
          content_type: 'text/xml' 
        )

        uploaded_file = "https://#{S3::Config.config['bucket_name']}.s3.#{S3::Config.config['region']}.amazonaws.com/fmax_direct/#{file_name}"

        return uploaded_file
      end
    end
  end
end
