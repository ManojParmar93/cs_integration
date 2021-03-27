# frozen_string_literal: true
module NonRssFeeds
  module DowJones
    # Downloads the Articles
    # and transforms them
    # for the ArticlesToRssFeeder.
    class ArticlesDownloader # rubocop:disable ClassLength
      def initialize(headlines)
        @headlines = headlines
      end

      def articles
        return [] unless @headlines.is_a?(Array)
        @headlines.reduce([]) do |array, headline|
          array + headline_articles(headline)
        end
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        []
      end

      private

      def headline_articles(headline)
        filter_headline_articles_json(
          headline_articles_json(headline)
        ).map do |article_json|
          headline.merge(
            id: headline[:article_ref],
            description: article_description(article_json),
            content: article_content(article_json['Body']),
            copyright: article_copyright(article_json),
            section: article_section(article_json)
          )
        end
      end

      def filter_headline_articles_json(json)
        json.select do |element|
          element.respond_to?(:key?) && element.key?('Body')
        end
      end

      def article_description(article_json)
        article_json['Title'].first['Items'].first['Value'].strip
      rescue StandardError => error
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{error}"
        )
        nil
      end

      def article_content(article_json_body)
        article_json_body.map do |body_object|
          paragraph(body_object)
        end.join.delete("\n").delete("\r")
      end

      def article_copyright(article_json)
        article_json['Copyright']['Items'].first['Value'].strip
      rescue StandardError => error
        ::Rails.logger.warn(
          "#{self.class.name}##{__method__} - WARN! #{error}"
        )
        nil
      end

      def paragraph(body_object)
        [
          '<p>',
          transform_paragraph_objects(
            filter_pragraph_objects(
              body_object['Items']
            )
          ).flatten,
          '</p>'
        ].join
      end

      def filter_pragraph_objects(paragraph_objects)
        paragraph_objects.select do |object|
          %(text elink entityreference).include?(
            object['__type'].downcase
          )
        end
      end

      def article_section(article_json)
        article_json['Section']
      end

      def transform_paragraph_objects(paragraph_objects)
        paragraph_objects.map do |paragraph_object|
          transform_paragraph_object(paragraph_object)
        end
      end

      def transform_paragraph_object(paragraph_object)
        case paragraph_object['__type'].downcase
        when 'text'
          text_object(paragraph_object)
        when 'elink'
          elink_object(paragraph_object)
        when 'entityreference'
          entity_reference_object(paragraph_object)
        end
      end

      def text_object(paragraph_object)
        paragraph_object['Value']
      end

      def entity_reference_object(paragraph_object)
        "<b>#{paragraph_object['Name']}</b>"
      end

      def elink_object(paragraph_object)
        "<a href='#{paragraph_object['Reference']}' " \
        "title='#{paragraph_object['Text']}'>" \
        "#{paragraph_object['Text']}</a>"
      end

      def headline_articles_json(headline)
        JSON.parse(
          download_headline_articles(headline).body
        )['Articles']
      rescue StandardError => error
        ::Rails.logger.error(
          "#{self.class.name}##{__method__} - ERROR! #{error}"
        )
        {}
      end

      def download_headline_articles(headline)
        Faraday.get(
          api_url,
          {
            articleRef: headline[:article_ref],
            encryptedToken: headline[:encrypted_token]
          },
          {}
        )
      end

      def api_url
        'https://api.dowjones.com/api/public/2.0/Content/article/articleRef/json'
      end

      def article_refs
        @article_refs ||= @headlines.map { |hash| hash['article_ref'] }.compact
      end
    end
  end
end
