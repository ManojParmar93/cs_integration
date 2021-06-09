module FmexDirect
  class RssFeedUploader
    def initialize
    end

    def call
      file_details = FmexDirect::PostsDownloader.new().call

      unless file_details[:are_items_present]
        fmexdirect_error_massage = "\n\n---No new articles available for Fmex Direct---\n\n"
        return fmexdirect_error_massage
      end


      file_content = file_details[:xml_rss_feed]
      file_name = file_details[:file_name]
      file_location = "public/fmax_direct/#{file_name}"
      File.open(file_location, 'a+') {|f| f.write(file_content) }

      bucket = S3_BUCKET.objects["fmax_direct/#{file_name}"]

      bucket.write(
        file: file_location,
        acl: :public_read
      )

      File.delete(file_location)
      uploaded_file = "https://#{ENV['S3_BUCKET']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/fmax_direct/#{file_name}"
      return uploaded_file
    end
  end
end
