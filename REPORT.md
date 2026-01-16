# WeFit Final Report (Canvas: BaskarPGuruswamyS)

## README: Build and Run
- See `README.md` in project root for step-by-step instructions.
- Prereqs: Python 3.11+, MySQL 8.0+, PowerShell.
- DB: Run `db/schema.sql`, create MySQL user, enable event scheduler if needed.
- App: create venv, install requirements, run `python app.py`, open `http://127.0.0.1:5000/`.

## Technical Specifications
- Host Language: Python 3.11+
- Framework: Flask 3.x, Jinja2
- DB: MySQL 8.0
- Connectivity: `mysql-connector-python`
- Env: `.env` via `python-dotenv`

## Conceptual Design (UML)
- See attached UML image in submission. Entities: User, Schedule, Schedule_Events, Event_Category, Food_Items, Food_Allergens, Meal_Log, Meal_Items, Medication, Medication_Log.

## Logical Design (Schema)
- See `db/schema.sql`. Third Normal Form, PK/FK constraints, ON UPDATE/DELETE, CHECKs, UNIQUEs, generated column `duration`, indexes.

## User Flow
- Navigate via navbar: Home → Users/Schedules/Foods.
- Users: Create → Edit → Delete.
- Schedules: Create for a user → Events: Create/Delete.
- Foods: Create; Meals: Create for a user with items; view totals; delete meals.
- Medications: Create for a user; log doses.
- Analytics: `/analytics/<userID>?date=YYYY-MM-DD` for macros.

## Lessons Learned
- Technical: Stored procedures and `SIGNAL`-based validation; MySQL events; generated columns; Flask-blueprint would be a future refactor.
- Insights: Consolidating wellness domains improves usability; schema design around junction tables for meals.
- Alternatives: ORMs (SQLAlchemy) vs stored-proc-centric approach; NoSQL for food catalog, but relational integrity preferred.
- Known Issues: None blocking; event scheduler requires server config.

## Future Work
- Role-based access (admin vs user), richer analytics with charts.
- Notification/reminders, calendar integrations.
- Bulk import/export; OAuth login.

