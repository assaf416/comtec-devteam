class CreateAiReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_reviews do |t|
      # Polymorphic subject — a Ticket, Sprint, Project, etc. (optional for ad-hoc runs)
      t.references :reviewable, polymorphic: true, null: true
      # The user who triggered the run (optional — may be system/CI initiated)
      t.bigint :user_id

      t.integer :kind,   null: false, default: 0   # which AI service produced this
      t.integer :status, null: false, default: 0   # pending / running / completed / failed

      t.string  :llm_model                            # e.g. "llama3.1:8b"
      t.string  :verdict                             # short machine verdict: pass / needs_work / fail
      t.integer :score                               # optional 0–100 quality/confidence score
      t.text    :summary                             # one-line / short summary
      t.text    :body                                # full markdown response from the model
      t.text    :prompt                              # the prompt that was sent (for audit/debug)
      t.integer :duration_ms                         # round-trip time to the LLM
      t.text    :error_message                       # populated when status = failed

      t.timestamps
    end

    add_index :ai_reviews, :kind
    add_index :ai_reviews, :status
    add_index :ai_reviews, :user_id
    add_index :ai_reviews, :created_at
  end
end
