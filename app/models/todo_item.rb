class TodoItem < ApplicationRecord
  belongs_to :todo_list

  validates :content, presence: true

  before_create :assign_position

  private

  def assign_position
    self.position = (todo_list.todo_items.maximum(:position) || 0) + 1 if position.to_i.zero?
  end
end
