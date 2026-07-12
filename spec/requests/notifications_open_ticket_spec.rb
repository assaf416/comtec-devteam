require 'rails_helper'

RSpec.describe "Notifications → Open ticket", type: :request do
  let(:user)     { create(:user) }
  let!(:project) { create(:project, name: "Print Server") }
  before { sign_in user }

  def notify(**attrs)
    Notification.create!({ recipient: user, type: "Notification" }.merge(attrs))
  end

  it "creates a story ticket from a plain notification and opens it for editing" do
    n = notify(message: "Customer reported slow PDF export", params: { "project_name" => "Print Server" })

    expect {
      post open_ticket_notification_path(n), headers: { "HTTP_REFERER" => notifications_path }
    }.to change(Ticket, :count).by(1)

    ticket = Ticket.last
    expect(ticket.project).to eq(project)
    expect(ticket.title).to include("slow PDF export")
    expect(ticket.owner).to eq(user)
    expect(ticket.kind).to eq("story")
    expect(ticket.description).to include("Customer reported slow PDF export")
    expect(n.reload.read_at).to be_present
    expect(response).to redirect_to(edit_ticket_path(ticket))
  end

  it "creates a high-priority bug with reproduction from an exception notification" do
    n = notify(message: "Exception in OrdersController",
               error_message: "NoMethodError: undefined method `total'",
               backtrace: "app/controllers/orders_controller.rb:42")

    post open_ticket_notification_path(n)
    ticket = Ticket.last
    expect(ticket.kind).to eq("bug_fix")
    expect(ticket.priority).to eq("high")
    expect(ticket.how_to_reproduce).to include("NoMethodError")
  end

  it "resolves the project by id from the notification params" do
    other = create(:project, name: "Other")
    n = notify(message: "Do the thing", params: { "project_id" => other.id })
    post open_ticket_notification_path(n)
    expect(Ticket.last.project).to eq(other)
  end

  it "falls back to an active project when the notification names none" do
    n = notify(message: "Generic note")
    expect { post open_ticket_notification_path(n) }.to change(Ticket, :count).by(1)
    expect(Ticket.last.project).to eq(project)
  end

  it "only opens the current user's notifications" do
    others = create(:user).notifications.create!(type: "Notification", message: "theirs")
    post open_ticket_notification_path(others)
    expect(response).to have_http_status(:not_found)
  end

  it "exposes the action in the notifications list kebab" do
    notify(message: "hi")
    get notifications_path
    expect(response.body).to include("Open ticket")
    expect(response.body).to include(open_ticket_notification_path(Notification.last))
  end
end
