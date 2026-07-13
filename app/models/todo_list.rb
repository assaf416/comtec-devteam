# A personal to-do list owned by a user, holding ordered items.
class TodoList < ApplicationRecord
  belongs_to :user
  has_many :todo_items, -> { order(:position, :id) }, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def progress
    total = todo_items.size
    done  = todo_items.count(&:done?)
    { total: total, done: done, percent: total.zero? ? 0 : (done * 100.0 / total).round }
  end
end
