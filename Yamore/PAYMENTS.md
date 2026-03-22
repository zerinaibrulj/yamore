# Payment system (Stripe + offline)

The app supports three payment options so the flow stays clear and reliable.

## 1. **Card (Stripe)** – pay now

- User pays by card at checkout. Payment is processed by **Stripe** (PCI-compliant).
- **Backend:** Creates a Stripe PaymentIntent, returns `client_secret` to the app. After the user completes payment in the Stripe sheet, the app calls the confirm endpoint; the backend verifies the PaymentIntent with Stripe, creates a `Payment` record, and sets the reservation to **Confirmed**.
- **Flutter:** Uses `flutter_stripe` Payment Sheet: after creating the reservation, the app gets the publishable key and creates an intent, then shows the Stripe sheet. On success it calls the confirm API.

### Configuring Stripe

1. Create an account at [stripe.com](https://stripe.com) and get your **Secret key** and **Publishable key** (Dashboard → Developers → API keys).
2. In the API project set:
   - **Stripe:SecretKey** – e.g. in `appsettings.Development.json` or User Secrets (never commit the secret key).
   - **Stripe:PublishableKey** – e.g. in `appsettings.json` or User Secrets.
3. Example (User Secrets or env):

   ```bash
   dotnet user-secrets set "Stripe:SecretKey" "sk_test_..."
   dotnet user-secrets set "Stripe:PublishableKey" "pk_test_..."
   ```

4. The Flutter app loads the publishable key from `GET /Payment/stripe-config` (no auth), so the key can be public.

If Stripe keys are not set, the “Card” option still appears; create-intent will fail with a clear message and the user can choose “Pay on arrival” instead.

### Testing card checkout (test mode — for evaluators)

Use **test mode** API keys (`pk_test_…` / `sk_test_…`). In the Stripe payment sheet you can enter [Stripe’s official test cards](https://docs.stripe.com/testing):

| Field | Example (successful Visa payment) |
|--------|-----------------------------------|
| Card number | `4242 4242 4242 4242` |
| Expiry | Any **future** date, e.g. `12 / 34` |
| CVC | Any 3 digits, e.g. `123` |
| Country / ZIP / address | Usually any values are accepted in test mode; if a field is required, use plausible test data (e.g. country **United States**, ZIP **12345**). |

Other scenarios (declines, 3D Secure, etc.) are listed in Stripe’s documentation above — those numbers are **not** secrets; Stripe publishes them for integration testing.

## 2. **Pay on arrival (cash / bank transfer)**

- User selects “Pay on arrival”. No payment is taken in the app.
- **Backend:** Confirm is called with `PaymentMethod: "Cash"` and no `PaymentIntentId`. A `Payment` record is created with status **pending**; reservation stays **Pending** until the owner marks it (or you add a “mark as paid” flow).
- No gateway configuration needed.

## 3. **PayPal** – coming soon

- Shown in the UI as “PayPal (coming soon)”.
- If the user selects it, the app creates the reservation and calls confirm with `PaymentMethod: "PayPal"` and no `PaymentIntentId`, so a **Payment** is stored as pending (same behaviour as cash). You can later add a real PayPal integration (e.g. orders API) and then trigger that flow when “PayPal” is selected.

## Summary

| Method        | When user pays   | Backend action                          | Reservation status after confirm   |
|---------------|------------------|-----------------------------------------|------------------------------------|
| Card (Stripe) | At checkout      | Create PaymentIntent → verify → Payment | Confirmed                          |
| Pay on arrival| On arrival       | Create Payment (pending)                | Pending                            |
| PayPal        | (Coming soon)    | Create Payment (pending)                | Pending                            |

This keeps the UX simple, supports “pay now” and “pay later”, and leaves room to add PayPal later without changing the overall flow.
