-- ============================================================
-- Hospitality Analytics Data Warehouse
-- Script: 03_data_validation.sql
-- Purpose: Data quality and integrity validation
-- ============================================================


-- ============================================================
-- 1. RECORD COUNT VALIDATION
-- ============================================================

SELECT 'hotels' AS table_name, COUNT(*) AS total_records FROM hotels
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'guests', COUNT(*) FROM guests
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'stays', COUNT(*) FROM stays
UNION ALL
SELECT 'room_nights', COUNT(*) FROM room_nights
UNION ALL
SELECT 'guest_feedback', COUNT(*) FROM guest_feedback
UNION ALL
SELECT 'employee_history', COUNT(*) FROM employee_history;


-- ============================================================
-- 2. PRIMARY KEY DUPLICATE VALIDATION
-- ============================================================

-- Hotels
SELECT hotel_id, COUNT(*)
FROM hotels
GROUP BY hotel_id
HAVING COUNT(*) > 1;

-- Rooms
SELECT room_id, COUNT(*)
FROM rooms
GROUP BY room_id
HAVING COUNT(*) > 1;

-- Guests
SELECT guest_id, COUNT(*)
FROM guests
GROUP BY guest_id
HAVING COUNT(*) > 1;

-- Employees
SELECT employee_id, COUNT(*)
FROM employees
GROUP BY employee_id
HAVING COUNT(*) > 1;

-- Reservations
SELECT reservation_id, COUNT(*)
FROM reservations
GROUP BY reservation_id
HAVING COUNT(*) > 1;

-- Stays
SELECT stay_id, COUNT(*)
FROM stays
GROUP BY stay_id
HAVING COUNT(*) > 1;

-- Room Nights
SELECT room_night_id, COUNT(*)
FROM room_nights
GROUP BY room_night_id
HAVING COUNT(*) > 1;

-- Guest Feedback
SELECT feedback_id, COUNT(*)
FROM guest_feedback
GROUP BY feedback_id
HAVING COUNT(*) > 1;

-- Employee History
SELECT employee_history_id, COUNT(*)
FROM employee_history
GROUP BY employee_history_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. FOREIGN KEY VALIDATION
-- ============================================================

-- Rooms without a valid hotel
SELECT r.*
FROM rooms r
LEFT JOIN hotels h
    ON r.hotel_id = h.hotel_id
WHERE h.hotel_id IS NULL;


-- Reservations without valid guests
SELECT r.*
FROM reservations r
LEFT JOIN guests g
    ON r.guest_id = g.guest_id
WHERE g.guest_id IS NULL;


-- Reservations without valid rooms
SELECT r.*
FROM reservations r
LEFT JOIN rooms rm
    ON r.room_id = rm.room_id
WHERE rm.room_id IS NULL;


-- Stays without valid reservations
SELECT s.*
FROM stays s
LEFT JOIN reservations r
    ON s.reservation_id = r.reservation_id
WHERE r.reservation_id IS NULL;


-- Guest feedback without valid stays
SELECT gf.*
FROM guest_feedback gf
LEFT JOIN stays s
    ON gf.stay_id = s.stay_id
WHERE s.stay_id IS NULL;


-- Employee history without valid employees
SELECT eh.*
FROM employee_history eh
LEFT JOIN employees e
    ON eh.employee_id = e.employee_id
WHERE e.employee_id IS NULL;


-- ============================================================
-- 4. RESERVATION VALIDATION
-- ============================================================

-- Invalid reservation date ranges
SELECT *
FROM reservations
WHERE check_out_date <= check_in_date;


-- Negative or zero quoted room rates
SELECT *
FROM reservations
WHERE quoted_nightly_rate <= 0;


-- Reservations with missing required values
SELECT *
FROM reservations
WHERE guest_id IS NULL
   OR room_id IS NULL
   OR check_in_date IS NULL
   OR check_out_date IS NULL;


