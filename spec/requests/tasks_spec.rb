require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  let(:user)    { create(:user, role: :admin) }
  let(:project) { create(:project) }
  let(:ticket)  { create(:ticket, project: project, kind: :bug_fix) }

  before { sign_in user }

  describe "POST /tickets/:ticket_id/tasks" do
    it "adds a task to the ticket" do
      expect {
        post ticket_tasks_path(ticket), params: { task: { description: "Wire up the API", estimation: "4h" } }
      }.to change(ticket.tasks, :count).by(1)
      expect(ticket.tasks.last.description).to eq("Wire up the API")
      expect(response).to redirect_to(ticket_path(ticket, anchor: "tasks"))
    end

    it "rejects a blank description" do
      expect {
        post ticket_tasks_path(ticket), params: { task: { description: "" } }
      }.not_to change(Task, :count)
    end
  end

  describe "lifecycle actions" do
    let!(:task) { create(:task, ticket: ticket) }

    it "starts a task" do
      patch start_ticket_task_path(ticket, task)
      expect(task.reload.status).to eq("in_progress")
    end

    it "completes a task" do
      patch complete_ticket_task_path(ticket, task)
      expect(task.reload.status).to eq("completed")
    end

    it "reopens a completed task" do
      task.complete!
      patch reopen_ticket_task_path(ticket, task)
      expect(task.reload.status).not_to eq("completed")
    end

    it "deletes a task" do
      expect {
        delete ticket_task_path(ticket, task)
      }.to change(Task, :count).by(-1)
    end
  end

  describe "ticket page shows the tasks panel with progress" do
    it "renders progress and tasks" do
      create(:task, ticket: ticket, description: "First task")
      get ticket_path(ticket)
      expect(response.body).to include('id="tasks"')
      expect(response.body).to include("First task")
    end
  end

  describe "progress badges (percent + hours) wherever a ticket appears" do
    before do
      create(:task, ticket: ticket, estimation: "2h")
      create(:task, ticket: ticket, estimation: "6h").complete!
      ticket.reload
    end

    it "shows the percent and hours badges on the ticket page" do
      get ticket_path(ticket)
      expect(response.body).to include("🧩 #{ticket.tasks_progress_in_percents}%")
      expect(response.body).to include("⏱ 6/8h") # 6 of 8 estimated hours done
    end

    it "shows the badges in the cross-project ticket list" do
      get all_tickets_path
      expect(response.body).to include("🧩 #{ticket.tasks_progress_in_percents}%")
      expect(response.body).to include("6/8h")
    end
  end
end
