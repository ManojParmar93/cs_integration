class ArticleItem < ApplicationRecord
  enum source: %w[centsai fmex_direct northern_trust]

  scope :centsai, -> { where(source: 0) }
end
