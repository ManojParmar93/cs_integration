class ArticleItem < BaseDocument
  #int source: %w[centsai fmex_direct northern_trust]

  include Mongoid::Document
  include Mongoid::Timestamps

  CENTSAI_ITEM = 0
  FMEX_ITEM = 1
  NORTHERN_TRUST_ITEM = 2

  field :source, type: Integer, default: CENTSAI_ITEM
  field :guid,   type: String

  scope :centsai, -> { where(source: CENTSAI_ITEM) }
  scope :fmex_direct, -> { where(source: FMEX_ITEM) }
  scope :northern_trust, -> { where(source: NORTHERN_TRUST_ITEM) }
end
