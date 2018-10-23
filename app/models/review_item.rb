# frozen_string_literal: true

class ReviewItem < ApplicationRecord
  include Websocket

  belongs_to :user
  belongs_to :queue, class_name: 'ReviewQueue', foreign_key: 'review_queue_id'
  belongs_to :reviewable, polymorphic: true
  has_many :results, class_name: 'ReviewResult'

  generate_direct_associations :post, :spam_domain, :flag

  validates :reviewable_type, inclusion: { in: %w[Post SpamDomain Flag] }

  scope(:active, -> { where(completed: false) })
  scope(:completed, -> { where(completed: true) })

  def self.unreviewed_by(queue, user)
    joins("LEFT JOIN review_results rr ON rr.review_item_id = review_items.id AND rr.user_id = #{user.id}").where(review_items: { queue: queue,
                                                                                                                                  completed: false },
                                                                                                                  rr: { id: nil })
  end

  private

  def generate_direct_associations(*types)
    types.each do |t|
      belongs_to(t, -> { where(reviewable_type: t.classify) }, foreign_key: 'reviewable_id')

      define_method t do
        return unless reviewable_type == t.classify
        super
      end
    end
  end
end
