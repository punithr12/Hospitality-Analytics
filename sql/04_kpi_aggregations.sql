
-- ============================================================
-- GOLD TABLE 1: MONTHLY HOTEL PERFORMANCE
-- KPIs: Occupancy Rate, ADR, RevPAR
-- ============================================================

DROP TABLE IF EXISTS gold_monthly_hotel_performance;

CREATE TABLE gold_monthly_hotel_performance AS

SELECT
    h.hotel_id,
    h.hotel_name,
    h.city,
    h.state,

    DATE_TRUNC('month', rn.business_date)::DATE AS month_start,

    COUNT(*) FILTER (
        WHERE rn.is_available = TRUE
    ) AS available_room_nights,

    COUNT(*) FILTER (
        WHERE rn.is_occupied = TRUE
    ) AS occupied_room_nights,

    ROUND(SUM(rn.room_revenue), 2) AS room_revenue,

    -- Occupancy Rate
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE rn.is_occupied = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE rn.is_available = TRUE
            ), 0
        ),
        2
    ) AS occupancy_rate,

    -- Average Daily Rate
    ROUND(
        SUM(rn.room_revenue)
        / NULLIF(
            COUNT(*) FILTER (
                WHERE rn.is_occupied = TRUE
            ), 0
        ),
        2
    ) AS adr,

    -- Revenue Per Available Room
    ROUND(
        SUM(rn.room_revenue)
        / NULLIF(
            COUNT(*) FILTER (
                WHERE rn.is_available = TRUE
            ), 0
        ),
        2
    ) AS revpar

FROM room_nights rn

JOIN rooms r
    ON rn.room_id = r.room_id

JOIN hotels h
    ON r.hotel_id = h.hotel_id

GROUP BY
    h.hotel_id,
    h.hotel_name,
    h.city,
    h.state,
    DATE_TRUNC('month', rn.business_date);

-- ============================================================
-- VALIDATION
-- ============================================================

SELECT *
FROM gold_monthly_hotel_performance
ORDER BY month_start, hotel_name
LIMIT 20;


-- ============================================================
-- GOLD TABLE 2: MONTHLY GUEST SATISFACTION
-- ============================================================

DROP TABLE IF EXISTS gold_monthly_guest_satisfaction;

CREATE TABLE gold_monthly_guest_satisfaction AS

SELECT
    h.hotel_id,
    h.hotel_name,
    h.city,

    DATE_TRUNC(
    'month',
    s.actual_checkout - INTERVAL '1 day'
)::DATE AS month_start,

    COUNT(gf.feedback_id) AS total_feedback,

    ROUND(AVG(gf.rating), 2) AS avg_guest_rating,

    COUNT(*) FILTER (
        WHERE gf.rating = 5
    ) AS five_star_feedback,

    COUNT(*) FILTER (
        WHERE gf.rating <= 2
    ) AS low_rating_feedback,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE gf.rating >= 4
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS positive_feedback_percentage

FROM guest_feedback gf

JOIN stays s
    ON gf.stay_id = s.stay_id

JOIN rooms r
    ON s.room_id = r.room_id

JOIN hotels h
    ON r.hotel_id = h.hotel_id

GROUP BY
    h.hotel_id,
    h.hotel_name,
    h.city,
    DATE_TRUNC(
    'month',
    s.actual_checkout - INTERVAL '1 day'
);

-- ============================================================
-- VALIDATION
-- ============================================================

SELECT *
FROM gold_monthly_guest_satisfaction
ORDER BY month_start, hotel_name
LIMIT 20;



-- ============================================================
-- GOLD TABLE 3: MONTHLY EMPLOYEE TURNOVER
-- KPI: Employee Turnover Rate
-- Internal transfers are excluded from employee exits.
-- ============================================================

DROP TABLE IF EXISTS gold_monthly_employee_turnover;

CREATE TABLE gold_monthly_employee_turnover AS

WITH months AS (

    SELECT
        generate_series(
            DATE '2021-01-01',
            DATE '2025-12-01',
            INTERVAL '1 month'
        )::DATE AS month_start

),

hotel_months AS (

    SELECT
        h.hotel_id,
        h.hotel_name,
        h.city,
        m.month_start
    FROM hotels h
    CROSS JOIN months m

),