-- Reservation status distribution
SELECT
    reservation_status,
    COUNT(*) AS total_reservations
FROM reservations
GROUP BY reservation_status
ORDER BY total_reservations DESC;


-- ============================================================
-- 5. STAY VALIDATION
-- ============================================================

-- Stays with invalid check-in/check-out dates
SELECT *
FROM stays
WHERE actual_checkout <= actual_check_in;


-- Stays without a reservation
SELECT s.*
FROM stays s
LEFT JOIN reservations r
    ON s.reservation_id = r.reservation_id
WHERE r.reservation_id IS NULL;


-- Multiple stays associated with the same reservation
SELECT
    reservation_id,
    COUNT(*) AS stay_count
FROM stays
GROUP BY reservation_id
HAVING COUNT(*) > 1;


-- Completed reservations without a corresponding stay
SELECT r.*
FROM reservations r
LEFT JOIN stays s
    ON r.reservation_id = s.reservation_id
WHERE r.reservation_status = 'COMPLETED'
  AND s.stay_id IS NULL;


-- ============================================================
-- 6. ROOM NIGHT VALIDATION
-- ============================================================

-- Occupied rooms must be available
SELECT *
FROM room_nights
WHERE is_occupied = TRUE
  AND is_available = FALSE;


-- Occupied room nights must have a stay ID
SELECT *
FROM room_nights
WHERE is_occupied = TRUE
  AND stay_id IS NULL;


-- Unoccupied room nights should not have a stay ID
SELECT *
FROM room_nights
WHERE is_occupied = FALSE
  AND stay_id IS NOT NULL;


-- Unoccupied room nights should have zero revenue
SELECT *
FROM room_nights
WHERE is_occupied = FALSE
  AND room_revenue <> 0;


-- Negative room revenue
SELECT *
FROM room_nights
WHERE room_revenue < 0;


-- Room nights with invalid hotel IDs
SELECT rn.*
FROM room_nights rn
LEFT JOIN hotels h
    ON rn.hotel_id = h.hotel_id
WHERE h.hotel_id IS NULL;


-- Room nights with invalid room IDs
SELECT rn.*
FROM room_nights rn
LEFT JOIN rooms r
    ON rn.room_id = r.room_id
WHERE r.room_id IS NULL;


-- Room nights with invalid stay IDs
SELECT rn.*
FROM room_nights rn
LEFT JOIN stays s
    ON rn.stay_id = s.stay_id
WHERE rn.stay_id IS NOT NULL
  AND s.stay_id IS NULL;


-- Duplicate room/date combinations
SELECT
    room_id,
    date,
    COUNT(*) AS record_count
FROM room_nights
GROUP BY room_id, date
HAVING COUNT(*) > 1;


-- Room night summary
SELECT
    COUNT(*) AS total_room_nights,
    SUM(CASE WHEN is_available THEN 1 ELSE 0 END)
        AS available_room_nights,
    SUM(CASE WHEN is_occupied THEN 1 ELSE 0 END)
        AS occupied_room_nights,
    SUM(CASE WHEN is_available AND NOT is_occupied THEN 1 ELSE 0 END)
        AS available_unoccupied_room_nights,
    SUM(CASE WHEN NOT is_available THEN 1 ELSE 0 END)
        AS unavailable_room_nights,
    SUM(room_revenue) AS total_room_revenue,
    ROUND(
        SUM(CASE WHEN is_occupied THEN 1 ELSE 0 END)::NUMERIC
        /
        NULLIF(SUM(CASE WHEN is_available THEN 1 ELSE 0 END), 0)
        * 100,
        2
    ) AS occupancy_rate
FROM room_nights;


-- ============================================================
-- 7. GUEST FEEDBACK VALIDATION
-- ============================================================

-- Ratings outside the valid range
SELECT *
FROM guest_feedback
WHERE rating < 1
   OR rating > 5;


