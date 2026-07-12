class Comment < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  belongs_to :commentable, polymorphic: true

  enum :kind, { note: 0, red_card: 1, green_card: 2 }, prefix: true

  validates :body, presence: true

  KIND_META = {
    "note"       => { label: "Note",       icon: "💬", border: "#d7d0c2", bg: "transparent" },
    "red_card"   => { label: "Red card",   icon: "🚩", border: "#b63a34", bg: "rgba(182,58,52,.06)" },
    "green_card" => { label: "Green card", icon: "🟢", border: "#1a7a3a", bg: "rgba(26,122,58,.06)" }
  }.freeze

  def kind_meta
    KIND_META.fetch(kind, KIND_META["note"])
  end
end
