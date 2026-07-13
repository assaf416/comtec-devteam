require "rails_helper"

RSpec.describe Ai::ChatSkillRouter do
  let(:project) { create(:project, repo_url: "https://github.com/acme/widget") }

  # Fake Ollama client — returns canned text without any network.
  let(:canned) { "VERDICT: pass\nSCORE: 80\n\n## Result\nStubbed LLM output." }
  let(:client) do
    Class.new do
      def initialize(text) = @text = text
      def model = "fake-model"
      def chat(**) = @text
      def converse(**) = @text
    end.new(canned)
  end

  subject(:router) { described_class.new(project: project, client: client) }

  it "routes a diagram request to the diagram skill" do
    result = router.route("צור דיאגרמת flow של התהליך")
    expect(result.handled).to be true
    expect(result.skill).to eq(:diagram)
    expect(result.reply).to include("Stubbed LLM output")
  end

  it "routes a cucumber request to the cucumber skill" do
    result = router.route("כתוב טסטים ב-cucumber לקוד שנכנס")
    expect(result.skill).to eq(:cucumber)
  end

  it "routes a code review request to the code_review skill" do
    result = router.route("בצע code review לקוד האחרון")
    expect(result.skill).to eq(:code_review)
    expect(result.handled).to be true
  end

  it "routes an issue-solution request and reads the referenced ticket" do
    create(:ticket, project: project, github_issue_number: 3, title: "SSO login")
    result = router.route("קרא את issue #3 ב-GitHub והצע פתרון")
    expect(result.skill).to eq(:solution)
    expect(result.reply).to include("Stubbed LLM output")
  end

  it "reports when the referenced issue is not found" do
    result = router.route("הצע פתרון ל-issue #999")
    expect(result.skill).to eq(:solution)
    expect(result.reply).to include("לא מצאתי")
  end

  context "task list → issues proposal" do
    let(:canned) { "Login page :: Build the login form\nSignup :: Add the signup flow" }

    it "returns a proposal of tasks (not yet opened)" do
      result = router.route("צור רשימת מטלות מהקובץ הבא לפתיחה כ-issues")
      expect(result.skill).to eq(:task_list)
      expect(result.proposal["tasks"].size).to eq(2)
      expect(result.proposal["tasks"].first["title"]).to eq("Login page")
    end
  end

  it "does not handle a plain conversational message" do
    expect(router.route("מה שלום הצוות היום?").handled).to be false
  end
end
