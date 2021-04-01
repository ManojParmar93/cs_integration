require 'json'
require 'net/http'

module NorthernTrust
  class PostsDownloader
    NORTHERNTRUST_POSTS_URI = "https://www.northerntrust.com/api/gridSearch?&query=*&filterString=%5b%7B%22name%22%3A%22publications%22%2C%22values%22%3A%5B%22*%22%5D%7D%5d&region=united-states&start=1&pageSize=9"

    def initialize
      articles = get_posts['results']
      @articles = articles.collect{|article| HashWithIndifferentAccess.new(article)}
      @channel_data = {}
    end

    def xml_rss_feed
      return unless @articles.is_a?(Array)
      make_feed
    # rescue StandardError => error
    #   ::Rails.logger.error(
    #     "#{self.class.name}##{__method__} - ERROR! #{error}"
    #   )
    #   nil
    end

    def http_connection
      Faraday.new(url: NORTHERNTRUST_POSTS_URI)
    end

    def make_feed
        xml = Builder::XmlMarkup.new
        xml.instruct!(:xml, version: '1.0', encoding: 'UTF-8')
        xml.rss(
          version: 2.0,
          'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
          'xmlns:media' => 'http://search.yahoo.com/mrss/'
        ) do |_|
          xml.channel do |channel|
            make_channel(channel)
          end
        end
      end

    private

      # updated code 31 March

      def make_feed # rubocop:disable MethodLength
        xml = Builder::XmlMarkup.new
        xml.instruct!(:xml, version: '1.0', encoding: 'UTF-8')
        xml.rss(
          version: 2.0,
          'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
          'xmlns:media' => 'http://search.yahoo.com/mrss/'
        ) do |_|
          xml.channel do |channel|
            make_channel(channel)
          end
        end
      end

      def make_channel(channel)
        channel.title @channel_data[:title]
        channel.link @channel_data[:link]
        channel.description @channel_data[:description]
        channel.pubDate DateTime.now.utc.to_formatted_s(:rfc822) rescue ""
        make_items(channel)
      end

      def make_items(channel)
        @articles.each do |article|
          channel.item do |item|
            make_item(item, article)
          end
        end
      end

      def make_item(item, article) # rubocop:disable MethodLength, AbcSize
        item.guid "#{article[:url]}#{[:articleDate]}"
        item.title article[:title]
        item.pubDate Time.zone.parse(
          article[:published_at].to_s
        ).to_formatted_s(:rfc822) rescue ""
        item.linke "https://www.northerntrust.com​#{article[:url]}"
        item.description article[:articleDescription]
        # http://www.lowter.com/blogs/2008/2/9/rss-dccreator-author
        item.dc(:creator) do |dc|
          dc.text! article[:author_name]
        end if article[:author_name].present?
        item.description article[:post_content]
        # Note that RSS 2.0 spec
        # does not validate with HTTPS.
        # These URLs are HTTPS from
        # the Dow Jones API.
        # https://github.com/rubys/feedvalidator/issues/16
        # This is why enclosure was not used.
        # FeedJira will pick this up.
        item.media(
          :content,
          url: article[:post_url],
          fileSize: article[:image_size],
          type: article[:image_type]
        ) do |media_content|
          media_content.media(
            :credit,
            role: 'photographer',
            scheme: 'urn:ebu'
          ) do |media_credit|
            media_credit.text! article[:image_credit]
          end if article[:image_credit].present?
        end if article[:image_url].present?
        # https://developer.mozilla.org/en-US/docs/Web/RSS/
        # Article/Why_RSS_Content_Module_is_Popular_-_Including_HTML_Contents
        item.content(:encoded) do |content|
          content.cdata!(article[:summary])
        end
      end

      def get_posts
        # response = http_connection.get()
        # JSON.parse(response.body)

        {"count":869,"results":[{"title":"The Bottom Line","summary":"Take a closer look at market activity in this weekly recap with Wealth Management Chief Investment Officer Katie Nixon.","url":"/insights-research/editorial-articles/wealth-management/bottom-line","articleContentType":"","articleDate":"","articlePdfUrl":"","articleImageUrl":"","articleAltText":"","onlineDate":"","offlineDate":"","publicationType":"","newItem":"","linkText":"","renderType":"","articleCaption":"","experts":nil,"articleDescription":"Take a closer look at market activity in this weekly recap with Wealth Management Chief Investment Officer Katie Nixon.","articleURL":"/insights-research/editorial-articles/wealth-management/bottom-line","articleTitle":"The Bottom Line"},{"title":"Steve David: Celebrating a New Career Milestone","summary":"Steve David reflects on his career journey after assuming the role of Chief Executive Officer of Northern Trust’s Luxembourg-headquartered bank, Northern Trust Global Services SE earlier this year. This is in addition to his responsibilities as Country Head of Northern Trust’s Luxembourg Global Fund Services Business.","url":"/insights-research/2021/cis/steve-david-new-career-milestone","articleContentType":"article","articleDate":"2021-03-31 09:00","articlePdfUrl":"","articleImageUrl":"","articleAltText":"","onlineDate":"","offlineDate":"","publicationType":"","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/cis.page","articleCaption":"","experts":nil,"articleDescription":"Steve David reflects on his career journey after assuming the role of Chief Executive Officer of Northern Trust’s Luxembourg-headquartered bank, Northern Trust Global Services SE earlier this year. This is in addition to his responsibilities as Country Head of Northern Trust’s Luxembourg Global Fund Services Business.","articleURL":"/insights-research/2021/cis/steve-david-new-career-milestone","articleTitle":"Steve David: Celebrating a New Career Milestone"},{"title":"Deciphering the Surge in Value Stocks","summary":"Value stocks in the U.S. have had a strong run in the past few months, led by lower quality companies. However, higher quality has started to outperform, creating an opportunity for investors. Head of Quantitative Strategies Michael Hunstad, Ph.D., explores the issue.","url":"/insights-research/2021/marketscape/deciphering-surge-value-stocks","articleContentType":"video","articleDate":"2021-03-29 10:00","articlePdfUrl":"","articleImageUrl":"/cdn/public/pws/nt/images/bios/hunstad_mike_851x478.jpg","articleAltText":"Michael Hunstad","onlineDate":"","offlineDate":"","publicationType":"MarketScape","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/marketscape.page","articleCaption":"","experts":nil,"articleDescription":"Value stocks in the U.S. have had a strong run in the past few months, led by lower quality companies. However, higher quality has started to outperform, creating an opportunity for investors. Head of Quantitative Strategies Michael Hunstad, Ph.D., explores the issue.","articleURL":"/insights-research/2021/marketscape/deciphering-surge-value-stocks","articleTitle":"Deciphering the Surge in Value Stocks"},{"title":"Productivity: The Story Behind the Numbers","summary":"The importance of data-driven decisions to drive large-scale productivity","url":"/insights-research/2021/cis/productivity-story-behind-the-numbers","articleContentType":"article","articleDate":"2021-03-29 09:00","articlePdfUrl":"","articleImageUrl":"","articleAltText":"","onlineDate":"","offlineDate":"","publicationType":"","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/cis.page","articleCaption":"","experts":nil,"articleDescription":"The importance of data-driven decisions to drive large-scale productivity","articleURL":"/insights-research/2021/cis/productivity-story-behind-the-numbers","articleTitle":"Productivity: The Story Behind the Numbers"},{"title":"Economic Commentary on Inflation: Base Effects, Supply Chain Disruptions and Aging Populations","summary":"Addressing technical, idiosyncratic and structural aspects of inflation.","url":"/insights-research/2021/weekly-economic-commentary/march-26","articleContentType":"article","articleDate":"2021-03-26 10:00","articlePdfUrl":"","articleImageUrl":"/cdn/public/pws/nt/images/insights-and-research/commentaries/wec-032621-image.jpg","articleAltText":"Shipping Containers","onlineDate":"","offlineDate":"","publicationType":"Weekly Economic Commentary","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/wec.page","articleCaption":"","experts":nil,"articleDescription":"Addressing technical, idiosyncratic and structural aspects of inflation.","articleURL":"/insights-research/2021/weekly-economic-commentary/march-26","articleTitle":"Economic Commentary on Inflation: Base Effects, Supply Chain Disruptions and Aging Populations"},{"title":"Embracing the Transformational Power of Outsourcing","summary":"How Asset Management in Asia Pacific is Driving Change Across the Whole Office.","url":"/insights-research/2021/cis/transformational-power-outsourcing","articleContentType":"article","articleDate":"2021-03-26 09:00","articlePdfUrl":"","articleImageUrl":"","articleAltText":"","onlineDate":"","offlineDate":"","publicationType":"","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/cis.page","articleCaption":"","experts":nil,"articleDescription":"How Asset Management in Asia Pacific is Driving Change Across the Whole Office.","articleURL":"/insights-research/2021/cis/transformational-power-outsourcing","articleTitle":"Embracing the Transformational Power of Outsourcing"},{"title":"Northern Trust Front Office Solutions Adds to Momentum with Key New Hires","summary":"Business supporting complex asset owners adds new roles as demand for its leading-edge capabilities continues to grow","url":"/pr/2021/front-office-solutions-key-new-hires","articleContentType":"article","articleDate":"2021-03-24 08:00","articlePdfUrl":"","articleImageUrl":"","articleAltText":"","onlineDate":"20210324080000","offlineDate":"","publicationType":"","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/pr/default-press-release.page","articleCaption":"","experts":nil,"articleDescription":"Business supporting complex asset owners adds new roles as demand for its leading-edge capabilities continues to grow","articleURL":"/pr/2021/front-office-solutions-key-new-hires","articleTitle":"Northern Trust Front Office Solutions Adds to Momentum with Key New Hires"},{"title":"Investment Strategy Brief: European Resilience","summary":"European equities are outperforming even as the region struggles with managing the pandemic, and we expect outperformance to continue. Learn why.","url":"/insights-research/2021/investment-management/uk-resilience","articleContentType":"article","articleDate":"2021-03-23 10:00","articlePdfUrl":"","articleImageUrl":"/cdn/public/pws/nt/images/insights-and-research/investment-management/sea-splashing-1200x675.jpg","articleAltText":"Sea splashing","onlineDate":"","offlineDate":"","publicationType":"Investment Strategy Commentary","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/investor-relations-article.page","articleCaption":"","experts":nil,"articleDescription":"European equities are outperforming even as the region struggles with managing the pandemic, and we expect outperformance to continue. Learn why.","articleURL":"/insights-research/2021/investment-management/uk-resilience","articleTitle":"Investment Strategy Brief: European Resilience"},{"title":"Fed Decision Creates Treasury Market Uncertainty","summary":"Investors could face renewed volatility after the Federal Reserve said it won’t renew a pandemic-related relief initiative for U.S. banks. How will this impact the financial system and the $21 trillion Treasury market? Our director of short duration fixed income, Peter Yi, explains.","url":"/insights-research/2021/marketscape/fed-decision-treasury-market-uncertainty","articleContentType":"video","articleDate":"2021-03-22 10:00","articlePdfUrl":"","articleImageUrl":"/cdn/public/pws/nt/images/bios/yi_peter_851x478.jpg","articleAltText":"Peter Yi","onlineDate":"","offlineDate":"","publicationType":"MarketScape","newItem":"","linkText":"","renderType":"/sites/pws/nt/data/templates/articles/marketscape.page","articleCaption":"","experts":nil,"articleDescription":"Investors could face renewed volatility after the Federal Reserve said it won’t renew a pandemic-related relief initiative for U.S. banks. How will this impact the financial system and the $21 trillion Treasury market? Our director of short duration fixed income, Peter Yi, explains.","articleURL":"/insights-research/2021/marketscape/fed-decision-treasury-market-uncertainty","articleTitle":"Fed Decision Creates Treasury Market Uncertainty"}],"facets":[],"warnings":[]}.stringify_keys
      end
  end
end