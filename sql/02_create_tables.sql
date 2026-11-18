
-- ==========================================
-- HOSPITALITY ANALYTICS
-- DATABASE SCHEMA
-- ==========================================

-- 1. HOTELS
CREATE TABLE IF NOT EXISTS hotels (
    hotel_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    star_rating NUMERIC(2,1)
        CHECK (star_rating BETWEEN 1 AND 5),
    opened_on DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. ROOMS
CREATE TABLE IF NOT EXISTS rooms (
    room_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hotel_id UUID NOT NULL REFERENCES hotels(hotel_id),
    room_number VARCHAR(20) NOT NULL,
    room_type VARCHAR(50) NOT NULL,
    max_occupancy INTEGER NOT NULL CHECK (max_occupancy > 0),
    base_rate NUMERIC(12,2) NOT NULL CHECK (base_rate >= 0),
    room_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (room_status IN ('ACTIVE', 'MAINTENANCE', 'INACTIVE')),
    UNIQUE (hotel_id, room_number)
);

-- 3. GUESTS
CREATE TABLE IF NOT EXISTS guests (
    guest_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    gender VARCHAR(20),
    date_of_birth DATE,
    home_city VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. EMPLOYEES
CREATE TABLE IF NOT EXISTS employees (
    employee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    gender VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. RESERVATIONS
-- Grain: One row per room reservation.

CREATE TABLE IF NOT EXISTS reservations (
    reservation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID NOT NULL REFERENCES guests(guest_id),
    room_id UUID NOT NULL REFERENCES rooms(room_id),
    booking_date DATE NOT NULL,
    planned_checkin DATE NOT NULL,
    planned_checkout DATE NOT NULL,
    booking_channel VARCHAR(50),
    quoted_nightly_rate NUMERIC(12,2) NOT NULL
        CHECK (quoted_nightly_rate >= 0),
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('CONFIRMED', 'CANCELLED', 'NO_SHOW', 'COMPLETED')),
    CHECK (planned_checkout > planned_checkin),
    CHECK (booking_date <= planned_checkin)
);

-- 6. STAYS
-- Grain: One row per actual guest stay.

CREATE TABLE IF NOT EXISTS stays (
    stay_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id UUID NOT NULL UNIQUE
        REFERENCES reservations(reservation_id),
    room_id UUID NOT NULL REFERENCES rooms(room_id),
    actual_checkin DATE NOT NULL,
    actual_checkout DATE,
    stay_status VARCHAR(20) NOT NULL
        CHECK (stay_status IN ('IN_HOUSE', 'COMPLETED')),
    CHECK (
        actual_checkout IS NULL
        OR actual_checkout > actual_checkin
    ),
    CHECK (
        (stay_status = 'IN_HOUSE' AND actual_checkout IS NULL)
        OR
        (stay_status = 'COMPLETED' AND actual_checkout IS NOT NULL)
    ),
    UNIQUE (stay_id, room_id)
);

-- 7. ROOM NIGHTS
-- Grain: One row per physical room per calendar night.
-- Includes occupied and unoccupied available rooms.

CREATE TABLE IF NOT EXISTS room_nights (
    room_night_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(room_id),
    stay_id UUID,
    business_date DATE NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    is_occupied BOOLEAN NOT NULL DEFAULT FALSE,
    room_revenue NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (room_revenue >= 0),

    UNIQUE (room_id, business_date),

    FOREIGN KEY (stay_id, room_id)
        REFERENCES stays(stay_id, room_id),

    CHECK (NOT is_occupied OR is_available),

    CHECK (
        (is_occupied AND stay_id IS NOT NULL)
        OR
        (NOT is_occupied AND stay_id IS NULL)
    ),

    CHECK (is_occupied OR room_revenue = 0)
);

-- 8. GUEST FEEDBACK
-- Grain: One row per guest feedback submission.

CREATE TABLE IF NOT EXISTS guest_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stay_id UUID NOT NULL REFERENCES stays(stay_id),
    rating NUMERIC(2,1) NOT NULL
        CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,
    feedback_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 9. EMPLOYEE HISTORY
-- Grain: One row per employment period.

CREATE TABLE IF NOT EXISTS employee_history (
    employment_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(employee_id),
    hotel_id UUID NOT NULL REFERENCES hotels(hotel_id),
    position VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    employment_type VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,
    exit_type VARCHAR(30),
    exit_reason TEXT,

    CHECK (end_date IS NULL OR end_date >= start_date),

    CHECK (
        (end_date IS NULL AND exit_type IS NULL)
        OR
        (end_date IS NOT NULL AND exit_type IS NOT NULL)
    ),

    CHECK (
        exit_type IS NULL OR
        exit_type IN (
            'RESIGNATION',
            'TERMINATION',
            'RETIREMENT',
            'TRANSFER',
            'CONTRACT_END',
            'OTHER'
        )
    )
);

-- ==========================================
-- INDEXES
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_rooms_hotel
    ON rooms(hotel_id);

CREATE INDEX IF NOT EXISTS idx_reservations_guest
    ON reservations(guest_id);

CREATE INDEX IF NOT EXISTS idx_reservations_room
    ON reservations(room_id);

CREATE INDEX IF NOT EXISTS idx_reservations_booking_date
    ON reservations(booking_date);

CREATE INDEX IF NOT EXISTS idx_stays_actual_dates
    ON stays(actual_checkin, actual_checkout);

CREATE INDEX IF NOT EXISTS idx_room_nights_date
    ON room_nights(business_date);

CREATE INDEX IF NOT EXISTS idx_feedback_stay
    ON guest_feedback(stay_id);

CREATE INDEX IF NOT EXISTS idx_employee_history_hotel
    ON employee_history(hotel_id, start_date, end_date);

-- ==========================================
-- END OF SCHEMA
-- ==========================================
