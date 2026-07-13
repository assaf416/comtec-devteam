class TodoItemsController < ApplicationController
  before_action :set_list
  before_action :set_item, only: %i[update toggle destroy]

  def create
    @item = @todo_list.todo_items.build(item_params)
    @item.save
    redirect_to todo_lists_path
  end

  def update
    @item.update(item_params)
    redirect_to todo_lists_path
  end

  # Flip done/undone with one click.
  def toggle
    @item.update(done: !@item.done)
    redirect_to todo_lists_path
  end

  def destroy
    @item.destroy
    redirect_to todo_lists_path
  end

  private

  def set_list
    @todo_list = current_user.todo_lists.find(params[:todo_list_id])
  end

  def set_item
    @item = @todo_list.todo_items.find(params[:id])
  end

  def item_params
    params.require(:todo_item).permit(:content, :done)
  end
end
