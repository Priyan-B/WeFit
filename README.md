<<<<<<< HEAD
# WeFit
=======
# WeFit - Personal Wellness Dashboard

A Flask web app connected to MySQL, providing CRUD for schedules, events, meals, food items, medications, and users. All database logic (CRUD) is implemented as stored procedures, functions, triggers, and events inside the MySQL schema.

## Prerequisites
- Python 3.11+
- MySQL Server 8.0+
- PowerShell (Windows)

## Setup
1. Create database and routines via the provided dump:
   - Open MySQL Workbench or `mysql` client and execute `db/schema.sql`.
   - This creates the `wefit_db`, tables, constraints, indexes, data, stored procedures, functions, triggers, and scheduled event.
2. Create a MySQL user for the app:
   ```sql
   CREATE USER IF NOT EXISTS 'wefit_user'@'localhost' IDENTIFIED BY 'wefit_pass';
   GRANT ALL PRIVILEGES ON wefit_db.* TO 'wefit_user'@'localhost';
   FLUSH PRIVILEGES;
   ```
3. Copy `.env.example` to `.env` and adjust if needed.
4. Install Python dependencies:
   ```powershell
   cd "c:\Users\satya\Downloads\dpproj_v2\wefit"
   python -m venv .venv; .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
5. Run the app:
   ```powershell
   $env:FLASK_ENV="development"; python app.py
   ```
6. Visit `http://127.0.0.1:5000/` and navigate via the navbar to avoid 404.

## Notes
- Front end uses procedures like `sp_create_user`, `sp_create_schedule`, etc.; Flask does not embed raw complex SQL beyond simple reads.
- Error handling: procedures use `SIGNAL` for invalid input; Flask displays messages.
- Event scheduler: `ev_nightly_calorie_summary` populates summaries into `User_Daily_Summary`.

## Deliverables Packaging
- Include the following in `groupname_project.zip`:
  - `wefit/db/schema.sql`
  - `wefit/app.py`, `wefit/db.py`, templates under `wefit/templates/`, static assets
  - `canvas_group_name_final_report.pdf`
  - Presentation slides or video link note

## CRUD Coverage
- Users: create, list, edit, delete (procedures)
- Schedules + Events: create, list, delete
- Meals + Items: create, list, delete
- Foods: create, list
- Medications + Logs: create, list, log doses

## Troubleshooting
- If you see 404, use the navbar routes: `/`, `/users`, `/schedules`, `/foods`. Ensure DB is initialized by running `db/schema.sql`.
- MySQL `EVENT` requires `event_scheduler=ON`:
  ```sql
  SET GLOBAL event_scheduler = ON;
  ```
>>>>>>> e03e007 (Initial commit)
