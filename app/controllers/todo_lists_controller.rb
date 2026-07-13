class TodoListsController < ApplicationController
  before_action :set_list, only: %i[update destroy]

  def index
    @todo_lists = current_user.todo_lists.recent.includes(:todo_items)
    @todo_list  = current_user.todo_lists.build
  end

  # Quick create — one field (title) spins up a new list.
  def create
    @todo_list = current_user.todo_lists.build(list_params)
    if @todo_list.save
      redirect_to todo_lists_path, notice: t("todos.list_created")
    else
      @todo_lists = current_user.todo_lists.recent.includes(:todo_items)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @todo_list.update(list_params)
    redirect_to todo_lists_path
  end

  def destroy
    @todo_list.destroy
    redirect_to todo_lists_path, notice: t("todos.list_deleted")
  end

  private

  def set_list
    @todo_list = current_user.todo_lists.find(params[:id])
  end

  def list_params
    params.require(:todo_list).permit(:title)
  end
end
