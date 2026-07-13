# language: he
# features/customer_tickets.feature
תכונה: כרטיסי תמיכת לקוחות
  כנציג תמיכה או חבר צוות
  אני רוצה לנהל כרטיסי תמיכת לקוחות
  כדי לעקוב ולפתור בעיות של לקוחות

  רקע:
    בהינתן אני מחובר כמפתח
    וגם קיים לקוח בשם "Beta Client"

  @ticket_submit
  תרחיש: לקוח פותח כרטיס תמיכה חדש
    כאשר אני מבקר בדף הכרטיסים של הלקוח "Beta Client"
    וגם אני לוחץ "New Ticket"
    וגם אני ממלא "Title" בערך "Cannot install version 2.5"
    וגם אני ממלא "Message / Description" בערך "The installer fails at step 3 with error code 1603"
    וגם אני בוחר "high" עבור "priority"
    וגם אני שולח את הטופס
    אז אני אמור לראות "Cannot install version 2.5"
    וגם אני אמור לראות תגית עדיפות "high"

  @ticket_resolve
  תרחיש: פתרון כרטיס תמיכת לקוח
    בהינתן ל"Beta Client" יש כרטיס פתוח בכותרת "Login fails after update"
    כאשר אני צופה בכרטיס הלקוח הזה
    וגם אני לוחץ "Mark Resolved"
    אז הכרטיס אמור להיות מסומן כנפתר
    וגם אני אמור לראות תגית סטטוס נפתר

  @ticket_link_internal
  תרחיש: קישור כרטיס לקוח לכרטיס פנימי
    בהינתן ל"Beta Client" יש כרטיס פתוח בכותרת "Feature request: dark mode"
    וגם קיים פרויקט בשם "Digital Internet Services"
    וגם לפרויקט יש כרטיס בכותרת "Dark mode support"
    כאשר אני צופה בכרטיס הלקוח "Feature request: dark mode"
    וגם אני מקשר אותו לכרטיס הפנימי "Dark mode support"
    אז אני אמור לראות שהכרטיס הפנימי מקושר

  @ticket_assign
  תרחיש: שיוך כרטיס לקוח לחבר צוות
    בהינתן ל"Beta Client" יש כרטיס פתוח בכותרת "Data export broken"
    כאשר אני עורך את כרטיס הלקוח הזה
    וגם אני משייך אותו לחבר צוות
    וגם אני שולח את הטופס
    אז הכרטיס אמור להיות משויך לאותו חבר צוות

  @ticket_list_filter
  תרחיש: סינון כרטיסי לקוח לפי סטטוס
    בהינתן ל"Beta Client" יש 2 כרטיסים פתוחים וכרטיס אחד שנפתר
    כאשר אני מבקר בדף הכרטיסים של הלקוח "Beta Client"
    וגם אני מסנן לפי סטטוס "open"
    אז אני אמור לראות 2 כרטיסים
    וגם אני לא אמור לראות כרטיסים שנפתרו
