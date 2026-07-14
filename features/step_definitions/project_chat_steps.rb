require "rails_helper"

Given("קיים ערוץ צ'אט {string} בפרויקט {string}") do |room_name, project_name|
  project = Project.find_by!(name: project_name)
  @chat_room = ChatRoom.create!(name: room_name, project: project, room_type: :project_room)
end

When("אני מבקר בערוץ הצ'אט {string}") do |room_name|
  room = ChatRoom.find_by!(name: room_name)
  visit chat_room_path(room)
end

When("אני מבקר בעמוד הפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  visit project_path(project)
end

When("אני עובר לצ'אט הפרויקט {string}") do |project_name|
  project = Project.find_by!(name: project_name)
  visit project_chat_path(project)
end

When("אני שולח בצ'אט את ההודעה {string} עם הקובץ {string}") do |body, filename|
  within("#chatComposeForm") do
    find("textarea[name='chat_message[body]']").set(body)
    attach_file "chat_message[files][]", fixture_file(filename)
    click_button "Send"
  end
end
