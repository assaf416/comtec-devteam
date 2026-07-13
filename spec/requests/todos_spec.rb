require "rails_helper"

RSpec.describe "Todos", type: :request do
  let(:user) { create(:user) }
  before { sign_in user }

  describe "GET /todo_lists" do
    it "shows my lists and their items" do
      list = create(:todo_list, user: user, title: "Sprint chores")
      create(:todo_item, todo_list: list, content: "Water the plants")
      get todo_lists_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sprint chores")
      expect(response.body).to include("Water the plants")
    end
  end

  describe "POST /todo_lists (quick create)" do
    it "creates a list" do
      expect {
        post todo_lists_path, params: { todo_list: { title: "Groceries" } }
      }.to change(user.todo_lists, :count).by(1)
      expect(response).to redirect_to(todo_lists_path)
    end
  end

  describe "todo items" do
    let(:list) { create(:todo_list, user: user) }

    it "adds an item" do
      expect {
        post todo_list_todo_items_path(list), params: { todo_item: { content: "Buy milk" } }
      }.to change { list.todo_items.count }.by(1)
    end

    it "assigns increasing positions" do
      post todo_list_todo_items_path(list), params: { todo_item: { content: "first" } }
      post todo_list_todo_items_path(list), params: { todo_item: { content: "second" } }
      expect(list.todo_items.order(:position).pluck(:content)).to eq(%w[first second])
    end

    it "toggles done" do
      item = create(:todo_item, todo_list: list)
      patch toggle_todo_list_todo_item_path(list, item)
      expect(item.reload.done).to be true
    end

    it "deletes an item" do
      item = create(:todo_item, todo_list: list)
      expect { delete todo_list_todo_item_path(list, item) }.to change { list.todo_items.count }.by(-1)
    end

    it "does not touch another user's list" do
      other = create(:todo_list, user: create(:user))
      post todo_list_todo_items_path(other), params: { todo_item: { content: "x" } }
      expect(response).to have_http_status(:not_found)
      expect(other.todo_items).to be_empty
    end
  end

  describe "DELETE /todo_lists/:id" do
    it "removes the list and its items" do
      list = create(:todo_list, user: user)
      create(:todo_item, todo_list: list)
      expect { delete todo_list_path(list) }.to change(user.todo_lists, :count).by(-1)
    end
  end
end
