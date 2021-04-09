class ArticleItem < ApplicationRecord
  enum source: %w[centsai fmex_direct northern_trust]

  scope :centsai, -> { where(source: 0) }
  scope :fmex_direct, -> { where(source: 1) }
  scope :northern_trust, -> { where(source: 2) }
end
