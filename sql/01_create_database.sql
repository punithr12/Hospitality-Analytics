-- ============================================================
-- Hospitality Analytics Data Warehouse
-- Script: 01_create_database.sql
-- Purpose: Create the project database and required extensions
-- ============================================================

-- Create the database
CREATE DATABASE hotel_analytics;

-- Connect to the database
\connect hotel_analytics

-- Enable UUID generation extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;