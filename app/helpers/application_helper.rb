module ApplicationHelper
	def remove_html_content(data)
		ActionView::Base.full_sanitizer.sanitize(data)
	end
end
