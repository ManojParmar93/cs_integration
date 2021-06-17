# frozen_string_literal: true

require 'spec_helper'

describe NonRssFeeds::DowJonesSelect::ArticlesDownloader do
  let(:non_rss_feed) do
    NonRssFeed.destroy_all
    create(
      :non_rss_feed,
      url: 'http://www.one.com',
      miscellaneous: {
        'username' => '1',
        'password' => '2'
      }
    )
  end

  let(:xml_article) do
    File.read('spec/fixtures/factiva_select/article_example.xml')
  end
  let(:subject) do
    described_class.new(non_rss_feed)
  end

  describe '#articles' do
    context 'when single article response is nil' do
      before do
        allow(subject)
          .to receive(:get_single_xml_article)
          .and_return(nil)
        allow(subject)
          .to receive(:feed_files_in_csv)
          .and_return('a123.xml')
      end
      it 'returns an empty array' do
        expect(
          subject.articles
        ).to be_empty
      end
    end
    context 'when article response is nil' do
      before do
        expect(subject).to_not receive(:get_single_xml_article)
        allow(subject)
          .to receive(:feed_files_in_csv)
          .and_return('')
      end
      it 'returns an empty array' do
        expect(
          subject.articles
        ).to be_empty
      end
    end
    context 'when response is xml' do
      it 'finds the article' do
      end
      let(:result) { subject.articles }

      before do
        allow(subject)
          .to receive(:get_single_xml_article)
          .with('a123.xml')
          .and_return(xml_article)
        allow(subject)
          .to receive(:feed_files_in_csv)
          .and_return('a123.xml')
      end

      it 'sets the id' do
        expect(result.first[:id]).to eq 'BON0000020170511ed5b000xd'
      end
      it 'sets the author' do
        expect(result.first[:author]).to eq 'By Cool Author'
      end
      it 'sets the right title' do
        expect(result.first[:title].squish).to eq 'Headline stuff'
      end
      it 'sets the description' do
        expect(
          result.first[:content]
        ).to eq (
          "Will Travelers Buy TripAdvisor's New Ad Campaign?<br> <br>"\
          "Paragraph about trip advisor<br> <br>Another Paragraph<br>"\
          " <br>But there's reason to be skeptical about this paragragh"\
          "\"<br> <br>* Link Description"
        )
      end
      it 'sets the section' do
        expect(result.first[:section]).to eq('Next')
      end
      it 'sets the summary' do
        expect(result.first[:summary]).to eq('This is a great snippet')
      end
    end
  end
end
