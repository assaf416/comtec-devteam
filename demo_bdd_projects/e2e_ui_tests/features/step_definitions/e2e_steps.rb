# Demo step definitions — simulate page/form state in-memory so this sample
# suite runs deterministically inside the dev sandbox (a real E2E run would
# drive an actual browser against the QA machine's UI).
Given("אני נמצא בעמוד ההתחברות") { @page = :login }
Given("אני נמצא בעמוד יצירת הקשר") { @page = :contact }

When("אני ממלא שם משתמש וסיסמה תקינים") { @credentials_valid = true }
When("אני ממלא שם משתמש תקין וסיסמה שגויה") { @credentials_valid = false }
When("אני ממלא את כל שדות הטופס") { @form_complete = true }
When("אני משאיר את שדה האימייל ריק") { @form_complete = false }

When("אני לוחץ על כפתור {string}") do |label|
  @clicked = label
  if @page == :login
    @logged_in = @credentials_valid
  elsif @page == :contact
    @submitted = @form_complete
  end
end

Then("אני אמור להגיע לעמוד הבית") { raise "login failed" unless @logged_in }
Then("אני אמור לראות הודעת שגיאה") { raise "expected a login failure" if @logged_in }
Then("אני אמור לראות הודעת אישור שליחה") { raise "form was not submitted" unless @submitted }
Then("אני אמור לראות הודעת שגיאת ולידציה") { raise "expected a validation failure" if @submitted }
