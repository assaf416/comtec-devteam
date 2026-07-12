class CustomerUser < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  belongs_to :customer

  has_many :customer_messages, as: :sender, dependent: :nullify

  validates :name, presence: true

  def display_name
    name.presence || email.split("@").first
  end
end
