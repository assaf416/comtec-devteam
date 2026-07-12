require 'rails_helper'

RSpec.describe "CodeReviews", type: :request do
  let(:user) { create(:user, role: :admin) }
  before { sign_in user }

  let(:pr_url) { "http://gitea.local/devteam/print-server/pulls/42" }

  let(:pr_meta) do
    {
      "title" => "Add print spooler retry",
      "state" => "open",
      "user"  => { "login" => "dana" },
      "head"  => { "ref" => "feature/T-1-retry", "sha" => "abc123" },
      "base"  => { "ref" => "main" }
    }
  end

  # Stub all outbound Gitea calls so the suite stays offline.
  before do
    allow_any_instance_of(GiteaService).to receive(:pull_request).and_return(pr_meta)
    allow_any_instance_of(GiteaService).to receive(:pull_request_file_details).and_return(
      [ { "filename" => "app/spooler.rb", "status" => "modified", "additions" => 12, "deletions" => 3 } ]
    )
    allow_any_instance_of(GiteaService).to receive(:pull_request_diff).and_return(
      "diff --git a/app/spooler.rb b/app/spooler.rb\n+  retry_with_backoff\n-  raise\n   context line\n"
    )
    allow_any_instance_of(GiteaService).to receive(:pull_request_comments).and_return(
      [ { "user" => "omri", "message" => "LGTM", "created_at" => "2026-06-05T10:00:00Z" } ]
    )
    allow_any_instance_of(GiteaService).to receive(:commit_statuses).and_return(
      [ { "context" => "ci/jenkins", "state" => "success", "description" => "build ok" } ]
    )
  end

  describe "GET /code_reviews/new" do
    it "renders the URL form" do
      get new_code_review_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pull request URL")
    end
  end

  describe "POST /code_reviews" do
    it "creates a review from a valid PR URL and pulls metadata" do
      expect {
        post code_reviews_path, params: { pr_url: pr_url }
      }.to change(CodeReview, :count).by(1)

      cr = CodeReview.last
      expect(cr.repo_owner).to eq("devteam")
      expect(cr.pr_number).to eq(42)
      expect(cr.title).to eq("Add print spooler retry")
      expect(cr.author).to eq("dana")
      expect(response).to redirect_to(code_review_path(cr))
    end

    it "rejects an unparseable URL" do
      expect {
        post code_reviews_path, params: { pr_url: "http://gitea.local/devteam/print-server" }
      }.not_to change(CodeReview, :count)
      expect(response).to redirect_to(new_code_review_path)
    end
  end

  describe "GET /code_reviews/:id" do
    let(:code_review) do
      CodeReview.create!(pr_url: pr_url, repo_owner: "devteam", repo_name: "print-server",
                         pr_number: 42, title: "Add print spooler retry",
                         head_branch: "feature/T-1-retry", base_branch: "main", reviewer: user)
    end

    it "shows files, diff, test results and the comment form" do
      get code_review_path(code_review)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("app/spooler.rb")            # files changed
      expect(response.body).to include("diff-add")                  # highlighted diff line
      expect(response.body).to include("ci/jenkins")                # gitea commit status
      expect(response.body).to include("LGTM")                      # gitea comment
      expect(response.body).to include("Add comment")               # comment form
      expect(response.body).to include("Run AI review")             # AI integration
    end

    it "surfaces in-app CI test results for the PR branch" do
      project = create(:project, repo_url: "http://gitea.local/devteam/print-server")
      code_review.update!(project: project)
      run = create(:ci_run, project: project, branch_name: "feature/T-1-retry", status: :passed)
      create(:test_result, ci_run: run, suite_name: "RSpec", passed: 40, failed: 1)

      get code_review_path(code_review)
      expect(response.body).to include("RSpec")
      expect(response.body).to include("40")
    end
  end

  describe "PATCH /code_reviews/:id (decision)" do
    let(:code_review) { CodeReview.create!(pr_url: pr_url, pr_number: 42, reviewer: user) }

    it "records the review decision and summary" do
      patch code_review_path(code_review), params: {
        code_review: { status: "changes_requested", summary: "Please add tests" }
      }
      expect(code_review.reload.status).to eq("changes_requested")
      expect(code_review.summary).to eq("Please add tests")
    end
  end

  describe "comments" do
    let(:code_review) { CodeReview.create!(pr_url: pr_url, pr_number: 42, reviewer: user) }

    it "adds and deletes a review comment" do
      expect {
        post code_review_comments_path(code_review), params: { comment: { body: "Nit: rename var" } }
      }.to change(code_review.comments, :count).by(1)

      comment = code_review.comments.last
      expect {
        delete code_review_comment_path(code_review, comment)
      }.to change(code_review.comments, :count).by(-1)
    end

    it "rejects a blank comment" do
      expect {
        post code_review_comments_path(code_review), params: { comment: { body: "  " } }
      }.not_to change(Comment, :count)
    end
  end

  describe "POST /code_reviews/:id/ai_review" do
    let(:code_review) { CodeReview.create!(pr_url: pr_url, pr_number: 42, reviewer: user) }

    it "runs the local LLM against the diff and stores the result" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:chat)
        .and_return("VERDICT: needs_work\nSCORE: 70\nConsider extracting the retry logic.")

      expect {
        post ai_review_code_review_path(code_review)
      }.to change { code_review.ai_reviews.count }.by(1)

      ai = code_review.ai_reviews.last
      expect(ai.kind).to eq("code_review")
      expect(ai.verdict).to eq("needs_work")
    end
  end
end
