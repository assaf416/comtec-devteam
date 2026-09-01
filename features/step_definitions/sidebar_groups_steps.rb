require "rails_helper"

Given("אני חבר בחדר צ'אט בשם {string}") do |name|
  room = ChatRoom.create!(name: name, room_type: :general)
  @user.chat_room_memberships.create!(chat_room: room, joined_at: Time.current)
end

Then("אני אמור לראות {string} בסרגל הצד") do |text|
  within(".app-sidebar") { expect(page).to have_content(text) }
end

Then("אני לא אמור לראות {string} בסרגל הצד") do |text|
  within(".app-sidebar") { expect(page).not_to have_content(text) }
end

Then("אני אמור לראות את הקישור {string} תחת הכותרת {string}") do |link_text, section_title|
  sidebar = find(".app-sidebar")
  in_section = false
  found = false

  sidebar.all(:xpath, "./*", visible: :all).each do |node|
    if node[:class].to_s.include?("sidebar-section-label")
      in_section = node.text.strip == section_title
      next
    end
    if node.tag_name == "hr"
      in_section = false
      next
    end
    found = true if in_section && node.text.include?(link_text)
  end

  expect(found).to be(true), "Expected to find \"#{link_text}\" under section \"#{section_title}\" in the sidebar"
end
