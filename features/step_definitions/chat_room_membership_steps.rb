require "rails_helper"

When("אני מצטרף לחדר הצ'אט {string}") do |name|
  room = ChatRoom.find_by!(name: name)
  @user.chat_room_memberships.create!(chat_room: room, joined_at: Time.current)
end

When("אני עוזב את חדר הצ'אט {string}") do |name|
  room = ChatRoom.find_by!(name: name)
  @user.chat_room_memberships.where(chat_room: room).destroy_all
end

Then("אני אמור לראות {string} בסעיף החדרים שלי") do |name|
  within("#section-chat-rooms") { expect(page).to have_content(name) }
end

Then("אני לא אמור לראות {string} בסעיף החדרים שלי") do |name|
  within("#section-chat-rooms") { expect(page).not_to have_content(name) }
end
