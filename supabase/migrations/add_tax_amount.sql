-- Add VAT/tax tracking to transactions (South Africa standard rate = 15%).
-- The POS already sends a tax_amount on each sale; this column was missing,
-- which silently broke checkout. Adds the column and back-fills history.

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS tax_amount numeric NOT NULL DEFAULT 0;

-- Back-fill legacy rows that never separated VAT (total == subtotal):
-- treat the recorded total as VAT-inclusive, extract the 15% VAT component,
-- and set subtotal to the net amount so subtotal + tax_amount = total_amount.
UPDATE transactions
SET tax_amount = ROUND(total_amount - (total_amount / 1.15), 2),
    subtotal   = ROUND(total_amount / 1.15, 2)
WHERE tax_amount = 0
  AND ABS(total_amount - subtotal) < 0.01;
