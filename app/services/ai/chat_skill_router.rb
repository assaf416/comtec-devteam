module Ai
  # Routes a natural-language chat message (Hebrew or English) to a local-LLM
  # "skill". If no skill matches, `handled` is false and the caller falls back to
  # a normal conversation. All LLM work runs on the on-prem Ollama model.
  #
  # Supported skills:
  #   • solution      — read a GitHub issue and suggest a solution
  #   • cucumber       — write Cucumber tests for just-merged code
  #   • code_review    — review a diff / the latest PR
  #   • diagram        — generate a flow / ERD / UML diagram (Mermaid)
  #   • task_list      — turn pasted material into a proposed list of GitHub issues
  #                      (returned as `proposal`; opened only after the user approves)
  class ChatSkillRouter
    Result = Struct.new(:handled, :reply, :proposal, :skill, keyword_init: true)

    def initialize(project:, user: nil, client: nil)
      @project = project
      @user    = user
      @client  = client || OllamaClient.new
    end

    def route(text)
      t = text.to_s
      return estimate(t)    if estimate?(t)
      return diagram(t)     if diagram?(t)
      return cucumber(t)    if cucumber?(t)
      return task_list(t)   if task_list?(t)
      return code_review(t) if code_review?(t)
      return solution(t)    if solution?(t)

      Result.new(handled: false)
    end

    # ── Intent detection (Hebrew + English) ────────────────────────────────
    def estimate?(t)    = t.match?(/הערכת זמן|הערכת זמנים|אומדן זמן|כמה זמן|estimate|estimation/i)
    def diagram?(t)     = t.match?(/diagram|דיאגרמ|תרשים|\berd\b|\buml\b|\bflow\b|flowchart|מבנה נתונים|מבנה הנתונים/i)
    def cucumber?(t)    = t.match?(/cucumber|gherkin|\.feature|טסטים|בדיקות|כתוב.*טסט|write.*tests?/i)
    def task_list?(t)   = t.match?(/מטלות|רשימת מטלות|task list|generate tasks|לפתוח issues|open .*issues|issues מהקובץ|from (?:this )?file/i)
    def code_review?(t) = t.match?(/code review|סקירת קוד|בדוק את הקוד|review (?:this|the) code|בצע סקירה/i)
    def solution?(t)    = t.match?(/פתרון|solution|לפתור|suggest.*(?:solution|approach)|הצע.*פתרון/i)

    private

    # ── Skills ─────────────────────────────────────────────────────────────
    def estimate(text)
      number = text[/#?\b(\d{1,6})\b/, 1] || text[/T-(\d+)/i, 1]
      ticket = find_ticket(number)
      unless ticket
        return Result.new(handled: true, skill: :ticket_estimation,
                          reply: "לא מצאתי טיקט/issue מספר #{number || '—'} בפרויקט הזה. ציין מספר טיקט קיים.")
      end
      review = TicketEstimationService.new(reviewable: ticket, user: @user, client: @client).call
      Result.new(handled: true, skill: :ticket_estimation, reply: review.body.presence || review.error_message)
    end

    def diagram(text)
      kind = if text.match?(/erd|מבנה נתונים|מבנה הנתונים/i) then :erd
      elsif text.match?(/uml/i) then :uml
      else :flow
      end
      reply = DiagramService.new(project: @project, client: @client).call(request: text, kind: kind)
      Result.new(handled: true, skill: :diagram, reply: reply)
    end

    def cucumber(text)
      diff = fenced_block(text) || latest_merged_diff
      reply = CucumberGenerationService.new(project: @project, client: @client).call(diff: diff)
      Result.new(handled: true, skill: :cucumber, reply: reply)
    end

    def code_review(text)
      diff   = fenced_block(text) || latest_merged_diff
      review = CodeReviewService.new(reviewable: @project, user: @user, client: @client, diff: diff).call
      Result.new(handled: true, skill: :code_review, reply: review.body.presence || review.error_message)
    end

    def solution(text)
      number = text[/#?\b(\d{1,6})\b/, 1] || text[/T-(\d+)/i, 1]
      ticket = find_ticket(number)
      unless ticket
        return Result.new(handled: true, skill: :solution,
                          reply: "לא מצאתי טיקט/issue מספר #{number || '—'} בפרויקט הזה. ציין מספר issue קיים.")
      end
      review = SolutionSuggestionService.new(reviewable: ticket, user: @user, client: @client).call
      Result.new(handled: true, skill: :solution, reply: review.body.presence || review.error_message)
    end

    def task_list(text)
      source = fenced_block(text) || text
      tasks  = IssueTaskListService.new(project: @project, client: @client).call(source: source)
      if tasks.empty?
        return Result.new(handled: true, skill: :task_list,
                          reply: "לא הצלחתי לחלץ מטלות מהטקסט. נסה לספק תוכן מפורט יותר.")
      end

      list = tasks.map.with_index(1) { |tk, i| "#{i}. **#{tk['title']}** — #{tk['body']}" }.join("\n")
      reply = "הצעתי #{tasks.size} מטלות לפתיחה כ-GitHub issues. אשר למטה כדי לפתוח אותן:\n\n#{list}"
      Result.new(handled: true, skill: :task_list, reply: reply, proposal: { "tasks" => tasks })
    end

    # ── Helpers ────────────────────────────────────────────────────────────
    def find_ticket(number)
      return nil if number.blank?
      @project.tickets.find_by(github_issue_number: number.to_i) ||
        @project.tickets.find_by(id: number.to_i)
    end

    def latest_merged_diff
      pr = @project.pull_requests.where.not(code_changed: [ nil, "" ]).order(updated_at: :desc).first
      pr&.code_changed
    end

    # Extracts the contents of the first fenced ``` code block in the message.
    def fenced_block(text)
      m = text.match(/```[a-z]*\n(.*?)```/mi)
      m && m[1].strip.presence
    end
  end
end
