class Customer < ApplicationRecord
  has_many :customer_tickets, dependent: :destroy
  has_many :installations, dependent: :destroy
  has_many :customer_users, dependent: :destroy
  has_many :customer_messages, dependent: :destroy

  validates :name,  presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def display_name
    company.present? ? "#{name} (#{company})" : name
  end

  def installed_projects
    installations.includes(:project).map(&:project).compact.uniq
  end
end
