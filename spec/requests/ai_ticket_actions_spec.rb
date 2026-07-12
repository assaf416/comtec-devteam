require 'rails_helper'

# The "Fix that bug" and "Generate tasks & estimations" AI buttons on the ticket
# page. The local LLM (Ollama) is stubbed so these run offline.
RSpec.describe "AI ticket actions", type: :request do
  let(:user)    { create(:user, role: :admin) }
  let(:project) { create(:project) }
  let(:bug)     { create(:ticket, project: project, kind: :bug_fix, title: "Crash on save") }
  let(:story)   { create(:ticket, project: project, kind: :story, title: "Checkout flow") }

  before { sign_in user }

  describe "POST /tools/ai/fix_bug" do
    it "runs the bug-fix service and stores a review" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_return("VERDICT: pass\nSCORE: 80\nRoot cause: nil guard missing.")

      expect {
        post tools_ai_fix_bug_path(ticket_id: bug.id)
      }.to change { bug.ai_reviews.where(kind: :bug_fix).count }.by(1)

      review = bug.ai_reviews.last
      expect(response).to redirect_to(tools_ai_review_path(review))
    end
  end

  describe "POST /tools/ai/generate_tasks" do
    it "breaks the story into Task records from the AI output" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat).and_return(<<~OUT)
        Here is the breakdown.
        TASKS:
        - [4h] Build the cart model
        - [2h] Add the checkout endpoint
        - [3h] Write request specs
      OUT

      # Story already auto-created one task on creation; AI adds three more.
      expect {
        post tools_ai_generate_tasks_path(ticket_id: story.id)
      }.to change { story.tasks.count }.by(3)

      expect(story.tasks.pluck(:description)).to include("Build the cart model")
      expect(story.tasks.find_by(description: "Build the cart model").estimation).to eq("4h")
      expect(response).to redirect_to(ticket_path(story, anchor: "tasks"))
    end

    it "reports gracefully when the model returns no parseable tasks" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat).and_return("No tasks here, sorry.")
      post tools_ai_generate_tasks_path(ticket_id: story.id)
      expect(flash[:notice]).to match(/no parseable tasks/i)
    end
  end
end
