module NonRssFeeds
  module CentsaiPosts
    class RssFeedUploader
      def initialize(options = {})
        @file_name = options[:file_name]
        @url_query = options[:url_query]
      end

      def call
        centsai_details = NonRssFeeds::CentsaiPosts::PostsDownloader.new({}, {file_name: @file_name, url_query: @url_query}).call

        unless centsai_details[:are_items_present]
          centsai_error_massage = "\n\n---No new articles available for centsai---\n\n"
          return centsai_error_massage
        end
        file_content = centsai_details[:xml_rss_feed]
        file_name = centsai_details[:file_name]

        s3 ||= AWS::S3.new(
          access_key_id: S3::Config.config['access_key_id'],
          secret_access_key: S3::Config.config['secret_access_key']
        )

        bucket = s3.buckets[S3::Config.config['bucket_name']]

        object = bucket.objects["centsai/#{file_name}"]      

        object.write(
          file_content,
          acl: :public_read,
          content_type: 'text/xml' 
        )

        #"https://s3.amazonaws.com/#{S3::Config.config['bucket_name']}/centsai/#{file_name}"
        uploaded_file = "https://#{S3::Config.config['bucket_name']}.s3.#{S3::Config.config['region']}.amazonaws.com/centsai/#{file_name}"
        return uploaded_file
      end
    end
  end
end
