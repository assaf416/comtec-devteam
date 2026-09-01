# Demo step definitions — simulate the AS400/COBOL session in-memory so this
# sample suite runs deterministically inside the dev sandbox (a real run
# would drive the JRuby harness against the actual AS400 on the QA machine).
INVENTORY = { "SKU-100" => 42 }.freeze

Given("חיבור JRuby ל-AS400 פעיל") { @connected = true }

When("אני מבצע בירור מלאי עבור פריט מספר {string}") do |sku|
  @sku = sku
  @quantity = INVENTORY[sku]
end

Then("אני אמור לקבל כמות מלאי תקפה") { raise "no quantity returned" unless @quantity }
Then("אני אמור לקבל הודעה {string}") do |expected|
  raise "expected a not-found message" if @quantity
  raise "wrong message" unless expected == "פריט לא נמצא"
end
