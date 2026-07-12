class Installation < ApplicationRecord
  belongs_to :customer
  belongs_to :project,    optional: true
  belongs_to :deployment, optional: true

  enum :status, {
    active:         0,
    pending:        1,
    outdated:       2,
    decommissioned: 3,
    failed:         4
  }, prefix: true

  ENVIRONMENTS = %w[production staging uat development].freeze

  validates :software_name, presence: true
  validates :version,       presence: true
  validates :environment,   presence: true, inclusion: { in: ENVIRONMENTS }

  scope :active,    -> { where(status: :active) }
  scope :outdated,  -> { where(status: :outdated) }
  scope :for_env,   ->(env) { where(environment: env) }

  # Mark previous active installations of the same software as outdated when a
  # newer one is added.
  after_create :mark_previous_as_outdated, if: -> { status_active? }

  def latest_for_customer?
    Installation.where(customer: customer, software_name: software_name)
                .order(installed_at: :desc)
                .first&.id == id
  end

  private

  def mark_previous_as_outdated
    Installation.where(customer: customer, software_name: software_name, status: :active)
                .where.not(id: id)
                .update_all(status: :outdated)
  end
end