headcounts AS (

    SELECT
        hm.hotel_id,
        hm.month_start,

        -- Employees active at the beginning of the month
        COUNT(DISTINCT eh.employee_id) FILTER (
            WHERE eh.start_date <= hm.month_start
              AND (
                  eh.end_date IS NULL
                  OR eh.end_date >= hm.month_start
              )
        ) AS opening_headcount,

        -- Employees active at the end of the month
        COUNT(DISTINCT eh.employee_id) FILTER (
            WHERE eh.start_date <=
                (hm.month_start + INTERVAL '1 month - 1 day')::DATE
              AND (
                  eh.end_date IS NULL
                  OR eh.end_date >=
                     (hm.month_start + INTERVAL '1 month - 1 day')::DATE
              )
        ) AS closing_headcount

    FROM hotel_months hm

    LEFT JOIN employee_history eh
        ON hm.hotel_id = eh.hotel_id

    GROUP BY
        hm.hotel_id,
        hm.month_start

),

monthly_exits AS (

    SELECT
        hotel_id,
        DATE_TRUNC('month', end_date)::DATE AS month_start,

        COUNT(DISTINCT employee_id) FILTER (
            WHERE exit_type <> 'TRANSFER'
        ) AS employee_exits,

        COUNT(DISTINCT employee_id) FILTER (
            WHERE exit_type = 'TRANSFER'
        ) AS internal_transfers

    FROM employee_history

    WHERE end_date >= DATE '2021-01-01'
      AND end_date < DATE '2026-01-01'

    GROUP BY
        hotel_id,
        DATE_TRUNC('month', end_date)::DATE

)

SELECT
    hm.hotel_id,
    hm.hotel_name,
    hm.city,
    hm.month_start,

    hc.opening_headcount,
    hc.closing_headcount,

    ROUND(
        (hc.opening_headcount + hc.closing_headcount) / 2.0,
        2
    ) AS average_headcount,

    COALESCE(me.employee_exits, 0) AS employee_exits,

    COALESCE(me.internal_transfers, 0) AS internal_transfers,

    -- Employee Turnover Rate
    COALESCE(
        ROUND(
            100.0 * COALESCE(me.employee_exits, 0)
            / NULLIF(
                (hc.opening_headcount + hc.closing_headcount) / 2.0,
                0
            ),
            2
        ),
        0
    ) AS employee_turnover_rate

FROM hotel_months hm

JOIN headcounts hc
    ON hm.hotel_id = hc.hotel_id
    AND hm.month_start = hc.month_start

LEFT JOIN monthly_exits me
    ON hm.hotel_id = me.hotel_id
    AND hm.month_start = me.month_start;


-- ============================================================
-- VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT hotel_id) AS hotels,
    MIN(month_start) AS first_month,
    MAX(month_start) AS last_month,
    SUM(employee_exits) AS total_employee_exits,
    SUM(internal_transfers) AS total_internal_transfers,
    ROUND(AVG(employee_turnover_rate), 2) AS avg_turnover_rate
FROM gold_monthly_employee_turnover;


-- ============================================================
-- DASHBOARD VIEW: UNIFIED MONTHLY HOTEL KPIs
-- ============================================================

CREATE OR REPLACE VIEW vw_hotel_monthly_dashboard AS

SELECT
    hp.hotel_id,
    hp.hotel_name,
    hp.city,
    hp.state,
    hp.month_start,

    -- Hotel Performance
    hp.available_room_nights,
    hp.occupied_room_nights,
    hp.room_revenue,
    hp.occupancy_rate,
    hp.adr,
    hp.revpar,

    -- Guest Satisfaction
    gs.total_feedback,
    gs.avg_guest_rating,
    gs.five_star_feedback,
    gs.low_rating_feedback,
    gs.positive_feedback_percentage,

    -- Employee Turnover
    et.opening_headcount,
    et.closing_headcount,
    et.average_headcount,
    et.employee_exits,
    et.internal_transfers,
    et.employee_turnover_rate

FROM gold_monthly_hotel_performance hp

JOIN gold_monthly_guest_satisfaction gs
    ON hp.hotel_id = gs.hotel_id
    AND hp.month_start = gs.month_start

JOIN gold_monthly_employee_turnover et
    ON hp.hotel_id = et.hotel_id
    AND hp.month_start = et.month_start;
