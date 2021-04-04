module ApplicationHelper
	def remove_html_content
		ActionView::Base.full_sanitizer.sanitize(data)
	end
end
