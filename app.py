from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from db import DB
import os
from datetime import datetime

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "dev_secret")
DB.init_pool()

@app.context_processor
def inject_user():
    return {
        "uid": session.get("userID"),
        "firstName": session.get("firstName"),
        "today": datetime.now().strftime("%Y-%m-%d")
    }

def format_duration(start_str, end_str):
    try:
        start = datetime.fromisoformat(str(start_str).replace(" ", "T"))
        end = datetime.fromisoformat(str(end_str).replace(" ", "T"))
        total_minutes = int((end - start).total_seconds() // 60)
        if total_minutes < 60:
            return f"{total_minutes} min"
        days = total_minutes // (60 * 24)
        rem = total_minutes % (60 * 24)
        hours = rem // 60
        minutes = rem % 60
        parts = []
        if days:
            parts.append(f"{days} day" + ("s" if days != 1 else ""))
        if hours:
            parts.append(f"{hours} hr" + ("s" if hours != 1 else ""))
        if minutes:
            parts.append(f"{minutes} min")
        return ", ".join(parts) if parts else "0 min"
    except Exception:
        return "-"

@app.context_processor
def inject_helpers():
    return {"format_duration": format_duration}

def require_login():
    if not session.get("userID"):
        flash("Please log in", "error")
        return False
    return True

@app.route("/login", methods=["GET","POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email")
        password = request.form.get("password")
        # For simplicity, compare plaintext to stored passwordHash; in production use hashing
        user_rows = DB.call_proc("sp_get_user_by_email", (email,))
        if user_rows:
            user = user_rows[0]
            if check_password_hash(user.get("passwordhash"), password):
                session["userID"] = user["userid"]
                session["firstName"] = user["firstname"]
                flash("Logged in", "success")
                return redirect(url_for("index"))
        flash("Invalid credentials", "error")
    return render_template("auth/login.html")

@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out", "info")
    return redirect(url_for("login"))

@app.route("/register", methods=["GET","POST"])
def register():
    if request.method == "POST":
        try:
            hashed = generate_password_hash(request.form.get("password"))
            DB.call_proc("sp_create_user", (
                request.form.get("firstName"),
                request.form.get("lastName"),
                request.form.get("email"),
                hashed
            ))
            flash("Account created. Please log in.", "success")
            return redirect(url_for("login"))
        except Exception as e:
            flash(str(e), "error")
    return render_template("auth/register.html")

@app.route("/")
def index():
    uid = session.get("userID")
    if not uid:
        return redirect(url_for("welcome"))
    schedules = DB.call_proc("sp_list_schedules_by_user", (uid,))
    meals = DB.call_proc("sp_list_meals", (uid,))
    try:
        meds = DB.call_proc("sp_list_meds", (uid,))
    except Exception as e:
        meds = []
        flash("Medications procedure missing or failed: " + str(e), "error")
    # Fetch recent meals with items in one call for dashboard
    recent_headers = []
    recent_items = []
    try:
        rows = DB.call_proc("sp_list_recent_meal_items_by_user", (uid, 5))
        # First result set: headers; second: items
        # Differentiate by presence of 'foodname' key
        for r in rows:
            if "foodname" in r:
                recent_items.append(r)
            else:
                recent_headers.append(r)
    except Exception:
        recent_headers = []
        recent_items = []
    # Build map meallogid -> {header, items}
    meal_details = {}
    for h in recent_headers:
        meal_details[h.get("meallogid")] = {"header": h, "items": []}
    for it in recent_items:
        mlid = it.get("meallogid")
        if mlid in meal_details:
            meal_details[mlid]["items"].append(it)
    # Daily macros for today
    macros_today = None
    try:
        mrows = DB.call_proc("sp_user_daily_macros", (uid, datetime.now().strftime("%Y-%m-%d")))
        macros_today = mrows[0] if mrows else None
    except Exception:
        macros_today = None
    return render_template("index.html", users=[], schedules=schedules, meals=meals, meds=meds, uid=uid, meal_details=meal_details, macros_today=macros_today)

@app.route("/welcome")
def welcome():
    if session.get("userID"):
        return redirect(url_for("index"))
    return render_template("welcome.html")

# Users CRUD via stored procedures
@app.route("/users")
def list_users():
    if not require_login():
        return redirect(url_for("login"))
    users = DB.call_proc("sp_list_users")
    return render_template("users/list.html", users=users)

@app.route("/users/create", methods=["GET","POST"])
def create_user():
    if request.method == "POST":
        try:
            DB.call_proc("sp_create_user", (
                request.form.get("firstName"),
                request.form.get("lastName"),
                request.form.get("emailID"),
                request.form.get("passwordHash")
            ))
            flash("User created", "success")
            return redirect(url_for("list_users"))
        except Exception as e:
            flash(str(e), "error")
    return render_template("users/create.html")

@app.route("/users/<int:userID>/edit", methods=["GET","POST"])
def edit_user(userID):
    if request.method == "POST":
        try:
            DB.call_proc("sp_update_user", (userID, request.form.get("firstName"), request.form.get("lastName")))
            flash("User updated", "success")
            return redirect(url_for("list_users"))
        except Exception as e:
            flash(str(e), "error")
    user = DB.execute("SELECT firstname, lastname FROM user WHERE userid = %s", (userID,))
    return render_template("users/edit.html", user=user[0] if user else None)

@app.route("/users/<int:userID>/delete", methods=["POST"]) 
def delete_user(userID):
    try:
        DB.call_proc("sp_delete_user", (userID,))
        flash("User deleted", "success")
    except Exception as e:
        flash(str(e), "error")
    return redirect(url_for("list_users"))

# Schedules
@app.route("/schedules")
def list_schedules():
    if not require_login():
        return redirect(url_for("login"))
    rows = DB.call_proc("sp_list_schedules_by_user", (session.get("userID"),))
    return render_template("schedules/list.html", schedules=rows)

@app.route("/schedules/create", methods=["GET","POST"])
def create_schedule():
    if not require_login():
        return redirect(url_for("login"))
    if request.method == "POST":
        try:
            DB.call_proc("sp_create_schedule", (int(session.get("userID")), request.form.get("scheduleName")))
            flash("Schedule created", "success")
            return redirect(url_for("list_schedules"))
        except Exception as e:
            flash(str(e), "error")
    return render_template("schedules/create.html")

@app.route("/schedules/<int:scheduleID>/delete", methods=["POST"]) 
def delete_schedule(scheduleID):
    try:
        DB.call_proc("sp_delete_schedule", (scheduleID,))
        flash("Schedule deleted", "success")
    except Exception as e:
        flash(str(e), "error")
    return redirect(url_for("list_schedules"))

# Events
@app.route("/events/<int:scheduleID>")
def list_events(scheduleID):
    if not require_login():
        return redirect(url_for("login"))
    events = DB.call_proc("sp_list_events_by_schedule", (scheduleID,))
    return render_template("events/list.html", events=events, scheduleID=scheduleID)

@app.route("/events/create/<int:scheduleID>", methods=["GET","POST"])
def create_event(scheduleID):
    if not require_login():
        return redirect(url_for("login"))
    cats = DB.execute("SELECT categoryid, categoryname FROM event_category ORDER BY categoryname")
    if request.method == "POST":
        try:
            DB.call_proc("sp_create_event", (scheduleID,
                      int(request.form.get("categoryID")) if request.form.get("categoryID") else None,
                      request.form.get("eventTitle"),
                      request.form.get("startTime"),
                      request.form.get("endTime"),
                      request.form.get("description")
            ))
            flash("Event created", "success")
            return redirect(url_for("list_events", scheduleID=scheduleID))
        except Exception as e:
            flash(str(e), "error")
    return render_template("events/create.html", scheduleID=scheduleID, categories=cats)

@app.route("/events/<int:eventID>/delete", methods=["POST"]) 
def delete_event(eventID):
    try:
        DB.call_proc("sp_delete_event", (eventID,))
        flash("Event deleted", "success")
    except Exception as e:
        flash(str(e), "error")
    return redirect(request.referrer or url_for("index"))

# Meals
@app.route("/meals/<int:userID>")
def list_meals(userID):
    if not require_login():
        return redirect(url_for("login"))
    if session.get("userID") != userID:
        flash("Unauthorized", "error")
        return redirect(url_for("index"))
    meals = DB.call_proc("sp_list_meals", (userID,))
    # Build detailed items per meal
    meal_items_map = {}
    for m in meals or []:
        try:
            rows = DB.call_proc("sp_get_meal_detail", (m.get("meallogid"),))
            items = [r for r in rows if "foodname" in r]
            meal_items_map[m.get("meallogid")] = items
        except Exception:
            meal_items_map[m.get("meallogid")] = []
    return render_template("meals/list.html", meals=meals, userID=userID, meal_items_map=meal_items_map)
 
@app.route("/meals/edit/<int:mealLogID>", methods=["GET","POST"])
def edit_meal(mealLogID):
    if not require_login():
        return redirect(url_for("login"))
    # Load current meal header + items
    rows = DB.call_proc("sp_get_meal_detail", (mealLogID,))
    header = None
    items = []
    for r in rows:
        if "foodname" in r:
            items.append(r)
        else:
            header = r
    if not header or header.get("userid") != session.get("userID"):
        flash("Unauthorized or not found", "error")
        return redirect(url_for("index"))
    # Use allergens proc with lowercase keys; fallback and normalize if needed
    try:
        foods = DB.call_proc("sp_list_foods_with_allergens")
    except Exception:
        raw_foods = DB.call_proc("sp_list_foods")
        foods = [{
            "foodid": f.get("foodid") or f.get("foodID"),
            "name": f.get("name") or f.get("Name"),
            "calories": f.get("calories") or f.get("Calories"),
            "proteins": f.get("proteins") or f.get("Proteins"),
            "carbs": f.get("carbs") or f.get("Carbs"),
            "fats": f.get("fats") or f.get("Fats")
        } for f in (raw_foods or [])]
    if request.method == "POST":
        try:
            DB.call_proc("sp_update_meal", (mealLogID, request.form.get("mealType"), request.form.get("logTime")))
            DB.call_proc("sp_clear_meal_items", (mealLogID,))
            for foodID, qty in zip(request.form.getlist("foodID"), request.form.getlist("quantityInGram")):
                if foodID and qty:
                    DB.call_proc("sp_add_meal_item", (int(mealLogID), int(foodID), int(qty)))
            flash("Meal updated", "success")
            return redirect(url_for("list_meals", userID=session.get("userID")))
        except Exception as e:
            flash(str(e), "error")
    return render_template("meals/edit.html", meal=header, items=items, foods=foods)

@app.route("/meals/detail/<int:mealLogID>")
def meal_detail(mealLogID):
    if not require_login():
        return redirect(url_for("login"))
    # Get detail and items using stored procedure
    try:
        results = DB.call_proc("sp_get_meal_detail", (mealLogID,))
    except Exception as e:
        flash("Meal detail procedure missing or failed: " + str(e), "error")
        return redirect(url_for("index"))
    # The procedure returns two result sets flattened; split by presence of fields
    header = None
    items = []
    for row in results:
        if "foodname" in row:
            items.append(row)
        else:
            header = row
    if not header or header.get("userid") != session.get("userID"):
        flash("Unauthorized or not found", "error")
        return redirect(url_for("index"))
    return render_template("meals/detail.html", meal=header, items=items)

@app.route("/meals/create/<int:userID>", methods=["GET","POST"])
def create_meal(userID):
    if not require_login():
        return redirect(url_for("login"))
    if session.get("userID") != userID:
        flash("Unauthorized", "error")
        return redirect(url_for("index"))
    foods = DB.call_proc("sp_list_foods")
    if request.method == "POST":
        try:
            # Create meal log
            DB.call_proc("sp_create_meal", (userID, request.form.get("mealType"), request.form.get("logTime")))
            # Get last inserted meal for the user
            last = DB.execute("SELECT meallogid FROM meal_log WHERE userid = %s ORDER BY meallogid DESC LIMIT 1", (userID,))
            mealLogID = last[0]["meallogid"]
            # Add items
            for foodID, qty in zip(request.form.getlist("foodID"), request.form.getlist("quantityInGram")):
                if foodID and qty:
                    DB.call_proc("sp_add_meal_item", (int(mealLogID), int(foodID), int(qty)))
            flash("Meal created", "success")
            return redirect(url_for("list_meals", userID=userID))
        except Exception as e:
            flash(str(e), "error")
    return render_template("meals/create.html", foods=foods, userID=userID)

@app.route("/meals/<int:mealLogID>/delete", methods=["POST"]) 
def delete_meal(mealLogID):
    try:
        DB.call_proc("sp_delete_meal", (mealLogID,))
        flash("Meal deleted", "success")
    except Exception as e:
        flash(str(e), "error")
    return redirect(request.referrer or url_for("index"))

# Foods
@app.route("/foods")
def list_foods():
    if not require_login():
        return redirect(url_for("login"))
    try:
        foods = DB.call_proc("sp_list_foods_with_allergens")
    except Exception:
        raw_foods = DB.call_proc("sp_list_foods")
        foods = [{
            "foodid": f.get("foodid") or f.get("foodID"),
            "name": f.get("name") or f.get("Name"),
            "calories": f.get("calories") or f.get("Calories"),
            "proteins": f.get("proteins") or f.get("Proteins"),
            "carbs": f.get("carbs") or f.get("Carbs"),
            "fats": f.get("fats") or f.get("Fats")
        } for f in (raw_foods or [])]
    return render_template("foods/list.html", foods=foods)

@app.route("/foods/create", methods=["GET","POST"])
def create_food():
    if request.method == "POST":
        try:
            DB.call_proc("sp_create_food", (
                request.form.get("Name"),
                int(request.form.get("Calories")),
                float(request.form.get("Proteins")),
                float(request.form.get("Carbs")),
                float(request.form.get("Fats"))
            ))
            # Add optional allergens, comma-separated
            allergens_str = request.form.get("Allergens") or ""
            allergens = [a.strip() for a in allergens_str.split(",") if a.strip()]
            if allergens:
                # Fetch the last inserted food id
                last_food = DB.execute("SELECT foodid FROM food_items ORDER BY foodid DESC LIMIT 1")
                if last_food:
                    fid = last_food[0]["foodid"]
                    for a in allergens:
                        DB.call_proc("sp_add_allergen", (int(fid), a))
            flash("Food created", "success")
            return redirect(url_for("list_foods"))
        except Exception as e:
            flash(str(e), "error")
    return render_template("foods/create.html")

# Medications
@app.route("/meds/<int:userID>")
def list_meds(userID):
    if not require_login():
        return redirect(url_for("login"))
    if session.get("userID") != userID:
        flash("Unauthorized", "error")
        return redirect(url_for("index"))
    meds = DB.call_proc("sp_list_meds", (userID,))
    return render_template("meds/list.html", meds=meds, userID=userID)

@app.route("/meds/detail/<int:medicationID>")
def med_detail(medicationID):
    if not require_login():
        return redirect(url_for("login"))
    results = DB.call_proc("sp_get_med_logs", (medicationID,))
    header = None
    logs = []
    for row in results:
        if "medname" in row:
            header = row
        else:
            logs.append(row)
    if not header or header.get("userid") != session.get("userID"):
        flash("Unauthorized or not found", "error")
        return redirect(url_for("index"))
    return render_template("meds/detail.html", med=header, logs=logs)

@app.route("/meds/create/<int:userID>", methods=["GET","POST"])
def create_med(userID):
    if request.method == "POST":
        try:
            DB.call_proc("sp_create_med", (userID, request.form.get("medName"), request.form.get("Dosage"), request.form.get("Frequency")))
            flash("Medication saved", "success")
            return redirect(url_for("list_meds", userID=userID))
        except Exception as e:
            flash(str(e), "error")
    return render_template("meds/create.html", userID=userID)

@app.route("/meds/log/<int:medicationID>", methods=["POST"]) 
def log_med(medicationID):
    try:
        taken = request.form.get("takenTime")
        # Fallback to current timestamp if empty to avoid MySQL datetime error
        if not taken or not taken.strip():
            taken = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        skipped = bool(request.form.get("isSkipped"))
        DB.call_proc("sp_log_med", (medicationID, taken, skipped))
        flash("Medication logged", "success")
    except Exception as e:
        flash(str(e), "error")
    return redirect(request.referrer or url_for("index"))

# Analytics page removed; macros are shown on the home page

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True, use_reloader=False)
