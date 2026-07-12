class CreateAiChats < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_chat_sessions do |t|
      t.bigint :user_id, null: false
      t.bigint :project_id          # context: the project this chat is about
      t.bigint :sprint_id           # context: the sprint this chat is about
      t.string :title
      t.string :llm_model
      t.timestamps
    end
    add_index :ai_chat_sessions, :user_id
    add_index :ai_chat_sessions, :project_id

    create_table :ai_chat_messages do |t|
      t.references :ai_chat_session, null: false, foreign_key: true
      t.string :role, null: false   # user / assistant
      t.text   :content, null: false
      t.timestamps
    end
  end
end
