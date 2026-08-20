# Saddle Ranch Roadhouse — Order Lifecycle & Void Management Specification
> **For 1:1 Parity Between Web, KDS, POS, and Flutter Mobile App**  
> **Source Codebase:** `OrderController.php`, `EmployeeController.php`, `KDS.tsx`, `Dashboard.tsx`, `CustomerOrderTracker.tsx`

---

## Table of Contents
1. [Order Lifecycle State Machine](#1-order-lifecycle-state-machine)
2. [Order Creation & Stock Allocation](#2-order-creation--stock-allocation)
3. [State Transition Matrix & Rules](#3-state-transition-matrix--rules)
4. [Kitchen Display System (KDS) & Cook Aggregator](#4-kitchen-display-system-kds--cook-aggregator)
5. [Void / Cancellation Security Flow](#5-void--cancellation-security-flow)
6. [Payment Gateway & Settlement Lifecycles](#6-payment-gateway--settlement-lifecycles)
7. [Customer Live Tracking & Polling Lifecycles](#7-customer-live-tracking--polling-lifecycles)
8. [Audit Logging & Historical Traceability](#8-audit-logging--historical-traceability)

---

## 1. Order Lifecycle State Machine

Every order placed in Saddle Ranch moves through a finite state machine:

```
                  ┌─────────────────────────────────────────────────────────┐
                  │                                                         │
                  ▼                                                         │
┌──────────────┐     PATCH /orders/{id}/status     ┌──────────────┐         │
│   pending    │ ────────────────────────────────► │  preparing   │         │
└──────────────┘                                   └──────────────┘         │
  (New Ticket)                                      (On the Grill)          │
                                                           │                │
                                               PATCH /orders/{id}/status    │
                                                           │                │
                                                           ▼                │
┌──────────────┐     PATCH /orders/{id}/status     ┌──────────────┐         │
│  completed   │ ◄──────────────────────────────── │    ready     │         │
└──────────────┘                                   └──────────────┘         │
  (Settled/Done)                                    (Ready to Serve)        │
                                                                            │
                                                                            │
      POST /orders/{id}/cancel (Password Authorized + Reason Required)      │
      ──────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │    cancelled    │  (Stock Restored)
                         └─────────────────┘
```

---

## 2. Order Creation & Stock Allocation

### A. Order Placement Sources
1. **Customer Web / Mobile Pick-Up & Delivery:** `POST /order/checkout` (Web session) or `POST /api/v1/orders` (Mobile Sanctum API).
2. **In-House QR Table Ordering:** `dine_in` or `express_takeout` bound to a `table_number`.
3. **Cashier POS In-Store Order:** Created directly from the Employee POS Dashboard.

### B. Atomic Stock Verification & Deduction
During checkout, the database executes an atomic transaction with row locking:

```php
// 1. Lock rows to prevent race conditions during high peak hours
$product = Product::where('id', $itemData['product_id'])
    ->lockForUpdate()
    ->firstOrFail();

// 2. Validate stock quantity
if ($product->stock_quantity < $itemData['quantity']) {
    throw ValidationException::withMessages([
        'items' => ["Sorry, '{$product->name}' has insufficient stock (Only {$product->stock_quantity} left)."],
    ]);
}

// 3. Decrement stock
$product->decrement('stock_quantity', $itemData['quantity']);
```

### C. Voucher Usage Locking
If a voucher is attached:
- Customer user authentication is verified.
- Expiration (`starts_at`, `expires_at`), minimum spend, and single-use checks are evaluated.
- A `voucher_usages` record is inserted, and `vouchers.times_used` is incremented.

---

## 3. State Transition Matrix & Rules

Status updates are executed via `PATCH /orders/{id}/status` or `PATCH /api/v1/orders/{id}/status`.

| Current Status | Allowed Next Status | Triggering Actor | System Actions |
|---|---|---|---|
| **`pending`** | `preparing` | Kitchen Head Chef / Grill Cook | Moves ticket to active grill queue; KDS card changes to yellow/sizzling. |
| **`preparing`** | `ready` | Kitchen Head Chef | Order is plated/boxed; KDS card changes to blue ("Ready at Counter"); Waiter / Delivery Rider notified. |
| **`ready`** | `completed` | Cashier / Server / Rider | Customer receives food and payment is finalized. Global & branch stock (`stock_bulihan` or `stock_dasmarinas`) inventory levels updated. |
| **`pending` / `preparing` / `ready`** | `cancelled` | Manager / Supervisor | **BLOCKED** on `PATCH /status`. **MUST** use `POST /orders/{id}/cancel` with password verification. |
| **`completed`** | None (Terminal) | - | Order is closed. |
| **`cancelled`** | None (Terminal) | - | Order is voided and immutable. |

---

## 4. Kitchen Display System (KDS) & Cook Aggregator

The Kitchen Display System (`resources/js/Pages/Employee/KDS.tsx`) is designed for touch terminals in hot kitchen environments.

### A. Polling & Chime Alert Engine
- **Poll Interval:** Queries `GET /api/v1/kitchen/orders` every **3.5 seconds** (auto-paused when browser tab is inactive to preserve server resources).
- **Dual-Chime Audio Alert:** When a new `pending` ticket is detected, the KDS triggers a dual-tone audio chime (880Hz & 1760Hz) via the Web Audio API / HTML5 Audio fallback.

### B. Ticket Urgency Timer Matrix
Elapsed minutes are calculated as `(currentTime - created_at) / 60000`:

| Elapsed Time | KDS Card Border & Background | Urgency Level | Kitchen Action |
|---|---|---|---|
| **0 – 9 Minutes** | `#1e1710` (Amber Gold Border) | Normal | Standard prep & cook time |
| **10 – 14 Minutes**| `#221e16` (Bright Yellow Border) | Warning Alert | Expediter prioritizes order |
| **15+ Minutes** | `#261416` (Rose Red Border + Pulse) | Critical Delay | Head Chef expedited immediately |

### C. Live Cook Summary Aggregator
The KDS side panel dynamically computes the total batch quantities required across all `pending` and `preparing` tickets:

$$\text{Total Required Quantity} = \sum_{\text{active tickets}} \text{item.quantity}$$

*Example KDS Summary Display:*
- 🔥 `12x` Sizzling Pork Sisig
- 🔥 `6x` Sizzling T-Bone Steak
- 🔥 `4x` Sizzling Bulalo Steak
- 🔥 `18x` Extra Garlic Rice

---

## 5. Void / Cancellation Security Flow

Cancelling or voiding an order requires supervisor authentication to prevent unauthorized deletions, theft, or inventory discrepancies.

### A. Cancellation Security API
- **Endpoint:** `POST /orders/{id}/cancel` or `POST /api/v1/orders/{id}/cancel`
- **Headers:** `Accept: application/json`, `Content-Type: application/json`
- **Request Payload:**
  ```json
  {
    "password": "supervisor_password_here",
    "reason": "Customer changed mind before preparation / Incorrect table input"
  }
  ```

### B. Void Processing Logic
```php
// 1. Authenticate user password
$user = auth()->user();
if (!$user || !Hash::check($request->password, $user->password)) {
    return response()->json(['message' => 'Invalid authorization password'], 403);
}

// 2. Reject if already cancelled
if ($order->status === 'cancelled') {
    return response()->json(['message' => 'Order is already cancelled.'], 422);
}

DB::transaction(function () use ($order, $user, $request) {
    // 3. Mark as cancelled with supervisor trail
    $order->status = 'cancelled';
    $order->cancelled_by_user_id = $user->id;
    $order->cancellation_reason = $request->reason;
    $order->save();

    // 4. Atomically restore inventory to products table
    $branchName = strtolower($order->branch ?? 'bulihan');
    $isDasma = str_contains($branchName, 'dasma');

    foreach ($order->orderItems as $item) {
        if ($item->product) {
            $qty = (int) $item->quantity;
            $item->product->increment('stock_quantity', $qty);
            if ($isDasma) {
                $item->product->increment('stock_dasmarinas', $qty);
            } else {
                $item->product->increment('stock_bulihan', $qty);
            }
        }
    }

    // 5. Create immutable audit record
    AuditLog::create([
        'user_id' => $user->id,
        'action' => "Voided Order #{$order->order_number} | Reason: {$request->reason}",
        'ip_address' => $request->ip(),
        'payload' => [
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'reason' => $request->reason,
        ],
    ]);
});
```

---

## 6. Payment Gateway & Settlement Lifecycles

### A. Cash & Cash on Delivery (COD)
- Placed immediately with `status: 'pending'`.
- Payment collection happens physically at the counter (Pick-Up / Dine-In) or doorstep (Delivery).
- Marked `status: 'completed'` upon cash receipt.

### B. PayMongo Gateway (GCash, Maya, Cards, QRPH)
1. Order row created with unique `order_number` (e.g. `SR-8A4F`).
2. Server calls `https://api.paymongo.com/v1/checkout_sessions` with line items, total amount, `success_url`, and `cancel_url`.
3. Customer is redirected to the PayMongo hosted checkout page.
4. Upon successful payment, customer returns to `success_url` (`?success=1&order_number=SR-8A4F`).
5. Webhook / return URL flags payment as completed.

---

## 7. Customer Live Tracking & Polling Lifecycles

Customers track their orders using the floating tracker (`resources/js/Components/CustomerOrderTracker.tsx`):

### A. Polling Query Endpoints
- **Endpoint:** `GET /api/v1/orders/track?query=SR-8A4F`
- **Fallback / Multi-order Query:** `GET /api/v1/orders/track?query=SR-8A4F,SR-9B12`

### B. Customer UI Status Representation
```
[ 🕒 Order Received ] ──► [ 🔥 Sizzling on Skillet ] ──► [ 🍽️ Ready to Serve / Out for Delivery ] ──► [ ✅ Completed ]
```

| Order Status | Customer Banner Title | Customer Subtitle / ETA Message |
|---|---|---|
| `pending` | **Order Received** | We have received your order. Sent to the kitchen grill. |
| `preparing` | **Sizzling on the Grill** | Chef is preparing your sizzling dishes right now! |
| `ready` | **Ready for Pick-Up / Delivery** | Your food is cooked and ready at the dispatch counter! |
| `completed` | **Order Completed** | Enjoy your meal! Thank you for dining with Saddle Ranch. |
| `cancelled` | **Order Cancelled** | This order was cancelled. Please check with our staff. |

---

## 8. Audit Logging & Historical Traceability

Every critical operation is logged to the `audit_logs` table:

| Event | Log Action Format | Payload Saved |
|---|---|---|
| **Order Placed** | `Order #SR-XXXX placed by [Name] ([Type]) - Total: ₱XXX.XX` | `order_id`, `order_number`, `order_type`, `total_amount`, `voucher_code` |
| **Status Update** | `Updated Order #SR-XXXX status from [old] to [new]` | `order_id`, `order_number`, `previous_status`, `new_status` |
| **Order Voided** | `Voided Order #SR-XXXX | Reason: [Reason Text]` | `order_id`, `order_number`, `previous_status`, `reason` |
| **Waiter Buzzer** | `WAITER CALL: Table #XX requested assistance at [Branch]` | `table_number`, `branch`, `time`, `timestamp` |
| **Auth Event** | `Customer [Name] logged in via Checkout Auth Modal` | `user_id`, `email`, `ip_address` |
