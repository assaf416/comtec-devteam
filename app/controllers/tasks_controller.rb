# Tasks under a ticket — the small, estimable units that make up a story.
class TasksController < ApplicationController
  before_action :set_ticket, only: :create
  before_action :set_task,   only: %i[update destroy start complete reopen]

  def create
    @task = @ticket.tasks.build(task_params)
    @task.user ||= current_user
    if @task.save
      redirect_to ticket_path(@ticket, anchor: "tasks"), notice: "Task added."
    else
      redirect_to ticket_path(@ticket, anchor: "tasks"), alert: @task.errors.full_messages.to_sentence
    end
  end

  def update
    if @task.update(task_params)
      redirect_to ticket_path(@task.ticket, anchor: "tasks"), notice: "Task updated."
    else
      redirect_to ticket_path(@task.ticket, anchor: "tasks"), alert: @task.errors.full_messages.to_sentence
    end
  end

  def start
    @task.start!
    redirect_to ticket_path(@task.ticket, anchor: "tasks"), notice: "Task started."
  end

  def complete
    @task.complete!
    redirect_to ticket_path(@task.ticket, anchor: "tasks"), notice: "Task completed."
  end

  def reopen
    @task.reopen!
    redirect_to ticket_path(@task.ticket, anchor: "tasks"), notice: "Task reopened."
  end

  def destroy
    ticket = @task.ticket
    @task.destroy
    redirect_to ticket_path(ticket, anchor: "tasks"), notice: "Task deleted."
  end

  private

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id])
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:description, :estimation, :actual, :user_id)
  end
end
