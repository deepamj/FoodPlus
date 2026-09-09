# FoodPlus+

Surplus food-to-NGO connector — a platform where canteens, restaurants, and event organizers post surplus food, and nearby NGOs claim and arrange pickup.

**Live site:** [FoodPlus+]([https://your-deployed-url.vercel.app](https://foodplus-app.surge.sh))


Built by Team hal9k.

## The Problem

Significant amounts of edible food are discarded daily by canteens, hostels, restaurants, and event caterers because there is no fast, reliable way to connect that surplus with the NGOs who could redistribute it. This is a coordination gap, not a supply or demand problem.

## The Solution

A three-stage workflow: post, claim, collect.

- Donors (canteens, restaurants, caterers) report surplus food through a short form — address, item details, photos.
- NGOs browse live listings and claim a specific quantity of parcels.
- Donors mark the post as collected once pickup is complete.

## Key Features

- Role-based authentication for Donors and NGOs
- Interactive map with location search (OpenStreetMap + Nominatim) for pickup addresses
- Itemized food posting with name, quantity, veg/non-veg classification, and photos
- Bounded claiming — claims are processed atomically at the database level, preventing two NGOs from over-claiming the same donation
- Status tracking: posted → claimed → collected
- Responsive layout, mobile-first

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Svelte + Vite |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Maps | Leaflet.js + OpenStreetMap |
| Security | Row-Level Security, atomic claim transaction |

## Implementation Notes

Claims are handled through a single PostgreSQL function (`SECURITY DEFINER`) that validates availability, decrements stock, inserts the claim record, and updates post status in one transaction — avoiding race conditions when multiple NGOs claim from the same post concurrently.

Profile creation on signup is handled via a database trigger rather than a client-side insert, avoiding authentication-timing issues with Row-Level Security.
## Future Scope

- Real-time notifications when a post is claimed
- Radius-based search for NGOs
- Impact analytics (meals redistributed, waste diverted)
- Native mobile apps

## Team hal9k

- Nikhil M Warrier
- Deepa Mary Jose
- Deva Nanda Sumod
- Johann Thomas Philip
