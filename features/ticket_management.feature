# language: he
תכונה: כרטיסים שמקורם ב-issues של GitHub
  כמפתח
  אני רוצה שכרטיסי הפרויקט ישקפו את ה-issues שלו ב-GitHub
  כדי ש-GitHub יישאר מקור האמת היחיד לפריטי עבודה

  רקע:
    בהינתן אני מחובר כמפתח
    וגם קיים פרויקט מגובה GitHub בשם "TDI2"

  תרחיש: סנכרון מייבא issues מ-GitHub ככרטיסים
    בהינתן מאגר ה-GitHub של הפרויקט מכיל issues:
      | number | title         | state | labels |
      | 1      | Fix login bug | open  | bug    |
      | 2      | Add dark mode | open  |        |
    כאשר אני מסנכרן את ה-issues של הפרויקט מ-GitHub
    אז אני אמור לראות "Fix login bug" בדף כרטיסי הפרויקט
    וגם אני אמור לראות "Add dark mode" בדף כרטיסי הפרויקט
    וגם הכרטיס "Fix login bug" אמור להיות מסוג bug_fix

  תרחיש: הכרטיסים לקריאה בלבד ומקושרים חזרה ל-GitHub
    בהינתן מאגר ה-GitHub של הפרויקט מכיל issues:
      | number | title         | state | labels |
      | 7      | Fix login bug | open  |        |
    כאשר אני מסנכרן את ה-issues של הפרויקט מ-GitHub
    וגם אני פותח את הכרטיס "Fix login bug"
    אז אני אמור לראות קישור ל-issue ב-GitHub
    וגם לא אמור להיות כפתור "New Ticket"

  תרחיש: סנכרון חוזר מעדכן במקום בלי לשכפל
    בהינתן מאגר ה-GitHub של הפרויקט מכיל issues:
      | number | title         | state  | labels |
      | 5      | Fix login bug | open   |        |
    כאשר אני מסנכרן את ה-issues של הפרויקט מ-GitHub
    וגם issue מספר "5" ב-GitHub נסגר ושמו שונה ל"Fix login bug (done)"
    וגם אני מסנכרן את ה-issues של הפרויקט מ-GitHub
    אז לפרויקט אמורים להיות בדיוק 1 כרטיסים
    וגם הכרטיס עבור issue "5" אמור להיות סגור
