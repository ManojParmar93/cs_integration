# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::DowJones::ArticlesDownloader do
  let(:body) do
    {
      Articles: [
        {
          ArticleRef: 'article:archive/ArticleRef',
          Body: [
            {
              Items: [
                {
                  Value: '1 2 ',
                  __type: 'Text'
                }
              ]
            },
            {
              Items: [
                {
                  Reference: 'http://www.blah.com',
                  Text: '3 4.',
                  __type: 'ELink'
                },
                {
                  Name: '5 6 7 ',
                  __type: 'EntityReference'
                }
              ]
            }
          ],
          Copyright: {
            Items: [
              {
                Value: 'This is a copyright.',
                __type: 'Text'
              }
            ]
          },
          Section: 'Business',
          Title: [
            {
              Items: [
                {
                  Value: 'This is a actually a long description.',
                  __type: 'Text'
                }
              ]
            }
          ]
        }
      ]
    }
  end
  let(:headlines) do
    [
      {
        article_ref: body[:Articles].first[:ArticleRef],
        title: 'This is a title.',
        author: 'Mr. News',
        summary: 'This is a summary.',
        published_at: Time.zone.at(0),
        image_url: 'http://www.image.com/image.png',
        encrypted_token: '1'
      }
    ]
  end
  let(:subject) do
    described_class.new(headlines)
  end

  describe '#articles' do
    context 'when response is nil' do
      before do
        allow(Faraday).to receive(:get).and_return(nil)
      end
      it 'returns an empty array' do
        expect(
          subject.articles
        ).to be_empty
      end
    end
    context 'when response is API JSON' do
      let(:result) { subject.articles }

      before do
        allow(Faraday).to receive(:get).with(
          subject.send(:api_url),
          {
            articleRef: headlines.first[:article_ref],
            encryptedToken: headlines.first[:encrypted_token]
          },
          {}
        ).and_return(double(body: body.to_json))
      end

      it 'sets the id' do
        expect(
          result.first[:id]
        ).to eq body[:Articles].first[:ArticleRef]
      end
      it 'sets the description' do
        expect(
          result.first[:description]
        ).to eq body[:Articles].first[:Title].first[:Items].first[:Value]
      end
      it 'sets the content' do
        expect(
          result.first[:content]
        ).to eq(
          '<p>1 2 </p><p><a href=\'http://www.blah.com\' ' \
          'title=\'3 4.\'>3 4.</a><b>5 6 7 </b></p>'
        )
      end
      it 'sets the copyright' do
        expect(
          result.first[:copyright]
        ).to eq(
          body[:Articles].first[:Copyright][:Items].first[:Value]
        )
      end
      it 'sets the correct section' do
        expect(
          result.first[:section]
        ).to eq(
          body[:Articles].first[:Section]
        )
      end
      context 'when more then one headlines are passed' do
        let(:subject) do
          described_class.new(headlines + headlines)
        end
        let(:result) { subject.articles }

        it 'returns the correct number of articles' do
          expect(
            result.size
          ).to eq((headlines + headlines).size)
        end
      end
    end
  end
end
