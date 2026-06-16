-- ============================================================================
-- Nibbles Bakery — IoT / Operations demo data
-- Seeds REAL rows into iot_events, purchase_orders and notifications so the
-- Production & Operations Hub renders live data (no hard-coded values).
-- Safe to re-run: seeded rows are tagged and removed first.
-- Timestamps are relative to now() so "today" metrics always populate.
-- ============================================================================

-- Branch / product / people IDs (from the live database)
--  Dr A B Xuma : 9b6d12e7-679f-4955-adf1-4ded27a52f71
--  Gateway     : 5179a5a3-9d62-49a2-b047-1cc4a0ab316a
--  West street : dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c
--  White loaf  : 1cfe344a-48ee-4eda-bef0-51f3d4d85314
--  Custard     : 96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1
--  Supplier    : ff68a714-a8c0-490e-9384-a55629c53255
--  Admin       : ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420

-- ---- clean previously seeded rows -----------------------------------------
DELETE FROM iot_events WHERE device_id LIKE 'RFID-%';
DELETE FROM purchase_order_lines
  WHERE purchase_order_id IN (SELECT id FROM purchase_orders WHERE notes LIKE 'SEED:%');
DELETE FROM purchase_orders WHERE notes LIKE 'SEED:%';
DELETE FROM notifications
  WHERE recipient_id = 'ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420'
    AND type IN ('iot_anomaly','low_stock','order_received');

-- ---- IoT scan events -------------------------------------------------------
-- event_type ∈ stock_in | stock_out | stock_check | unknown
INSERT INTO iot_events
  (branch_id, product_id, sku_scanned, event_type, quantity, device_id, is_anomaly, anomaly_reason, processed, created_at)
VALUES
  -- today: production / goods-in scans (drive "Stock-In Today")
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_in',240,'RFID-XUMA-01',false,null,true, now() - interval '1 hour'),
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_in',300,'RFID-GW-01',  false,null,true, now() - interval '2 hours'),
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_in',120,'RFID-GW-02', false,null,true, now() - interval '3 hours'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_in',90,'RFID-WST-01', false,null,true, now() - interval '4 hours'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_in',180,'RFID-WST-02', false,null,true, now() - interval '5 hours'),
  -- today: point-of-sale stock-out scans
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_out',12,'RFID-GW-01', false,null,true, now() - interval '30 minutes'),
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_out',6,'RFID-XUMA-02', false,null,true, now() - interval '45 minutes'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_out',9,'RFID-WST-01', false,null,true, now() - interval '90 minutes'),
  -- today: a stock-take audit scan
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_check',58,'RFID-XUMA-01', false,null,true, now() - interval '6 hours'),
  -- today: anomalies (drive System Alerts)
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_out',40,'RFID-GW-02', true,'Stock-out spike: 40 units in one scan vs avg 6', false, now() - interval '20 minutes'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c',null,'UNKNOWN-SKU-7781','unknown',1,'RFID-WST-02', true,'Unregistered SKU scanned at till', false, now() - interval '70 minutes'),
  -- yesterday
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_in',280,'RFID-GW-01', false,null,true, now() - interval '1 day 2 hours'),
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_in',110,'RFID-XUMA-02', false,null,true, now() - interval '1 day 3 hours'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_out',15,'RFID-WST-01', false,null,true, now() - interval '1 day 5 hours'),
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','1cfe344a-48ee-4eda-bef0-51f3d4d85314','NB-BRD-001','stock_check',62,'RFID-XUMA-01', false,null,true, now() - interval '1 day 8 hours'),
  -- 2 days ago
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_in',130,'RFID-GW-02', false,null,true, now() - interval '2 days 4 hours'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','96bbfda4-2c5c-4d93-ac91-8ce8bb3860b1','NB-CAKE-001','stock_out',8,'RFID-WST-02', false,null,true, now() - interval '2 days 6 hours');

-- ---- Scheduled deliveries (purchase orders) --------------------------------
-- status ∈ pending | sent | confirmed | partially_received | received | cancelled
INSERT INTO purchase_orders
  (branch_id, supplier_id, raised_by, status, is_auto_generated, expected_delivery, notes, total_value, created_at)
VALUES
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','ff68a714-a8c0-490e-9384-a55629c53255','a5371ea1-7b76-4058-a87e-1eda67df4e93','confirmed', true,  CURRENT_DATE + 1, 'SEED: weekly flour & yeast restock', 4250.00, now() - interval '1 day'),
  ('9b6d12e7-679f-4955-adf1-4ded27a52f71','ff68a714-a8c0-490e-9384-a55629c53255','6065a67d-4343-4c35-9140-5ff67527fd19','sent',      false, CURRENT_DATE + 2, 'SEED: custard powder & sugar',        2180.00, now() - interval '12 hours'),
  ('dfc91b0b-86fb-4723-ad64-d2ca71f0eb9c','ff68a714-a8c0-490e-9384-a55629c53255','8ce3d426-71cd-4646-8c45-cd2243edf2ee','pending',   true,  CURRENT_DATE + 4, 'SEED: auto-reorder — bread flour low', 3600.00, now() - interval '4 hours'),
  ('5179a5a3-9d62-49a2-b047-1cc4a0ab316a','ff68a714-a8c0-490e-9384-a55629c53255','a5371ea1-7b76-4058-a87e-1eda67df4e93','received',  false, CURRENT_DATE - 1, 'SEED: packaging & boxes',             1490.00, now() - interval '3 days');

-- one order line per seeded PO (for realistic totals)
INSERT INTO purchase_order_lines (purchase_order_id, product_id, quantity_ordered, quantity_received, unit_cost, line_total)
SELECT po.id, '1cfe344a-48ee-4eda-bef0-51f3d4d85314', 500,
       CASE WHEN po.status = 'received' THEN 500 ELSE 0 END, 8.50, 4250.00
FROM purchase_orders po WHERE po.notes LIKE 'SEED:%';

-- ---- System alerts / notifications ----------------------------------------
-- type ∈ low_stock | order_received | staff_absent | transaction_voided | iot_anomaly | daily_report
INSERT INTO notifications (recipient_id, type, title, body, is_read, created_at)
VALUES
  ('ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420','iot_anomaly','Unusual stock-out detected','Gateway Umhlanga: 40 Custard units scanned out in a single event (avg is 6). Possible mis-scan or theft.', false, now() - interval '20 minutes'),
  ('ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420','iot_anomaly','Unregistered SKU scanned','West street: device RFID-WST-02 scanned an unknown SKU (UNKNOWN-SKU-7781).', false, now() - interval '70 minutes'),
  ('ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420','low_stock','Bread flour running low','West street is below reorder level on bread flour — auto purchase order raised.', false, now() - interval '4 hours'),
  ('ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420','order_received','Delivery received','Gateway Umhlanga received packaging & boxes order from Sprinkles and Frosting.', true, now() - interval '3 days');
