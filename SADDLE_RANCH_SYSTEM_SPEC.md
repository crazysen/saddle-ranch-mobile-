# Saddle Ranch Roadhouse — System & API Functional Specification
> **For 1:1 Flutter Mobile App & Web Parity**  
> **Source Codebase:** Saddle Ranch Web (Laravel 11 + React / Inertia + Tailwind CSS + SQLite/MySQL)

---

## Table of Contents
1. [Municipality & Barangay Dropdown Specification](#1-municipality--barangay-dropdown-specification)
2. [Database Architecture & Schema](#2-database-architecture--schema)
3. [Feature 1: Online Ordering (Pick-Up)](#3-feature-1-online-ordering-pick-up)
4. [Feature 2: In-House QR Ordering (Dine-In & Express Takeout)](#4-feature-2-in-house-qr-ordering-dine-in--express-takeout)
5. [Feature 3: Delivery Ordering](#5-feature-3-delivery-ordering)
6. [Complete REST API Reference for Flutter](#6-complete-rest-api-reference-for-flutter)
7. [Voucher & Discount Engine Rules](#7-voucher--discount-engine-rules)
8. [Live Order Tracking & Polling Lifecycle](#8-live-order-tracking--polling-lifecycle)

---

## 1. Municipality & Barangay Dropdown Specification

In the web application (`resources/js/Pages/Customer/Order.tsx`), delivery locations are organized using structured data for Cavite province, with special prioritization for the **Bulihan** cluster.

### A. Location Data Constants (Dart / Flutter Mapping)

```dart
// 1. Bulihan Core Barangays
const List<String> bulihanBarangays = [
  'Anahaw II',
  'Anahaw I',
  'Acacia',
  'Banaba',
  'Ipil I',
  'Ipil II',
  'Narra I',
  'Narra II',
  'Narra III',
  'Yakal',
  'Bulihan Proper',
];

// 2. Cavite Cities & Barangays Mapping
const Map<String, List<String>> caviteLocations = {
  'Silang': [
    ...bulihanBarangays,
    'Biga I',
    'Biga II',
    'Carmen',
    'Lucsuhin',
    'Poblacion I',
    'Poblacion II',
    'Sabutan',
    'San Vicente',
    'Tubuan',
    'Other Silang Barangay',
  ],
  'Dasmariñas City': [
    'Sampaloc 1',
    'Sampaloc 2',
    'Salawag',
    'Paliparan 1',
    'Paliparan 2',
    'Paliparan 3',
    'Langgaan',
    'San Agustin 1',
    'San Agustin 2',
    'Other Dasmariñas Barangay',
  ],
  'General Trias': [
    'Manggahan',
    'San Francisco',
    'Navarro',
    'Tejero',
    'Other Gen. Trias Barangay',
  ],
  'Imus City': [
    'Anabu I-A',
    'Bucandala',
    'Malagasang I-A',
    'Poblacion',
    'Other Imus Barangay',
  ],
  'Bacoor City': [
    'Molino 1',
    'Molino 2',
    'Molino 3',
    'Queens Row',
    'Other Bacoor Barangay',
  ],
  'Tagaytay City': [
    'Maharlika',
    'Mendez Crossing',
    'Sungay',
    'Other Tagaytay Barangay',
  ],
  'Other Cavite Municipality': [
    'Poblacion / Local Barangay',
  ],
};
```

### B. Form State & Cascading Dropdown Behavior
- **Default Region:** `Region IV-A (CALABARZON)` (Read-only)
- **Default Province:** `Cavite` (Read-only)
- **Default City / Municipality:** `Silang`
- **Default Barangay:** `Anahaw II`
- **Cascade Trigger:** When the user changes `city`, immediately set `barangay = caviteLocations[city][0]`.
- **Constructed Delivery Address String sent to backend:**
  ```text
  "${streetAddress.trim()}, Brgy. ${barangay}, ${city}, ${province}, ${region}"
  ```
  *(Example: `"Blk 26 Lot 17 Narra St., Brgy. Anahaw II, Silang, Cavite, Region IV-A (CALABARZON)"`)*

---

## 2. Database Architecture & Schema

The backend is built with Laravel 11. It supports SQLite for development and MySQL / PostgreSQL in production.

### Database Tables & Schema

#### 1. `users` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | User ID |
| `name` | VARCHAR(255) | NO | - | Full name |
| `first_name` | VARCHAR(255) | YES | NULL | First name |
| `last_name` | VARCHAR(255) | YES | NULL | Last name |
| `email` | VARCHAR(255) UNIQUE | NO | - | Email address (Login identifier) |
| `phone_number` | VARCHAR(20) | YES | NULL | 11-digit mobile (e.g. `09171234567`) |
| `address` | VARCHAR(255) | YES | NULL | Default saved delivery address |
| `password` | VARCHAR(255) | NO | - | Bcrypt hashed password |
| `role` | ENUM('admin','employee','user') | NO | `'user'` | Role permission |
| `branch` | VARCHAR(50) | NO | `'all'` | Branch assignment (`Bulihan`, `Dasma`, `all`) |
| `created_at` / `updated_at` | TIMESTAMP | YES | - | Timestamps |

#### 2. `products` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | Product ID |
| `name` | VARCHAR(255) | NO | - | Dish / item name |
| `description` | TEXT | YES | NULL | Menu item description |
| `price` | DECIMAL(8,2) | NO | - | Base price |
| `price_bulihan` | DECIMAL(8,2) | YES | NULL | Bulihan branch price |
| `price_dasmarinas`| DECIMAL(8,2) | YES | NULL | Dasmariñas branch price |
| `image_path` | VARCHAR(255) | YES | NULL | Image URL or relative path |
| `stock_quantity` | INTEGER | NO | 0 | Total global stock |
| `stock_bulihan` | INTEGER | NO | 0 | Bulihan branch inventory stock |
| `stock_dasmarinas`| INTEGER | NO | 0 | Dasmariñas branch inventory stock |
| `is_active` | BOOLEAN | NO | 1 (true) | If visible on menu |
| `created_at` / `updated_at` | TIMESTAMP | YES | - | Timestamps |

#### 3. `orders` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | Order ID |
| `user_id` | BIGINT UNSIGNED FK | YES | NULL | References `users.id` (NULL for guests) |
| `order_number` | VARCHAR(50) UNIQUE | NO | - | Unique ref (e.g. `SR-8A4F`) |
| `branch` | VARCHAR(50) | NO | `'Bulihan'`| Branch (`Bulihan` or `Dasma`) |
| `order_type` | ENUM | NO | - | `'dine_in'`, `'express_takeout'`, `'pickup'`, `'delivery'` |
| `table_number` | VARCHAR(20) | YES | NULL | Table number (Required for QR/dine-in) |
| `status` | ENUM | NO | `'pending'` | `'pending'`, `'preparing'`, `'ready'`, `'completed'`, `'cancelled'` |
| `total_amount` | DECIMAL(8,2) | NO | - | Final amount to pay (after discount) |
| `payment_method`| VARCHAR(100) | NO | - | e.g. `'Cash'`, `'Cash on Delivery'`, `'GCash'`, `'QRPH'`, `'PayMongo'` |
| `voucher_code` | VARCHAR(50) | YES | NULL | Applied promo coupon code |
| `discount_amount`| DECIMAL(8,2)| NO | 0.00 | Computed voucher discount |
| `customer_name` | VARCHAR(255) | YES | NULL | Name of customer |
| `customer_phone`| VARCHAR(20) | YES | NULL | 11-digit customer phone number |
| `delivery_address`| TEXT | YES | NULL | Full delivery address |
| `delivery_notes`| TEXT | YES | NULL | Gate code, landmark, or pick-up time |
| `cancelled_by_user_id`| BIGINT FK | YES | NULL | Staff ID who cancelled the order |
| `cancellation_reason` | VARCHAR(255)| YES | NULL | Cancellation reason note |
| `created_at` / `updated_at` | TIMESTAMP | YES | - | Timestamps |

#### 4. `order_items` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | Order item ID |
| `order_id` | BIGINT UNSIGNED FK | NO | - | Cascade deletes on order deletion |
| `product_id` | BIGINT UNSIGNED FK | NO | - | References `products.id` |
| `quantity` | INTEGER | NO | - | Number of units (min: 1) |
| `unit_price` | DECIMAL(8,2) | NO | - | Unit price at time of purchase |
| `subtotal` | DECIMAL(8,2) | NO | - | `quantity * unit_price` |
| `created_at` / `updated_at` | TIMESTAMP | YES | - | Timestamps |

#### 5. `vouchers` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | Voucher ID |
| `code` | VARCHAR(50) UNIQUE | NO | - | Upper-case code (e.g. `SADDLE10`, `WELCOME50`) |
| `discount_type` | ENUM('fixed', 'percentage') | NO | - | Discount computation method |
| `value` | DECIMAL(8,2) | NO | - | Percentage (e.g. `10.00` = 10%) or Fixed (e.g. `50.00` = ₱50) |
| `min_spend` | DECIMAL(8,2) | NO | 0.00 | Minimum order subtotal required |
| `is_one_time_use`| BOOLEAN | NO | 0 (false) | If true, single use per customer |
| `is_limited_time`| BOOLEAN | NO | 0 (false) | If time-restricted |
| `starts_at` | TIMESTAMP | YES | NULL | Valid from date |
| `expires_at` | TIMESTAMP | YES | NULL | Expiration date |
| `times_used` | INTEGER | NO | 0 | Total usage counter |
| `branch` | VARCHAR(50) | NO | `'all'` | Branch applicability (`all`, `bulihan`, `dasmarinas`) |
| `created_at` / `updated_at` | TIMESTAMP | YES | - | Timestamps |

#### 6. `voucher_usages` Table
| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Primary key |
| `voucher_id` | BIGINT UNSIGNED FK | NO | References `vouchers.id` (cascade delete) |
| `user_id` | BIGINT UNSIGNED FK | NO | References `users.id` (cascade delete) |
| `order_id` | BIGINT UNSIGNED FK | YES | References `orders.id` (null on delete) |
| `created_at` / `updated_at` | TIMESTAMP | YES | Timestamps |

#### 7. `promo_banners` Table
| Column | Type | Nullable | Default | Description |
|---|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Auto | Banner ID |
| `title` | VARCHAR(255) | NO | - | Banner title |
| `image_path` | VARCHAR(255) | YES | NULL | Image URL |
| `branch` | VARCHAR(50) | NO | `'all'` | Branch target (`all`, `bulihan`, `dasmarinas`) |
| `display_order` | INTEGER | NO | 0 | Sorting rank |
| `is_active` | BOOLEAN | NO | 1 (true) | Active state |

#### 8. `audit_logs` Table
| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED PK | NO | Log ID |
| `user_id` | BIGINT UNSIGNED FK | YES | User/Staff who initiated action |
| `action` | VARCHAR(255) | NO | Description of action taken |
| `ip_address` | VARCHAR(45) | YES | Client IP address |
| `payload` | JSON | YES | Associated order or context payload |
| `created_at` / `updated_at` | TIMESTAMP | YES | Timestamps |

---

## 3. Feature 1: Online Ordering (Pick-Up)

Online Ordering allows customers to order food remotely and pick it up at the selected branch.

### User Flow & Functional Requirements
1. **Menu Browsing & Filtering:**
   - Categories: `Popular`, `Rice Meals`, `Authentic Filipino`, `Barkada Platters`, `Drinks & Extra Rice`.
   - Real-time search query filtering across menu name and descriptions.
   - Branch toggle: Switch between **Bulihan** and **Dasmariñas** (changes item prices and availability).
2. **Cart Management:**
   - Add item, increment/decrement quantity (bounded by product `stock_quantity`), remove item.
   - Persistent local storage (`saddle_ranch_cart_v1`).
3. **Pick-up Form Fields:**
   - `customer_name` (Required, string)
   - `customer_phone` (Required, 11 digits: `^09[0-9]{9}$` or `^[0-9]{11}$`)
   - `pickup_time` (Select options: `ASAP (15-20 mins)`, `30 mins`, `45 mins`, `1 hour`, `Scheduled Time`)
   - `delivery_notes` (Special cooking instructions, e.g. "extra spicy, separate gravy")
4. **Voucher Redemption:**
   - Input voucher code -> Calls `/api/v1/vouchers/validate`.
   - Requires customer login if applying a voucher.
   - Calculates percentage or fixed discount and subtracts from subtotal.
5. **Checkout & Payment:**
   - Payment Options: `Cash (Pick-Up)`, `GCash`, `PayMongo / Card / QRPH`.
   - Optional inline account registration if customer is a guest.
6. **Order Placed Confirmation:**
   - Generates unique order number: `SR-XXXX`.
   - Saves order number locally in customer history (`saddle_ranch_customer_orders`).
   - Automatically opens the **Live Order Tracker**.

---

## 4. Feature 2: In-House QR Ordering (Dine-In & Express Takeout)

In-House QR Ordering is triggered when a customer seated at a table scans the table's QR code.

### Deep Linking / URL Parameter Handling
- Scanning the table QR opens: `https://saddleranch.ph/dine-in?table=05` (or deep-links into Flutter: `saddleranch://dinein?table=05`).
- The app parses the `table` query parameter (defaults to `'05'` if missing) and stores it in session/state.

### Fulfillment Mode Switcher
Customers select between two modes:
1. **Dine-In (`order_type = 'dine_in'`):**
   - Served directly to table.
   - Requires `table_number`.
   - Customer name and phone are optional.
2. **Express Takeout (`order_type = 'express_takeout'`):**
   - Packaged to-go while sitting in-house.
   - Requires `table_number` for delivery to table or counter call.

### "Call Waiter" Buzzer System
- **Endpoint to Request Waiter:** `POST /api/v1/waiter-call`
  - Body: `{"table_number": "05", "branch": "Bulihan"}`
  - Stores call in server cache with 30-minute expiration.
  - Generates Audit Log.
- **Client Status Polling:** `GET /api/v1/waiter-call/status?table_number=05`
  - Polled every 2.5 seconds.
  - States:
    - `'idle'`: Button displays **"Call Waiter"** (amber buzzer).
    - `'pending'`: Button displays **"Calling Waiter... / Assistance Requested"** (pulsing red/amber).
    - `'acknowledged'`: Waiter dismissed call on POS/KDS -> App displays **"Server is on the way!"** toast for 12 seconds, then resets to `'idle'`.
- **Staff Dismiss Endpoint:** `POST /api/v1/waiter-calls/dismiss`
  - Body: `{"table_number": "05"}`

### Branch Selection & GPS Distance Calculator
- Saddle Ranch GPS Coordinates:
  - **Bulihan Branch:** `Lat: 14.2384, Lng: 120.9752`
  - **Dasmariñas Branch:** `Lat: 14.3291, Lng: 120.9365`
- Distance Formula (Haversine in km):
  ```dart
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth radius km
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
  ```

---

## 5. Feature 3: Delivery Ordering

Delivery Ordering allows customers across Cavite to have food delivered directly to their doorstep.

### Address & Dropdown Form Structure
1. **Region:** `Region IV-A (CALABARZON)` (Fixed / Pre-selected)
2. **Province:** `Cavite` (Fixed / Pre-selected)
3. **Municipality / City:** Dropdown containing:
   - `Silang`
   - `Dasmariñas City`
   - `General Trias`
   - `Imus City`
   - `Bacoor City`
   - `Tagaytay City`
   - `Other Cavite Municipality`
4. **Barangay / Zone:** Dropdown dynamically populated from the selected city.
   - For `Silang`, all 11 **Bulihan Barangays** (`Anahaw I & II`, `Acacia`, `Banaba`, `Ipil I & II`, `Narra I-III`, `Yakal`, `Bulihan Proper`) are highlighted at the top.
5. **Street Address / House No. / Building:** (Required text input).
6. **Delivery Notes & Landmarks:** (e.g., "Green gate beside sari-sari store, please ring bell").

### Address Construction & Payload Format
```json
{
  "order_type": "delivery",
  "customer_name": "Juan Dela Cruz",
  "customer_phone": "09171234567",
  "delivery_address": "Block 26 Lot 17 Narra St., Brgy. Anahaw II, Silang, Cavite, Region IV-A (CALABARZON)",
  "delivery_notes": "Call upon arrival at the gate",
  "payment_method": "Cash on Delivery",
  "voucher_code": "BULIHANFREE",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 7, "quantity": 2 }
  ]
}
```

### Payment Methods for Delivery
- `Cash on Delivery (COD)` (Default)
- `GCash`
- `PayMongo (Credit/Debit Card / Maya / QRPH)`

---

## 6. Complete REST API Reference for Flutter

Base URL: `https://your-domain.com/api/v1` (or local dev: `http://10.0.2.2:8000/api/v1` for Android Emulator)

### 1. Authentication Endpoints

#### POST `/auth/login` (Flutter Token Login)
- **Description:** Issues a Sanctum Bearer Token for Flutter mobile app.
- **Request Body:**
  ```json
  {
    "email": "customer@example.com",
    "password": "password123"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "message": "Login successful.",
    "token": "1|sanctum_token_string_here...",
    "user": {
      "id": 5,
      "name": "Juan Dela Cruz",
      "email": "customer@example.com",
      "phone_number": "09171234567",
      "address": "Silang, Cavite",
      "role": "user"
    }
  }
  ```

#### POST `/customer/register`
- **Request Body:**
  ```json
  {
    "name": "Juan Dela Cruz",
    "email": "juan@example.com",
    "phone_number": "09171234567",
    "password": "password123",
    "password_confirmation": "password123"
  }
  ```

---

### 2. Menu & Banners Endpoints

#### GET `/products`
- **Description:** Returns all active menu items with full absolute image URLs.
- **Response `200 OK`:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": 1,
        "name": "Sizzling Pork Sisig",
        "description": "Crispy pork belly seasoned with local spices...",
        "price": "180.00",
        "price_bulihan": "180.00",
        "price_dasmarinas": "195.00",
        "image_path": "https://lh3.googleusercontent.com/...",
        "stock_quantity": 50,
        "stock_bulihan": 30,
        "stock_dasmarinas": 20,
        "is_active": true
      }
    ]
  }
  ```

#### GET `/banners`
- **Description:** Returns active promo carousel banners.
- **Response `200 OK`:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": 1,
        "title": "Weekend Sizzling Specials",
        "image_path": "https://lh3.googleusercontent.com/...",
        "branch": "all",
        "display_order": 1
      }
    ]
  }
  ```

---

### 3. Orders & Checkout Endpoints

#### POST `/orders` (Mobile Order Submission)
- **Headers:** `Authorization: Bearer <TOKEN>` (optional for guests)
- **Request Body:**
  ```json
  {
    "order_type": "delivery",
    "table_number": null,
    "customer_name": "Juan Dela Cruz",
    "customer_phone": "09171234567",
    "delivery_address": "Blk 26 Lot 17, Brgy. Anahaw II, Silang, Cavite, Region IV-A",
    "delivery_notes": "Leave with guard if unattended",
    "payment_method": "Cash on Delivery",
    "voucher_code": "SADDLE10",
    "items": [
      {
        "product_id": 1,
        "quantity": 2
      }
    ]
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "status": "success",
    "message": "Order created successfully.",
    "data": {
      "id": 42,
      "order_number": "SR-7F92",
      "order_type": "delivery",
      "status": "pending",
      "total_amount": 324.00,
      "payment_method": "Cash on Delivery",
      "customer_name": "Juan Dela Cruz",
      "order_items": [
        {
          "id": 88,
          "product_id": 1,
          "quantity": 2,
          "unit_price": "180.00",
          "subtotal": "360.00",
          "product": {
            "name": "Sizzling Pork Sisig"
          }
        }
      ]
    }
  }
  ```

---

### 4. Vouchers Endpoints

#### POST `/vouchers/validate`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Request Body:**
  ```json
  {
    "code": "SADDLE10",
    "subtotal": 500.00,
    "branch": "Bulihan"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "status": "success",
    "message": "Voucher applied successfully!",
    "voucher": {
      "id": 1,
      "code": "SADDLE10",
      "discount_type": "percentage",
      "value": 10.00,
      "discount_amount": 50.00,
      "final_total": 450.00
    }
  }
  ```

#### GET `/customer/vouchers`
- **Description:** Returns list of all available vouchers with an `is_used` boolean indicator for the logged-in user.

---

### 5. Order Tracking & History Endpoints

#### GET `/orders/track?query=SR-7F92`
- **Query Params:**
  - `query`: Order number (`SR-XXXX`), customer phone number, or customer name.
  - `all=1`: Returns recent 30 active orders.
- **Response `200 OK`:**
  ```json
  {
    "status": "success",
    "data": [
      {
        "id": 42,
        "order_number": "SR-7F92",
        "order_type": "delivery",
        "status": "preparing",
        "total_amount": 324.00,
        "payment_method": "Cash on Delivery",
        "created_at": "2026-08-17T15:30:00Z",
        "order_items": [...]
      }
    ]
  }
  ```

#### GET `/customer/orders`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Description:** Fetches all historical orders associated with the authenticated customer account.

---

### 6. Waiter Call Endpoints (QR Ordering)

#### POST `/waiter-call`
- **Request:** `{"table_number": "05", "branch": "Bulihan"}`
- **Response:** `{"status": "success", "message": "Waiter call sent for Table #05"}`

#### GET `/waiter-call/status?table_number=05`
- **Response:**
  ```json
  {
    "status": "success",
    "data": {
      "status": "idle",
      "updated_at": 1723880000
    }
  }
  ```
  *(Status values: `'idle'`, `'pending'`, `'acknowledged'`)*

---

## 7. Voucher & Discount Engine Rules

1. **Authentication Requirement:** Customer MUST be logged in with a valid account to apply any voucher code.
2. **Min Spend Check:** Subtotal must be `>= voucher.min_spend`.
3. **One-Time Use Check:** If `is_one_time_use == true`, checks `voucher_usages` table. If the user ID has already redeemed the voucher, the request is rejected with `"You have already redeemed this 1-time use promo code."`.
4. **Time & Expiration Window:**
   - If `starts_at` is set, `now() >= starts_at`.
   - If `expires_at` is set, `now() <= expires_at`.
5. **Branch Filtering:** If `voucher.branch != 'all'`, it can only be redeemed when ordering from the matching branch.
6. **Computation Formula:**
   - **Percentage:** `discount = round(subtotal * (value / 100), 2)`
   - **Fixed Amount:** `discount = min(subtotal, value)`
   - **Final Total:** `max(0, subtotal - discount)`

---

## 8. Live Order Tracking & Polling Lifecycle

### Status Lifecycle Diagram

```
[ pending ] ──► [ preparing ] ──► [ ready ] ──► [ completed ]
     │               │              │
     └───────────────┴──────────────┴──────────► [ cancelled ] (Voided)
```

| Order Status | Customer UI Representation | Meaning |
|---|---|---|
| `pending` | 🕒 Order Received | Order recorded, awaiting kitchen confirmation |
| `preparing`| 🔥 Sizzling on Skillet | Kitchen is cooking dishes |
| `ready` | 🍽️ Ready for Pick-Up / Delivery | Dishes are boxed or ready for pickup / rider dispatched |
| `completed`| ✅ Order Complete | Customer received order and payment settled |
| `cancelled`| ❌ Cancelled / Voided | Cancelled by manager with reason note |

### Polling Frequency Recommendations for Flutter
- **Active Order Screen:** Poll `GET /api/v1/orders/track?query=<ORDER_NUMBERS>` every **5 seconds**.
- **Waiter Buzzer Status:** Poll `GET /api/v1/waiter-call/status?table_number=<TABLE>` every **2.5 seconds**.
- **Cache Persistence:** Save placed order numbers in Flutter `shared_preferences` / `hydrated_bloc` under key `saddle_ranch_customer_orders`.
