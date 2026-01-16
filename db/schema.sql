-- WeFit MySQL Schema, Data, Routines, Triggers and Events

DROP DATABASE IF EXISTS wefit_db;
CREATE DATABASE wefit_db;
USE wefit_db;

-- Users
CREATE TABLE user (
  userid INT AUTO_INCREMENT PRIMARY KEY,
  firstname VARCHAR(50) NOT NULL,
  lastname VARCHAR(50) NOT NULL,
  emailid VARCHAR(100) NOT NULL UNIQUE,
  passwordhash VARCHAR(255) NOT NULL,
  createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Schedules
CREATE TABLE schedule (
  scheduleid INT AUTO_INCREMENT PRIMARY KEY,
  schedulename VARCHAR(100) NOT NULL,
  userid INT NOT NULL,
  CONSTRAINT fk_schedule_user FOREIGN KEY (userid)
    REFERENCES user(userid)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Event Categories
CREATE TABLE event_category (
  categoryid INT AUTO_INCREMENT PRIMARY KEY,
  categoryname VARCHAR(100) NOT NULL UNIQUE
);

-- Schedule Events
CREATE TABLE schedule_events (
  eventid INT AUTO_INCREMENT PRIMARY KEY,
  scheduleid INT NOT NULL,
  categoryid INT NULL,
  eventtitle VARCHAR(150) NOT NULL,
  starttime DATETIME NOT NULL,
  endtime DATETIME NOT NULL,
  description TEXT NULL,
  duration INT GENERATED ALWAYS AS (TIMESTAMPDIFF(MINUTE, starttime, endtime)) STORED,
  CONSTRAINT chk_event_time CHECK (endtime > starttime),
  CONSTRAINT fk_event_schedule FOREIGN KEY (scheduleid)
    REFERENCES schedule(scheduleid)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_event_category FOREIGN KEY (categoryid)
    REFERENCES event_category(categoryid)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- Food Items
CREATE TABLE food_items (
  foodid INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  calories INT NOT NULL DEFAULT 0,
  proteins DECIMAL(6,2) NOT NULL DEFAULT 0,
  carbs DECIMAL(6,2) NOT NULL DEFAULT 0,
  fats DECIMAL(6,2) NOT NULL DEFAULT 0
);

-- Food Allergens (1..n labels)
CREATE TABLE food_allergens (
  foodid INT NOT NULL,
  allergenname VARCHAR(100) NOT NULL,
  CONSTRAINT fk_allergen_food FOREIGN KEY (foodid)
    REFERENCES food_items(foodid)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  PRIMARY KEY (foodid, allergenname)
);

-- Meal Log
CREATE TABLE meal_log (
  meallogid INT AUTO_INCREMENT PRIMARY KEY,
  userid INT NOT NULL,
  mealtype ENUM('breakfast','lunch','dinner','snack') NOT NULL,
  logtime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_meal_user FOREIGN KEY (userid)
    REFERENCES user(userid)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Meal Items (junction between meal_log and food_items with quantity)
CREATE TABLE meal_items (
  meallogid INT NOT NULL,
  foodid INT NOT NULL,
  quantityingram INT NOT NULL CHECK (quantityingram > 0),
  CONSTRAINT fk_mealitem_meallog FOREIGN KEY (meallogid)
    REFERENCES meal_log(meallogid)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_mealitem_food FOREIGN KEY (foodid)
    REFERENCES food_items(foodid)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  PRIMARY KEY (meallogid, foodid)
);

-- Medication
CREATE TABLE medication (
  medicationid INT AUTO_INCREMENT PRIMARY KEY,
  userid INT NOT NULL,
  medname VARCHAR(150) NOT NULL,
  dosage VARCHAR(100) NOT NULL,
  frequency VARCHAR(100) NOT NULL,
  CONSTRAINT fk_med_user FOREIGN KEY (userid)
    REFERENCES user(userid)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Medication Log
CREATE TABLE medication_log (
  medlogid INT AUTO_INCREMENT PRIMARY KEY,
  medicationid INT NOT NULL,
  takentime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  isskipped BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_medlog_med FOREIGN KEY (medicationid)
    REFERENCES medication(medicationid)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_schedule_user ON schedule(userid);
CREATE INDEX idx_event_schedule ON schedule_events(scheduleid);
CREATE INDEX idx_meal_user_time ON meal_log(userid, logtime);
CREATE INDEX idx_med_user ON medication(userid);

-- Sample Data
INSERT INTO user (firstname, lastname, emailid, passwordhash) VALUES
('Priyan','Baskar','priyan@example.com','hash123'),
('Satyaa','Guruswamy','satyaa@example.com','hash456');

INSERT INTO schedule (schedulename, userid) VALUES
('Work', 1), ('School', 1), ('Personal', 2);

INSERT INTO event_category (categoryname) VALUES
('Meeting'),('Study'),('Workout');

INSERT INTO schedule_events (scheduleid, categoryid, eventtitle, starttime, endtime, description) VALUES
(1, 1, 'Sprint Planning', '2025-12-05 09:00:00', '2025-12-05 10:00:00', 'Weekly planning'),
(2, 2, 'Database Exam Prep', '2025-12-06 14:00:00', '2025-12-06 16:00:00', 'Practice questions'),
(3, 3, 'Evening Run', '2025-12-04 18:00:00', '2025-12-04 18:45:00', '5K easy');

INSERT INTO food_items (name, calories, proteins, carbs, fats) VALUES
('Chicken Breast', 165, 31.00, 0.00, 3.60),
('Brown Rice', 216, 5.00, 44.00, 1.80),
('Apple', 95, 0.50, 25.00, 0.30),
('Oatmeal', 150, 5.00, 27.00, 2.50),
('Banana', 105, 1.30, 27.00, 0.30),
('Salmon', 208, 20.00, 0.00, 13.00),
('Sweet Potato', 103, 2.00, 24.00, 0.20),
('Broccoli', 55, 3.70, 11.20, 0.60),
('Almonds (30 g)', 164, 6.00, 6.00, 14.00),
('Whole Egg', 78, 6.00, 0.60, 5.30),
('Greek Yogurt (Plain)', 100, 17.00, 6.00, 0.70),
('Peanut Butter (2 tbsp)', 190, 8.00, 7.00, 16.00),
('Quinoa', 120, 4.00, 21.00, 2.00);

INSERT INTO food_allergens (foodid, allergenname) VALUES
(1, 'None'),
(2, 'Gluten'),
(3, 'None'),
(4, 'None'),
(5, 'None'),
(6, 'None'),
(7, 'None'),
(8, 'None'),
(9, 'Nuts'),
(10, 'None'),
(11, 'Lactose'),
(12, 'Nuts'),
(13, 'None');

INSERT INTO meal_log (userid, mealtype, logtime) VALUES
(1, 'breakfast', '2025-12-04 08:00:00'),
(1, 'lunch', '2025-12-04 13:00:00'),
(2, 'dinner', '2025-12-04 19:30:00');

INSERT INTO meal_items (meallogid, foodid, quantityingram) VALUES
(1, 3, 150),
(2, 1, 200),
(2, 2, 180),
(3, 2, 160);

INSERT INTO medication (userid, medname, dosage, frequency) VALUES
(1, 'Vitamin D', '1000 IU', 'Daily'),
(2, 'Ibuprofen', '200 mg', 'As needed');

INSERT INTO medication_log (medicationid, takentime, isskipped) VALUES
(1, '2025-12-04 08:30:00', FALSE),
(2, '2025-12-04 21:00:00', TRUE);


-- Stored Functions
DELIMITER $$
CREATE FUNCTION fn_total_meal_calories(p_mealLogID INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT DEFAULT 0;
  SELECT COALESCE(SUM(F.calories * MI.quantityingram / 100),0)
    INTO total
  FROM meal_items MI
  JOIN food_items F ON F.foodid = MI.foodid
  WHERE MI.meallogid = p_mealLogID;
  RETURN total;
END $$

CREATE FUNCTION fn_event_duration_minutes(p_eventID INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE d INT;
  SELECT duration INTO d FROM schedule_events WHERE eventid = p_eventID;
  RETURN d;
END $$
DELIMITER ;

-- Stored Procedures
DELIMITER $$
CREATE PROCEDURE sp_create_user(
  IN p_firstName VARCHAR(50), IN p_lastName VARCHAR(50), IN p_emailID VARCHAR(100), IN p_passwordHash VARCHAR(255)
)
BEGIN
  IF p_firstName IS NULL OR p_lastName IS NULL OR p_emailID IS NULL OR p_passwordHash IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'All fields required';
  END IF;
  INSERT INTO user(firstname, lastname, emailid, passwordhash) VALUES(p_firstName, p_lastName, p_emailID, p_passwordHash);
END $$

CREATE PROCEDURE sp_update_user(
  IN p_userID INT, IN p_firstName VARCHAR(50), IN p_lastName VARCHAR(50)
)
BEGIN
  IF p_userID IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='userID required'; END IF;
  UPDATE user SET firstname = COALESCE(p_firstName, firstname), lastname = COALESCE(p_lastName, lastname) WHERE userid = p_userID;
END $$

CREATE PROCEDURE sp_delete_user(IN p_userID INT)
BEGIN
  DELETE FROM user WHERE userid = p_userID;
END $$

CREATE PROCEDURE sp_list_users()
BEGIN
  SELECT userid, firstname, lastname, emailid, createdat FROM user ORDER BY createdat DESC;
END $$

-- Auth helper: fetch user by email
CREATE PROCEDURE sp_get_user_by_email(IN p_email VARCHAR(100))
BEGIN
  SELECT userid AS userid, firstname AS firstname, lastname AS lastname, emailid AS emailid, passwordhash AS passwordhash
  FROM user
  WHERE emailid = p_email;
END $$

-- Schedule Procedures
CREATE PROCEDURE sp_create_schedule(IN p_userID INT, IN p_name VARCHAR(100))
BEGIN
  INSERT INTO schedule(schedulename, userid) VALUES(p_name, p_userID);
END $$

CREATE PROCEDURE sp_delete_schedule(IN p_scheduleID INT)
BEGIN
  DELETE FROM schedule WHERE scheduleid = p_scheduleID;
END $$

CREATE PROCEDURE sp_list_events_by_schedule(IN p_scheduleID INT)
BEGIN
  SELECT eventid AS eventid, eventtitle AS eventtitle, starttime AS starttime, endtime AS endtime, duration AS duration, description AS description
  FROM schedule_events
  WHERE scheduleid = p_scheduleID
  ORDER BY starttime;
END $$

-- List all schedules with user names
CREATE PROCEDURE sp_list_schedules()
BEGIN
  SELECT s.scheduleid AS scheduleid, s.schedulename AS schedulename, u.firstname AS firstname, u.lastname AS lastname
  FROM schedule s
  JOIN user u ON u.userid = s.userid
  ORDER BY s.scheduleid DESC;
END $$

-- List schedules for a specific user
CREATE PROCEDURE sp_list_schedules_by_user(IN p_userID INT)
BEGIN
  SELECT s.scheduleid AS scheduleid, s.schedulename AS schedulename
  FROM schedule s
  WHERE s.userid = p_userID
  ORDER BY s.scheduleid DESC;
END $$

-- Event Procedures
CREATE PROCEDURE sp_create_event(
  IN p_scheduleID INT, IN p_categoryID INT, IN p_title VARCHAR(150), IN p_start DATETIME, IN p_end DATETIME, IN p_desc TEXT
)
BEGIN
  IF p_end <= p_start THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='endTime must be greater than startTime'; END IF;
  INSERT INTO schedule_events(scheduleid, categoryid, eventtitle, starttime, endtime, description)
  VALUES(p_scheduleID, p_categoryID, p_title, p_start, p_end, p_desc);
END $$

CREATE PROCEDURE sp_update_event(
  IN p_eventID INT, IN p_title VARCHAR(150), IN p_start DATETIME, IN p_end DATETIME, IN p_desc TEXT
)
BEGIN
  UPDATE schedule_events
  SET eventtitle = COALESCE(p_title, eventtitle),
      starttime = COALESCE(p_start, starttime),
      endtime = COALESCE(p_end, endtime),
      description = COALESCE(p_desc, description)
  WHERE eventid = p_eventID;
END $$

CREATE PROCEDURE sp_delete_event(IN p_eventID INT)
BEGIN
  DELETE FROM schedule_events WHERE eventid = p_eventID;
END $$

-- Meal Procedures
CREATE PROCEDURE sp_create_meal(IN p_userID INT, IN p_mealType ENUM('breakfast','lunch','dinner','snack'), IN p_logTime DATETIME)
BEGIN
  INSERT INTO meal_log(userid, mealtype, logtime) VALUES(p_userID, p_mealType, COALESCE(p_logTime, CURRENT_TIMESTAMP));
END $$

CREATE PROCEDURE sp_add_meal_item(IN p_mealLogID INT, IN p_foodID INT, IN p_qty INT)
BEGIN
  INSERT INTO meal_items(meallogid, foodid, quantityingram) VALUES(p_mealLogID, p_foodID, p_qty);
END $$
 
-- Update meal header (type/time)
CREATE PROCEDURE sp_update_meal(IN p_mealLogID INT, IN p_type VARCHAR(30), IN p_time DATETIME)
BEGIN
  UPDATE meal_log SET mealtype = p_type, logtime = p_time WHERE meallogid = p_mealLogID;
END $$

-- Clear all items for a meal (used before re-adding)
CREATE PROCEDURE sp_clear_meal_items(IN p_mealLogID INT)
BEGIN
  DELETE FROM meal_items WHERE meallogid = p_mealLogID;
END $$

CREATE PROCEDURE sp_delete_meal(IN p_mealLogID INT)
BEGIN
  DELETE FROM meal_log WHERE meallogid = p_mealLogID;
END $$

CREATE PROCEDURE sp_list_meals(IN p_userID INT)
BEGIN
  SELECT ML.meallogid AS meallogid, ML.mealtype AS mealtype, ML.logtime AS logtime,
         fn_total_meal_calories(ML.meallogid) AS totalcalories
  FROM meal_log ML
  WHERE ML.userid = p_userID
  ORDER BY ML.logtime DESC;
END $$

-- Meal detail with items
CREATE PROCEDURE sp_get_meal_detail(IN p_mealLogID INT)
BEGIN
  SELECT ML.meallogid AS meallogid, ML.userid AS userid, ML.mealtype AS mealtype, ML.logtime AS logtime,
    fn_total_meal_calories(ML.meallogid) AS totalcalories
  FROM meal_log ML
  WHERE ML.meallogid = p_mealLogID;

  SELECT MI.foodid AS foodid, F.name AS foodname, MI.quantityingram AS quantityingram,
    F.calories AS calories, F.proteins AS proteins, F.carbs AS carbs, F.fats AS fats
  FROM meal_items MI
  JOIN food_items F ON F.foodid = MI.foodid
  WHERE MI.meallogid = p_mealLogID;
END $$

-- Recent meals across users (for home page)
CREATE PROCEDURE sp_recent_meals(IN p_limit INT)
BEGIN
  IF p_limit IS NULL OR p_limit <= 0 THEN
    SET p_limit = 10;
  END IF;
  SELECT ML.meallogid, ML.userid, ML.mealtype, ML.logtime
  FROM meal_log ML
  ORDER BY ML.logtime DESC
  LIMIT p_limit;
END $$

-- Recent meals with items for a user (for dashboard)
CREATE PROCEDURE sp_list_recent_meal_items_by_user(IN p_userID INT, IN p_limit INT)
BEGIN
  IF p_limit IS NULL OR p_limit <= 0 THEN
    SET p_limit = 5;
  END IF;
  -- Header rows: recent meals with total calories
    SELECT ML.meallogid AS meallogid, ML.userid AS userid, ML.mealtype AS mealtype, ML.logtime AS logtime,
      fn_total_meal_calories(ML.meallogid) AS totalcalories
  FROM meal_log ML
  WHERE ML.userid = p_userID
  ORDER BY ML.logtime DESC
  LIMIT p_limit;

  -- Item rows: foods for those meals (avoiding LIMIT in subquery by using a temp table)
  CREATE TEMPORARY TABLE IF NOT EXISTS recent_meals (
    meallogid INT PRIMARY KEY
  );
  DELETE FROM recent_meals;
  INSERT INTO recent_meals (meallogid)
  SELECT ML2.meallogid
  FROM meal_log ML2
  WHERE ML2.userid = p_userID
  ORDER BY ML2.logtime DESC
  LIMIT p_limit;

    SELECT MI.meallogid AS meallogid, MI.foodid AS foodid, F.name AS foodname, MI.quantityingram AS quantityingram,
      F.calories AS calories, F.proteins AS proteins, F.carbs AS carbs, F.fats AS fats
  FROM meal_items MI
  JOIN food_items F ON F.foodid = MI.foodid
  JOIN recent_meals RM ON RM.meallogid = MI.meallogid
  ORDER BY MI.meallogid, MI.foodid;

  DROP TEMPORARY TABLE IF EXISTS recent_meals;
END $$

-- Food Procedures
CREATE PROCEDURE sp_create_food(IN p_name VARCHAR(150), IN p_cal INT, IN p_pro DECIMAL(6,2), IN p_carbs DECIMAL(6,2), IN p_fats DECIMAL(6,2))
BEGIN
  INSERT INTO food_items(name, calories, proteins, carbs, fats) VALUES(p_name, p_cal, p_pro, p_carbs, p_fats);
END $$

CREATE PROCEDURE sp_add_allergen(IN p_foodID INT, IN p_allergen VARCHAR(100))
BEGIN
  INSERT INTO food_allergens(foodid, allergenname) VALUES(p_foodID, p_allergen);
END $$

-- List foods
CREATE PROCEDURE sp_list_foods()
BEGIN
  SELECT foodid, name, calories, proteins, carbs, fats
  FROM food_items
  ORDER BY name;
END $$

-- Foods with aggregated allergens list for UI
CREATE PROCEDURE sp_list_foods_with_allergens()
BEGIN
  SELECT F.foodid AS foodid, F.name AS name, F.calories AS calories, F.proteins AS proteins, F.carbs AS carbs, F.fats AS fats,
         GROUP_CONCAT(FA.allergenname ORDER BY FA.allergenname SEPARATOR ', ') AS allergens
  FROM food_items F
  LEFT JOIN food_allergens FA ON FA.foodid = F.foodid
  GROUP BY F.foodid, F.name, F.calories, F.proteins, F.carbs, F.fats
  ORDER BY F.name;
END $$

-- Medication Procedures
CREATE PROCEDURE sp_create_med(IN p_userID INT, IN p_name VARCHAR(150), IN p_dosage VARCHAR(100), IN p_freq VARCHAR(100))
BEGIN
  INSERT INTO medication(userid, medname, dosage, frequency) VALUES(p_userID, p_name, p_dosage, p_freq);
END $$

CREATE PROCEDURE sp_log_med(IN p_medicationID INT, IN p_takenTime DATETIME, IN p_isSkipped BOOLEAN)
BEGIN
  INSERT INTO medication_log(medicationid, takentime, isskipped) VALUES(p_medicationID, COALESCE(p_takenTime, CURRENT_TIMESTAMP), COALESCE(p_isSkipped, FALSE));
END $$

CREATE PROCEDURE sp_list_meds(IN p_userID INT)
BEGIN
  SELECT m.medicationid AS medicationid, m.medname AS medname, m.dosage AS dosage, m.frequency AS frequency,
         (SELECT COUNT(*) FROM medication_log ml WHERE ml.medicationid = m.medicationid AND ml.isskipped = 0) AS dosestaken,
         (SELECT COUNT(*) FROM medication_log ml WHERE ml.medicationid = m.medicationid AND ml.isskipped = 1) AS dosesskipped
  FROM medication m WHERE m.userid = p_userID;
END $$

-- Medication logs for a medication
CREATE PROCEDURE sp_get_med_logs(IN p_medicationID INT)
BEGIN
  SELECT m.medicationid AS medicationid, m.userid AS userid, m.medname AS medname, m.dosage AS dosage, m.frequency AS frequency
  FROM medication m
  WHERE m.medicationid = p_medicationID;

  SELECT medlogid AS medlogid, takentime AS takentime, isskipped AS isskipped
  FROM medication_log
  WHERE medicationid = p_medicationID
  ORDER BY takentime DESC;
END $$

-- Recent medications (for home page)
CREATE PROCEDURE sp_recent_meds(IN p_limit INT)
BEGIN
  IF p_limit IS NULL OR p_limit <= 0 THEN
    SET p_limit = 10;
  END IF;
  SELECT medicationid, userid, medname, dosage, frequency
  FROM medication
  ORDER BY medicationid DESC
  LIMIT p_limit;
END $$

-- Analytical queries
CREATE PROCEDURE sp_user_daily_macros(IN p_userID INT, IN p_date DATE)
BEGIN
  SELECT 
    COALESCE(SUM(F.proteins * MI.quantityingram / 100),0) AS protein_g,
    COALESCE(SUM(F.carbs * MI.quantityingram / 100),0) AS carbs_g,
    COALESCE(SUM(F.fats * MI.quantityingram / 100),0) AS fats_g,
    COALESCE(SUM(F.calories * MI.quantityingram / 100),0) AS calories
  FROM meal_log ML
  JOIN meal_items MI ON MI.meallogid = ML.meallogid
  JOIN food_items F ON F.foodid = MI.foodid
  WHERE ML.userid = p_userID AND DATE(ML.logtime) = p_date;
END $$
DELIMITER ;

-- Triggers
DELIMITER $$
CREATE TRIGGER trg_validate_meal_item BEFORE INSERT ON meal_items
FOR EACH ROW
BEGIN
  IF NEW.quantityingram <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be positive';
  END IF;
END $$

CREATE TRIGGER trg_event_time_update BEFORE UPDATE ON schedule_events
FOR EACH ROW
BEGIN
  IF NEW.endtime <= NEW.starttime THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid event time';
  END IF;
END $$
DELIMITER ;

-- Event Scheduler 
CREATE TABLE user_daily_summary (
  summaryid INT AUTO_INCREMENT PRIMARY KEY,
  userid INT NOT NULL,
  summarydate DATE NOT NULL,
  totalcalories INT NOT NULL DEFAULT 0,
  createdat TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_summary_user FOREIGN KEY (userid)
    REFERENCES user(userid)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT uq_user_date UNIQUE(userid, summarydate)
) ENGINE=InnoDB;

DELIMITER $$
CREATE EVENT IF NOT EXISTS ev_nightly_calorie_summary
ON SCHEDULE EVERY 1 DAY STARTS '2025-12-04 23:59:00'
DO
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_userID INT;
  DECLARE cur CURSOR FOR SELECT userid FROM user;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_userID;
    IF done = 1 THEN LEAVE read_loop; END IF;
    INSERT INTO user_daily_summary(userid, summarydate, totalcalories)
    SELECT v_userID, CURDATE(), COALESCE(SUM(F.calories * MI.quantityingram / 100),0)
    FROM meal_log ML
    LEFT JOIN meal_items MI ON MI.meallogid = ML.meallogid
    LEFT JOIN food_items F ON F.foodid = MI.foodid
    WHERE ML.userid = v_userID AND DATE(ML.logtime) = CURDATE()
    ON DUPLICATE KEY UPDATE totalcalories = VALUES(totalcalories);
  END LOOP;
  CLOSE cur;
END $$
DELIMITER ;

