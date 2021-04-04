module NorthernTrust
  class RssFeedUploader
    def initialize
    end

    def call
      file_details = NorthernTrust::PostsDownloader.new().call

      unless file_details[:are_items_present]
        northerntrust_error_massage = "\n\n---No new articles available for Northern Trust---\n\n"
        return northerntrust_error_massage
      end


      file_content = file_details[:xml_rss_feed]
      file_name = file_details[:file_name]
      file_location = "public/northerntrust/#{file_name}"
      file_location = Rails.env.test? ? "spec/test_files/northerntrust/northern_trust_test.rss" : "public/northerntrust/#{file_name}"

      File.open(file_location, 'a+') {|f| f.write(file_content) }

      bucket = S3_BUCKET.objects["northerntrust/#{file_name}"]

      bucket.write(
        file: file_location,
        acl: :public_read
      )

      File.delete(file_location)
      uploaded_file = "https://#{ENV['S3_BUCKET']}.s3.ap-south-1.amazonaws.com/northerntrust/#{file_name}"
      return uploaded_file
    end
  end
end
