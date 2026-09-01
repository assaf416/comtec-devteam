Given("האמולטור הפנימי פעיל") { @emulator_up = true }
When("אני שולח בקשת בדיקה") { @response_ok = @emulator_up }
Then("אני אמור לקבל תשובה תקינה") { raise "no response" unless @response_ok }
