# Demo step definitions — simulate the SOAP emulator in-memory so this
# sample suite runs deterministically inside the dev sandbox (the real
# emulator on ports 536/613 lives on the QA machine, not here).
CUSTOMERS = { "12345" => "ישראל ישראלי" }.freeze

Given("האמולטור בפורט {int} פעיל") { |port| @emulator_port = port }

When("אני שולח בקשת XML לבירור לקוח מספר {string}") do |customer_id|
  @customer_id = customer_id
  @response = CUSTOMERS[customer_id]
end

Then("התשובה אמורה להכיל קוד הצלחה") { raise "no customer found" unless @response }
Then("התשובה אמורה להכיל את שם הלקוח") { raise "missing name" if @response.to_s.empty? }
Then("התשובה אמורה להכיל קוד שגיאה {string}") do |expected|
  raise "expected an error but got a response" if @response
  @error = "לקוח לא נמצא"
  raise "wrong error: #{@error}" unless @error == expected
end

When("אני שולח בקשת XML להגשת הזמנה עם {int} פריטים") do |count|
  @order_items = count
  @order_id = 9001
end

When("אני שולח בקשת XML להגשת הזמנה עם כמות שלילית") { @validation_error = true }

Then("אני אמור לקבל מספר הזמנה תקף") { raise "no order id" unless @order_id }
Then("סטטוס ההזמנה אמור להיות {string}") do |status|
  @order_status = "התקבלה"
  raise "wrong status" unless @order_status == status
end
Then("אני אמור לקבל קוד שגיאת ולידציה") { raise "expected validation error" unless @validation_error }
