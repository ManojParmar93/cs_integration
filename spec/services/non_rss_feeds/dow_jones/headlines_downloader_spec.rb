# frozen_string_literal: true
require 'spec_helper'

describe NonRssFeeds::DowJones::HeadlinesDownloader do
  let(:body) do
    {
      'Headlines' => [
        {
          'ArticleRef' => 'summary:archive/NWSPLS0020160608ec6800a3z',
          'AttributionCode' => 'NWSPLS',
          'ByLine' => {
            'Items' => [
              {
                '__type' => 'Text',
                'Value' => 'By Christina Binkley'
              }
            ]
          },
          'ColumnName' => 'On Style',
          'ContentType' => 'summary',
          'Copyright' => {
            'Items' => [
              {
                '__type' => 'Text',
                'Value' => 'This is a copyright.'
              }
            ]
          },
          'LanguageCode' => 'en',
          'Link' => 'https://www.link.com',
          'Metadata' => {
            'ContentItems' => [
              {
                'Link' => 'https://www.image.com/dispix.jpg',
                'MIMEType' => 'image/jpeg',
                'Reference' => 'probj:archive/DJEORH2016060902188/88/17721',
                'Size' => 17_721,
                'Type' => 'dispix'
              },
              {
                'Link' => 'https://www.image.com/tnail.jpg',
                'MIMEType' => 'image/jpeg',
                'Reference' => 'probj:archive/DJEORH2016060902188/17809/3333',
                'Size' => 3_333,
                'Type' => 'tnail'
              },
              {
                'Link' => 'https://www.image.com/fnail.jpg',
                'MIMEType' => 'image/jpeg',
                'Reference' => 'probj:archive/DJEORH2016060902188/21142/1521',
                'Size' => 1_521,
                'Type' => 'fnail'
              }
            ]
          },
          'ModificationDate' => '2016-06-09',
          'ModificationDateTime' => '/Date(1465511348000)/',
          'ModificationTime' => '22:29:08Z',
          'ModificationTimeSpecified' => true,
          'ParentArticle' => 'WSJO000020160608ec680080z',
          'PublicationDate' => '2016-06-08',
          'PublicationDateTime' => '/Date(1465428720000)/',
          'PublicationTime' => '23:32:00Z',
          'PublicationTimeSpecified' => true,
          'SectionName' => {
            'Items' => [
              {
                '__type' => 'Text',
                'Value' => 'Life'
              }
            ]
          },
          'Snippet' => {
            'Items' => [
              {
                '__type' => 'Text',
                'Value' => 'This is a snippet.'
              }
            ]
          },
          'SourceArticleId' => '1',
          'SourceCode' => 'nwspls',
          'SourceName' => 'NewsPlus',
          'Title' => [
            {
              'Items' => [
                {
                  '__type' => 'Text',
                  'Value' => 'This is a title.'
                }
              ]
            }
          ],
          'TruncationRules' => {
            'ExtraSmall' => 27
          },
          'WordCount' => 32
        }
      ]
    }
  end

  let(:non_rss_feed) do
    NonRssFeed.destroy_all
    create(
      :non_rss_feed,
      url: 'http://www.one.com',
      miscellaneous: {
        'encrypted_token': '1'
      }
    )
  end

  describe '#headlines' do
    context 'when response is nil' do
      before do
        allow(Faraday).to receive(:get).and_return(nil)
      end
      it 'returns an empty array' do
        expect(
          described_class.new(
            non_rss_feed
          ).headlines
        ).to be_empty
      end
    end
    context 'when response is API JSON' do
      let(:result) do
        described_class.new(non_rss_feed).headlines
      end

      before do
        allow(Faraday).to receive(:get).with(
          non_rss_feed.url,
          {
            code: 'NP_Lifestyle_1',
            encryptedToken: non_rss_feed.miscellaneous['encrypted_token']
          },
          {}
        ).and_return(double(body: body.to_json))
      end
      it 'returns the correct number of headlines' do
        expect(
          result.size
        ).to eq 1
      end
      it 'creates the right article_ref' do
        expect(
          result.first[:article_ref]
        ).to eq 'article:archive/' + body['Headlines'].first['ParentArticle']
      end
      it 'creates the right published_at date time' do
        expect(
          result.first[:published_at]
        ).to eq(
          Time.zone.at(
            body['Headlines'].first['PublicationDateTime'].sub(
              '/Date(',
              ''
            ).sub(')/', '').to_i / 1000
          )
        )
      end
      it 'creates the right image_url' do
        expect(
          result.first[:image_url]
        ).to eq(
          body['Headlines'].first['Metadata']['ContentItems'].first['Link']
        )
      end
      it 'creates the right image_size' do
        expect(
          result.first[:image_size]
        ).to eq(
          body['Headlines'].first['Metadata']['ContentItems'].first['Size']
        )
      end
      it 'creates the right image_type' do
        expect(
          result.first[:image_type]
        ).to eq(
          body['Headlines'].first['Metadata']['ContentItems'].first['MIMEType']
        )
      end
      it 'creates the right author' do
        expect(
          result.first[:author]
        ).to eq(
          body['Headlines'].first[
            'ByLine'
          ]['Items'].first['Value'].sub('By ', '')
        )
      end
      it 'creates the right title' do
        expect(
          result.first[:title]
        ).to eq(
          body['Headlines'].first[
            'Title'
          ].first['Items'].first['Value']
        )
      end
      it 'creates the right summary' do
        expect(
          result.first[:summary]
        ).to eq(
          body['Headlines'].first[
            'Snippet'
          ]['Items'].first['Value']
        )
      end
      it 'adds the encrypted token' do
        expect(
          result.first[:encrypted_token]
        ).to eq(
          non_rss_feed.miscellaneous['encrypted_token']
        )
      end
      context 'when headline has no by line' do
        let(:body1) do
          headline = body['Headlines'].first
          headline.delete('ByLine')
          body['Headlines'] = [headline]
          body
        end

        before do
          allow(Faraday).to receive(:get).with(
            non_rss_feed.url,
            {
              code: 'NP_Lifestyle_1',
              encryptedToken: non_rss_feed.miscellaneous['encrypted_token']
            },
            {}
          ).and_return(double(body: body1.to_json))
        end
        it 'returns the correct number of headlines' do
          expect(
            result.size
          ).to eq 1
        end
        it 'creates the right author' do
          expect(
            result.first[:author]
          ).to eq(
            nil
          )
        end
      end
    end
  end
end
