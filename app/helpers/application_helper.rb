module ApplicationHelper
	def remove_html_content(data)
		sanitizer_obj = Rails::Html::SafeListSanitizer.new
		sanitizer_obj.sanitize(data, tags: %w(b br ul li p))
	end
end
