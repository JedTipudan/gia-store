# 🏪 Paluwagan Food Store Manager

A full-stack MVP for managing a Filipino food store with a built-in Paluwagan (rotating savings) system.

---

## 📁 Project Structure

```
Gia Store/
├── backend/          # Spring Boot (Java 17)
├── frontend/         # React 18
└── database/         # MySQL schema
```

---

## ⚙️ Prerequisites

| Tool        | Version  |
|-------------|----------|
| Java        | 17+      |
| Maven       | 3.8+     |
| Node.js     | 18+      |
| MySQL       | 8.0+     |

---

## 🗄️ Database Setup

```sql
-- 1. Open MySQL client
mysql -u root -p

-- 2. Run the schema
source /path/to/database/schema.sql
```

Or import via MySQL Workbench: File → Run SQL Script → select `database/schema.sql`

---

## 🚀 Backend Setup (Spring Boot)

### 1. Configure database credentials

Edit `backend/src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/paluwagan_store?useSSL=false&serverTimezone=Asia/Manila&allowPublicKeyRetrieval=true
spring.datasource.username=root
spring.datasource.password=YOUR_MYSQL_PASSWORD
```

### 2. Run the backend

```bash
cd backend
mvn spring-boot:run
```

The API starts at **http://localhost:8080**

> On first run, a default admin is auto-created: `admin` / `admin123`

---

## 💻 Frontend Setup (React)

```bash
cd frontend
npm install
npm start
```

The app opens at **http://localhost:3000**

---

## 🔑 Default Login

| Field    | Value    |
|----------|----------|
| Username | admin    |
| Password | admin123 |

---

## 📡 API Endpoints

### Auth
| Method | Endpoint         | Description   |
|--------|-----------------|---------------|
| POST   | /api/auth/login | Login → JWT   |

### Food Items
| Method | Endpoint             | Description        |
|--------|---------------------|--------------------|
| GET    | /api/food-items      | List all items     |
| POST   | /api/food-items      | Create item        |
| PUT    | /api/food-items/{id} | Update item        |
| DELETE | /api/food-items/{id} | Soft-delete item   |

### Paluwagan Packages
| Method | Endpoint                    | Description     |
|--------|-----------------------------|-----------------|
| GET    | /api/paluwagan/packages      | List packages   |
| POST   | /api/paluwagan/packages      | Create package  |
| PUT    | /api/paluwagan/packages/{id} | Update package  |
| DELETE | /api/paluwagan/packages/{id} | Delete package  |

### Members
| Method | Endpoint                   | Description                          |
|--------|---------------------------|--------------------------------------|
| GET    | /api/paluwagan/members     | List all members                     |
| GET    | /api/paluwagan/members/{id}| Get member by ID                     |
| POST   | /api/paluwagan/members     | Add member + auto-generate payments  |
| PUT    | /api/paluwagan/members/{id}| Update member                        |

### Payments
| Method | Endpoint                                  | Description              |
|--------|------------------------------------------|--------------------------|
| GET    | /api/paluwagan/payments                   | All payments             |
| GET    | /api/paluwagan/payments/member/{memberId} | Payments by member       |
| PATCH  | /api/paluwagan/payments/{id}/pay          | Mark as paid + receipt # |
| PATCH  | /api/paluwagan/payments/{id}/unpay        | Mark as unpaid           |

### Receipts
| Method | Endpoint                  | Description          |
|--------|--------------------------|----------------------|
| GET    | /api/receipts/{id}/pdf    | Download PDF receipt |

### Dashboard
| Method | Endpoint        | Description       |
|--------|----------------|-------------------|
| GET    | /api/dashboard  | Summary analytics |

---

## ✨ Features

- **Admin Authentication** — JWT-based login, protected routes
- **Food Item CRUD** — Add, edit, soft-delete food items with categories and stock
- **Paluwagan Packages** — Define weekly amount and duration
- **Member Management** — Add members, auto-generates weekly payment schedule on enrollment
- **Payment Tracking** — Mark payments paid/unpaid with timestamps
- **PDF Receipts** — Auto-generated on payment, downloadable from the UI
- **Dashboard Analytics** — Total collected, collection rate, active members, pending payments
- **Mobile Responsive** — Collapsible sidebar on mobile
- **₱ PHP Currency** — All amounts formatted in Philippine Peso

---

## 🏗️ Architecture

```
React (port 3000)
    ↓ HTTP + JWT
Spring Boot (port 8080)
    ↓ JPA
MySQL (port 3306)
```

- JWT tokens expire in 24 hours
- Payments are auto-generated when a member is enrolled
- Receipt numbers format: `RCP-00001-20241215`
- Soft-delete pattern used for food items and packages

---

## 🔧 Troubleshooting

**CORS error** — Ensure frontend runs on port 3000 and backend on 8080.

**DB connection failed** — Check MySQL is running and credentials in `application.properties` are correct.

**`mvn` not found** — Install Maven or use `./mvnw spring-boot:run` if wrapper is present.

**`npm install` fails** — Use Node.js 18+. Run `node -v` to check.
