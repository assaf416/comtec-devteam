require "rails_helper"

Given("קיים חדר צ'אט בשם {string}") do |name|
  @chat_room = ChatRoom.create!(name: name, room_type: :general)
end

When("אני נועץ את חדר הצ'אט {string}") do |name|
  room = ChatRoom.find_by!(name: name)
  @user.chat_room_pins.create!(chat_room: room, pinned_at: Time.current)
end

When("אני מבטל את הנעיצה של חדר הצ'אט {string}") do |name|
  room = ChatRoom.find_by!(name: name)
  visit chat_rooms_path
  within(:xpath, "//tr[contains(., \"#{name}\")]") { click_button "Unpin" }
end

Then("אני אמור לראות {string} בתפריט הצ'אט בסיידבר") do |name|
  within(".app-sidebar") { expect(page).to have_content(name) }
end

Then("אני לא אמור לראות {string} בתפריט הצ'אט בסיידבר") do |name|
  within(".app-sidebar") { expect(page).not_to have_content(name) }
end
