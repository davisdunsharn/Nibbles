-- Inventory RPCs the frontend calls but which were missing on the live project.
-- Matched to the REAL inventory schema: reorder_threshold, updated_at.
-- (The repo's older inventory_setup.sql assumed reorder_level/last_updated and
--  was never applied to this project.)

-- Read: per-branch inventory with computed status. Aliased to the names the
-- frontend expects (reorder_level, last_updated). SECURITY INVOKER => RLS applies.
CREATE OR REPLACE FUNCTION get_branch_inventory(p_branch_id uuid)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  quantity_on_hand int,
  reorder_level int,
  status text,
  last_updated timestamptz
)
LANGUAGE sql
STABLE
AS $$
  SELECT i.product_id,
         p.name,
         i.quantity_on_hand,
         i.reorder_threshold,
         CASE
           WHEN i.quantity_on_hand <= 0 THEN 'out_of_stock'
           WHEN i.quantity_on_hand <= i.reorder_threshold THEN 'low_stock'
           ELSE 'in_stock'
         END,
         i.updated_at
  FROM inventory i
  JOIN products p ON p.id = i.product_id
  WHERE i.branch_id = p_branch_id
  ORDER BY p.name;
$$;

-- Add stock (manager restock / PO receive). SECURITY DEFINER so it can run for
-- callers without a direct inventory UPDATE grant; guarded by auth.uid().
CREATE OR REPLACE FUNCTION restock_inventory(p_product_id uuid, p_branch_id uuid, p_quantity int)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_new int;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  INSERT INTO inventory (branch_id, product_id, quantity_on_hand)
  VALUES (p_branch_id, p_product_id, GREATEST(p_quantity, 0))
  ON CONFLICT (branch_id, product_id)
  DO UPDATE SET quantity_on_hand = inventory.quantity_on_hand + GREATEST(p_quantity, 0),
                updated_at = now()
  RETURNING quantity_on_hand INTO v_new;
  RETURN json_build_object('success', true, 'new_quantity', v_new);
END;
$$;

-- Deduct stock on sale (POS). Clamps at 0 (table CHECK quantity_on_hand >= 0).
CREATE OR REPLACE FUNCTION deduct_inventory(p_product_id uuid, p_branch_id uuid, p_quantity int, p_transaction_id uuid DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_prev int; v_new int;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  INSERT INTO inventory (branch_id, product_id, quantity_on_hand)
  VALUES (p_branch_id, p_product_id, 0)
  ON CONFLICT (branch_id, product_id) DO NOTHING;

  SELECT quantity_on_hand INTO v_prev FROM inventory
  WHERE branch_id = p_branch_id AND product_id = p_product_id;

  v_new := GREATEST(v_prev - p_quantity, 0);
  UPDATE inventory SET quantity_on_hand = v_new, updated_at = now()
  WHERE branch_id = p_branch_id AND product_id = p_product_id;

  RETURN json_build_object('success', true, 'previous_quantity', v_prev, 'new_quantity', v_new);
END;
$$;
