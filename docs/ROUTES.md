# RideGo Route Catalog & Corridor Reference

This document provides the authoritative reference for transit corridors, verified municipality stops, route variants, fare rules, and stop order validation for the RideGo platform operating in Samar and Leyte, Philippines.

---

## 1. Geographical Context & Core Corridors

RideGo connects the key transit hubs of Western Samar and Northern Leyte across the Pan-Philippine Highway (AH26) and the iconic San Juanico Bridge.

```
                      [ Calbayog City ]
                              ▲
                              │ Northbound Corridor (AH26)
                              ▼
                      [ Catbalogan City ] (Central Hub)
                              ▲
                              │ Southbound Corridor (AH26 & San Juanico)
                              ▼
                       [ Tacloban City ]
```

---

## 2. Southbound Corridor: Catbalogan City ⇄ Tacloban City

### Corridor Identifier
- `catbalogan-tacloban-south`

### Municipality Stops & Sequence Order
In accordance with provincial transit rules, the Southbound corridor connects 11 sequential stops across Western Samar, the San Juanico Strait, and Leyte:

| Stop Order | Municipality / Hub | Province | Coordinates | Is Terminal | Key Junction / Landmark |
|---|---|---|---|---|---|
| 0 | Catbalogan City | Samar | 11.7753° N, 124.8860° E | Yes | Pier 1 / Catbalogan Bus Terminal |
| 1 | Jiabong | Samar | 11.7562° N, 124.9542° E | No | Mussel / Tahong Capital |
| 2 | Motiong | Samar | 11.7892° N, 124.9961° E | No | AH26 Highway Junction |
| 3 | Paranas (Wright) | Samar | 11.7711° N, 125.0253° E | No | Eastern Samar Divergence |
| 4 | Villareal | Samar | 11.5583° N, 124.9317° E | No | Villareal Bay Turn-off |
| 5 | Pinabacdao | Samar | 11.5392° N, 124.9811° E | No | Lulugayan / Provincial Road |
| 6 | Calbiga | Samar | 11.6189° N, 125.0167° E | No | Calbiga Caves / Town Proper |
| 7 | Basey | Samar | 11.2825° N, 125.0692° E | No | Basey Weaving Hub / Sohoton |
| 8 | Marabut | Samar | 11.2056° N, 125.1972° E | No | Coastal Rock Formations |
| 9 | Santa Rita | Samar | 11.4503° N, 124.9806° E | No | Samar End of San Juanico Bridge |
| 10 | Tacloban City | Leyte | 11.2444° N, 125.0039° E | Yes | Tacloban New Bus Terminal (Abucay) |

### Reverse Route Support
A separate route variant (`tacloban-catbalogan-north`) represents the exact reverse corridor with inverted stop sequences (Tacloban = Stop 0, Santa Rita = Stop 1, ..., Catbalogan = Stop 10).

---

## 3. Northbound Corridor: Catbalogan City ⇄ Calbayog City

### Corridor Identifier
- `catbalogan-calbayog-north`

### Municipality Stops & Sequence Order
The Northbound corridor covers 9 sequential stops through northwestern Samar:

| Stop Order | Municipality / Hub | Province | Coordinates | Is Terminal | Key Junction / Landmark |
|---|---|---|---|---|---|
| 0 | Catbalogan City | Samar | 11.7753° N, 124.8860° E | Yes | Catbalogan Grand Terminal |
| 1 | Jiabong | Samar | 11.7562° N, 124.9542° E | No | Pan-Philippine Highway Coastal |
| 2 | Motiong | Samar | 11.7892° N, 124.9961° E | No | Northward Convergence |
| 3 | San Jorge | Samar | 11.9822° N, 124.8156° E | No | Blanca Aurora Falls Junction |
| 4 | Gandara | Samar | 12.0167° N, 124.8167° E | No | Gandara River Basin |
| 5 | Pagsanghan | Samar | 11.9667° N, 124.8667° E | No | Interior Access Highway |
| 6 | Tarangnan | Samar | 11.8978° N, 124.7508° E | No | Coastal Highway Divergence |
| 7 | Santa Margarita | Samar | 12.0378° N, 124.6606° E | No | Northern Samar Border Access |
| 8 | Calbayog City | Samar | 12.0675° N, 124.5958° E | Yes | Calbayog City Central Bus Terminal |

---

## 4. Authoritative Pricing Rules & Fare Calculation

Fares are calculated strictly on the backend using the PostgreSQL RPC `calculate_authoritative_fare` to ensure complete financial integrity and prevent client manipulation.

### Shared Vehicles (Vans & Buses)
Shared transportation services charge per passenger seat using a piecewise formula:

$$\text{Total Fare} = \left(\text{Base Fare} + \left(N_{\text{segments}} \times \text{Per Segment Rate}\right)\right) \times \text{Seat Count} + \text{Terminal Fee}$$

Where:
- $N_{\text{segments}} = \text{Dropoff Stop Order} - \text{Pickup Stop Order}$
- If $N_{\text{segments}} \le 0$, the calculation raises an error (`Invalid stop sequence: dropoff must follow pickup`).
- **Standard Van (Van-Vans, Grand Tours)**:
  - Base Fare: ₱60.00
  - Per Segment Rate: ₱15.00
  - Terminal Fee: ₱10.00 (charged if pickup or dropoff is at a designated terminal)
- **Standard Bus (Silver Star, DLTB, Philtranco)**:
  - Base Fare: ₱45.00
  - Per Segment Rate: ₱10.00
  - Terminal Fee: ₱5.00

### Private Vehicles (Motorcycles, Car Rental, Chartered Vans)
Private transportation services are chartered as a whole vehicle rather than per seat:

$$\text{Total Fare} = \text{Base Fare} + \left(N_{\text{segments}} \times \text{Per Segment Rate}\right) + \text{Terminal Fee}$$

- **Motorcycle / Habal-habal**:
  - Base Fare: ₱40.00
  - Per Segment Rate: ₱20.00
  - Terminal Fee: ₱0.00

---

## 5. Stop Sequence & Validation Rules

1. **Strict Directionality**:
   Every search and booking query verifies that:
   $$\text{order}(\text{dropoff\_stop}) > \text{order}(\text{pickup\_stop})$$
   Attempts to book in reverse order on a forward variant are rejected with code `P0001: Invalid forward stop sequence`.

2. **Schedule Conflict Prevention**:
   Vehicles assigned to an active schedule cannot be double-booked for overlapping departure times. The database trigger `check_vehicle_schedule_conflict` ensures a vehicle is only committed to one active route at any given departure timestamp.

3. **Remaining Capacity Enforcement**:
   For shared routes, seat reservations decrement remaining seats atomically. Once `remaining_capacity < requested_seats`, the schedule is flagged sold-out for the requested segment.
