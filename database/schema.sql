-- ============================================================
-- Paluwagan Food Store Manager — Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS paluwagan_store
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE paluwagan_store;

-- Users (admin only)
CREATE TABLE IF NOT EXISTS users (
  id       BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50)  NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role     VARCHAR(20)  NOT NULL DEFAULT 'ADMIN'
);

-- Food Items
CREATE TABLE IF NOT EXISTS food_items (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)   NOT NULL,
  description VARCHAR(255),
  category    VARCHAR(50),
  price       DECIMAL(10, 2) NOT NULL,
  stock       INT            NOT NULL DEFAULT 0,
  image_url   VARCHAR(500),
  active      TINYINT(1)     NOT NULL DEFAULT 1,
  created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Paluwagan Packages
CREATE TABLE IF NOT EXISTS paluwagan_packages (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100)   NOT NULL,
  description    VARCHAR(255),
  weekly_amount  DECIMAL(10, 2) NOT NULL,
  duration_weeks INT            NOT NULL,
  active         TINYINT(1)     NOT NULL DEFAULT 1
);

-- Members
CREATE TABLE IF NOT EXISTS members (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name   VARCHAR(100) NOT NULL,
  phone       VARCHAR(20),
  address     VARCHAR(255),
  package_id  BIGINT       NOT NULL,
  start_date  DATE         NOT NULL,
  status      VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  CONSTRAINT fk_member_package FOREIGN KEY (package_id)
    REFERENCES paluwagan_packages (id)
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id      BIGINT         NOT NULL,
  week_number    INT            NOT NULL,
  amount         DECIMAL(10, 2) NOT NULL,
  paid           TINYINT(1)     NOT NULL DEFAULT 0,
  due_date       DATE,
  paid_at        DATETIME,
  receipt_number VARCHAR(50),
  CONSTRAINT fk_payment_member FOREIGN KEY (member_id)
    REFERENCES members (id)
);

-- ============================================================
-- Seed Data (optional — admin is auto-created by Spring Boot)
-- ============================================================

-- Sample packages
INSERT INTO paluwagan_packages (name, description, weekly_amount, duration_weeks, active) VALUES
  ('Basic',    'Starter paluwagan package',  200.00, 10, 1),
  ('Standard', 'Regular paluwagan package',  500.00, 12, 1),
  ('Premium',  'Premium paluwagan package', 1000.00, 16, 1);

-- Sample food items
INSERT INTO food_items (name, description, category, price, stock, active) VALUES
  ('Sinangag Rice',    'Garlic fried rice',         'Rice',    35.00, 100, 1),
  ('Adobo Chicken',    'Classic Filipino adobo',    'Viand',   85.00,  50, 1),
  ('Sinigang Pork',    'Sour tamarind soup',        'Soup',    95.00,  30, 1),
  ('Pandesal',         'Soft Filipino bread roll',  'Bread',   10.00, 200, 1),
  ('Halo-Halo',        'Mixed shaved ice dessert',  'Dessert', 65.00,  40, 1),
  ('Lumpia Shanghai',  'Crispy spring rolls',       'Snack',   45.00,  80, 1);
