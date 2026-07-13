# language: he
# features/customer_management.feature
תכונה: ניהול לקוחות
  כראש צוות או מנהל פרויקט
  אני רוצה לנהל לקוחות במערכת
  כדי לעקוב אחר אילו לקוחות משתמשים בתוכנה שלנו

  רקע:
    בהינתן אני מחובר כמפתח

  @customer_create
  תרחיש: יצירת לקוח חדש
    כאשר אני מבקר בדף רשימת הלקוחות
    וגם אני לוחץ "New Customer"
    וגם אני ממלא "Name" בערך "Acme Corp"
    וגם אני ממלא "Email" בערך "contact@acme.com"
    וגם אני ממלא "Company" בערך "Acme Corporation"
    וגם אני שולח את הטופס
    אז אני אמור לראות "Acme Corp"
    וגם אני אמור לראות "Customer was successfully created" או הודעת הצלחה

  @customer_list
  תרחיש: צפייה ברשימת הלקוחות
    בהינתן קיימים 3 לקוחות פעילים
    כאשר אני מבקר בדף רשימת הלקוחות
    אז אני אמור לראות 3 שורות לקוח בטבלה

  @customer_search
  תרחיש: חיפוש לקוח לפי שם
    בהינתן קיים לקוח בשם "GlobalTech Ltd"
    וגם קיים לקוח בשם "Local Services"
    כאשר אני מבקר בדף רשימת הלקוחות
    וגם אני מחפש "Global"
    אז אני אמור לראות "GlobalTech Ltd"
    וגם אני לא אמור לראות "Local Services"

  @customer_deactivate
  תרחיש: סינון לקוחות פעילים בלבד
    בהינתן קיים לקוח פעיל בשם "Active Co"
    וגם קיים לקוח לא פעיל בשם "Closed Corp"
    כאשר אני מבקר בדף רשימת הלקוחות ומסנן פעילים בלבד
    אז אני אמור לראות "Active Co"
    וגם אני לא אמור לראות "Closed Corp"

  @customer_edit
  תרחיש: עריכת לקוח קיים
    בהינתן קיים לקוח בשם "Old Name Corp"
    כאשר אני עורך את הלקוח הזה ומשנה את השם ל"New Name Corp"
    אז אני אמור לראות "New Name Corp"
    וגם אני אמור לראות "Customer was successfully updated" או הודעת הצלחה