-- Missing ratings
SELECT *
FROM guest_feedback
WHERE rating IS NULL;


-- Feedback without a valid stay
SELECT gf.*
FROM guest_feedback gf
LEFT JOIN stays s
    ON gf.stay_id = s.stay_id
WHERE s.stay_id IS NULL;


-- Feedback rating distribution
SELECT
    rating,
    COUNT(*) AS feedback_count
FROM guest_feedback
GROUP BY rating
ORDER BY rating;


-- Overall guest satisfaction
SELECT
    COUNT(*) AS total_feedback,
    ROUND(AVG(rating), 2) AS average_rating
FROM guest_feedback;


-- ============================================================
-- 8. EMPLOYEE HISTORY VALIDATION
-- ============================================================

-- Invalid employment date ranges
SELECT *
FROM employee_history
WHERE end_date IS NOT NULL
  AND end_date < start_date;


-- Employee history records without valid employees
SELECT eh.*
FROM employee_history eh
LEFT JOIN employees e
    ON eh.employee_id = e.employee_id
WHERE e.employee_id IS NULL;


-- Employees with multiple history records
SELECT
    employee_id,
    COUNT(*) AS history_records
FROM employee_history
GROUP BY employee_id
HAVING COUNT(*) > 1;


-- Employee history summary
SELECT
    COUNT(*) AS total_history_records,
    COUNT(*) FILTER (WHERE end_date IS NULL)
        AS active_records,
    COUNT(*) FILTER (WHERE end_date IS NOT NULL)
        AS ended_records
FROM employee_history;


-- ============================================================
-- 9. HOTEL AND ROOM VALIDATION
-- ============================================================

-- Rooms without a hotel
SELECT r.*
FROM rooms r
LEFT JOIN hotels h
    ON r.hotel_id = h.hotel_id
WHERE h.hotel_id IS NULL;


-- Room status distribution
SELECT
    room_status,
    COUNT(*) AS total_rooms
FROM rooms
GROUP BY room_status
ORDER BY total_rooms DESC;


-- Room type distribution
SELECT
    room_type,
    COUNT(*) AS total_rooms
FROM rooms
GROUP BY room_type
ORDER BY total_rooms DESC;


-- Hotel inventory summary
SELECT
    h.hotel_id,
    h.hotel_name,
    COUNT(r.room_id) AS total_rooms
FROM hotels h
LEFT JOIN rooms r
    ON h.hotel_id = r.hotel_id
GROUP BY h.hotel_id, h.hotel_name
ORDER BY total_rooms DESC;


-- ============================================================
-- 10. DATA QUALITY SUMMARY
-- ============================================================

-- Null checks for important columns

SELECT
    'reservations' AS table_name,
    COUNT(*) FILTER (WHERE reservation_id IS NULL)
        AS null_reservation_ids,
    COUNT(*) FILTER (WHERE guest_id IS NULL)
        AS null_guest_ids,
    COUNT(*) FILTER (WHERE room_id IS NULL)
        AS null_room_ids
FROM reservations

UNION ALL

SELECT
    'stays',
    COUNT(*) FILTER (WHERE stay_id IS NULL),
    COUNT(*) FILTER (WHERE reservation_id IS NULL),
    COUNT(*) FILTER (WHERE actual_check_in IS NULL)
FROM stays

UNION ALL

SELECT
    'room_nights',
    COUNT(*) FILTER (WHERE room_night_id IS NULL),
    COUNT(*) FILTER (WHERE room_id IS NULL),
    COUNT(*) FILTER (WHERE date IS NULL)
FROM room_nights

UNION ALL

SELECT
    'guest_feedback',
    COUNT(*) FILTER (WHERE feedback_id IS NULL),
    COUNT(*) FILTER (WHERE stay_id IS NULL),
    COUNT(*) FILTER (WHERE rating IS NULL)
FROM guest_feedback;


