module NonRssFeeds
  module DowJonesSelect
    class ParaEntry
      include SAXMachine
      include Feedjira::FeedEntryUtilities
      elements :Para, as: :paragraphs
    end

    class FeedParser
      include SAXMachine
      include Feedjira::FeedEntryUtilities

      element :Title, as: :title
      element :ArchiveDoc, as: :description
      elements :ArchiveDoc, as: :archive_doc, class: ParaEntry
      element :Date, value: :value, as: :published
      element :SrcName, as: :source
      element :Logo, value: :img, as: :logo_img
      element :Logo, value: :src, as: :logo_src
      element :Logo, value: :link, as: :logo_link
      element :SectionName, as: :section
      element :ColumnName, as: :column_name
      element :FolderName, as: :folder
      element :AccessionNo, value: :value, as: :article_id
      element :Byline, as: :author
      element :Copyright, as: :copyright
      element :Snippet, as: :summary
      elements :Snippet, as: :summary_paragraphs, class: ParaEntry
    end
  end
end
