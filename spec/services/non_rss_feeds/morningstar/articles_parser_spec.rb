# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::Morningstar::ArticlesParser do
  let(:raw_article) do
    '
      <?xml version="1.0" encoding="UTF-8"?>
      <article source="Morningstar" format="Analyst IndustryGroup Article" id="803884">
        <url>http://news.morningstar.com/doc/article/1,,803884,00.html</url>
        <department>stocks</department>
        <collection id="507">Stock Strategist Industry Reports</collection>
        <keywords>
          <keyword id="3" category="Asset Types">Stocks</keyword>
        </keywords>
          <tickers>
            <ticker exchange="NYSE" name="Nucor Corp" country="USA">NUE</ticker>
          </tickers>
          <author>Andrew Lane</author>
          <author_email>andrew.lane@morningstar.com</author_email>
          <publish_date>2017-04-24 06:00:00-05</publish_date>
          <modified_date />
          <title>Steel Rallies on Trump Memo, but Our Outlook Is Still Negative</title>
          <deck>Protectionist trade policies arent enough</deck>
          <body>
            Share prices for operators across the ...
            <p />
            Given the wide-ranging list of...
            <p />
          </body>
      </article>
    '
  end

  let(:subject) do
    described_class.new( [raw_article] )
  end

  describe '#parse' do
    context 'when response is nil' do
      let(:raw_article) { '' }
      it 'returns an empty array' do
        expect(subject.parse).to be_empty
      end
    end
    context 'when response is one article' do
      let(:result) { subject.parse }
      it 'returns an array' do
        expect(result.count).to eq 1
      end
      it 'parses the id' do
        expect(
          result.first[:id]
        ).to eq("803884")
      end
      it 'parses the title' do
        expect(
          result.first[:title]
        ).to eq("Steel Rallies on Trump Memo, but Our Outlook Is Still Negative")
      end
      it 'parses the author' do
        expect(
          result.first[:author]
        ).to eq("Andrew Lane")
      end
      it 'parses the summary' do
        expect(
          result.first[:summary]
        ).to eq("Protectionist trade policies arent enough")
      end
      it 'parses the published_at' do
        expect(
          result.first[:published_at]
        ).to eq("2017-04-24 06:00:00-05")
      end

      it 'parses the section' do
        expect(
          result.first[:section]
        ).to eq("Stock Strategist Industry Reports")
      end

      it 'parses the content' do
        expect(
          result.first[:content]
        ).to eq(
          "<body>\n            Share prices for operators across the ...\n   " \
          "         <p/>\n            Given the wide-ranging list of...\n    " \
          "        <p/>\n          </body>"
        )
      end
    end
  end
end
