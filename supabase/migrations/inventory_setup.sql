-- Create inventory tracking table
CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity_on_hand INT NOT NULL DEFAULT 0,
  reorder_level INT NOT NULL DEFAULT 10,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(branch_id, product_id)
);

-- Create inventory history for audit trail
CREATE TABLE IF NOT EXISTS inventory_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id UUID NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  quantity_change INT NOT NULL,
  reason VARCHAR(50) NOT NULL, -- 'sale', 'restock', 'adjustment', 'correction'
  previous_quantity INT NOT NULL,
  new_quantity INT NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create function to deduct inventory on sale
CREATE OR REPLACE FUNCTION deduct_inventory(
  p_product_id UUID,
  p_branch_id UUID,
  p_quantity INT,
  p_transaction_id UUID DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
  v_inventory_id UUID;
  v_previous_qty INT;
  v_new_qty INT;
BEGIN
  -- Get or create inventory record
  SELECT id INTO v_inventory_id FROM inventory 
  WHERE product_id = p_product_id AND branch_id = p_branch_id;
  
  IF v_inventory_id IS NULL THEN
    INSERT INTO inventory (branch_id, product_id, quantity_on_hand)
    VALUES (p_branch_id, p_product_id, 0)
    RETURNING id INTO v_inventory_id;
  END IF;

  -- Get current quantity
  SELECT quantity_on_hand INTO v_previous_qty FROM inventory 
  WHERE id = v_inventory_id;

  v_new_qty := v_previous_qty - p_quantity;

  -- Update inventory (allow negative for overselling tracking)
  UPDATE inventory 
  SET quantity_on_hand = v_new_qty,
      last_updated = NOW()
  WHERE id = v_inventory_id;

  -- Log to history
  INSERT INTO inventory_history (
    inventory_id, transaction_id, quantity_change, reason,
    previous_quantity, new_quantity, created_by
  ) VALUES (
    v_inventory_id, p_transaction_id, -p_quantity, 'sale',
    v_previous_qty, v_new_qty, auth.uid()
  );

  RETURN json_build_object(
    'success', true,
    'inventory_id', v_inventory_id,
    'previous_quantity', v_previous_qty,
    'new_quantity', v_new_qty,
    'low_stock', v_new_qty <= (SELECT reorder_level FROM inventory WHERE id = v_inventory_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to restock inventory
CREATE OR REPLACE FUNCTION restock_inventory(
  p_product_id UUID,
  p_branch_id UUID,
  p_quantity INT
) RETURNS JSON AS $$
DECLARE
  v_inventory_id UUID;
  v_previous_qty INT;
  v_new_qty INT;
BEGIN
  SELECT id INTO v_inventory_id FROM inventory 
  WHERE product_id = p_product_id AND branch_id = p_branch_id;
  
  IF v_inventory_id IS NULL THEN
    INSERT INTO inventory (branch_id, product_id, quantity_on_hand)
    VALUES (p_branch_id, p_product_id, p_quantity)
    RETURNING id INTO v_inventory_id;
    
    v_previous_qty := 0;
    v_new_qty := p_quantity;
  ELSE
    SELECT quantity_on_hand INTO v_previous_qty FROM inventory WHERE id = v_inventory_id;
    v_new_qty := v_previous_qty + p_quantity;
    
    UPDATE inventory 
    SET quantity_on_hand = v_new_qty,
        last_updated = NOW()
    WHERE id = v_inventory_id;
  END IF;

  INSERT INTO inventory_history (
    inventory_id, quantity_change, reason,
    previous_quantity, new_quantity, created_by
  ) VALUES (
    v_inventory_id, p_quantity, 'restock',
    v_previous_qty, v_new_qty, auth.uid()
  );

  RETURN json_build_object(
    'success', true,
    'new_quantity', v_new_qty
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get inventory by branch
CREATE OR REPLACE FUNCTION get_branch_inventory(p_branch_id UUID)
RETURNS TABLE (
  product_id UUID,
  product_name VARCHAR,
  quantity_on_hand INT,
  reorder_level INT,
  status VARCHAR,
  last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.product_id,
    p.name,
    i.quantity_on_hand,
    i.reorder_level,
    CASE 
      WHEN i.quantity_on_hand <= 0 THEN 'out_of_stock'
      WHEN i.quantity_on_hand <= i.reorder_level THEN 'low_stock'
      ELSE 'in_stock'
    END as status,
    i.last_updated
  FROM inventory i
  JOIN products p ON i.product_id = p.id
  WHERE i.branch_id = p_branch_id
  ORDER BY p.name;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_inventory_branch_product ON inventory(branch_id, product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_status ON inventory(branch_id, quantity_on_hand);
CREATE INDEX IF NOT EXISTS idx_inventory_history_transaction ON inventory_history(transaction_id);
CREATE INDEX IF NOT EXISTS idx_inventory_history_created ON inventory_history(created_at DESC);

-- Enable RLS
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_history ENABLE ROW LEVEL SECURITY;

-- RLS policies for inventory
CREATE POLICY "Users can view inventory for their branches"
  ON inventory FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND (up.branch_id = inventory.branch_id OR up.role = 'admin')
    )
  );

CREATE POLICY "Managers and admins can update inventory"
  ON inventory FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND (up.role IN ('manager', 'admin') AND up.branch_id = inventory.branch_id)
    )
  );

CREATE POLICY "Users can view inventory history for their branches"
  ON inventory_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      JOIN inventory i ON i.id = inventory_history.inventory_id
      WHERE up.id = auth.uid() AND (up.branch_id = i.branch_id OR up.role = 'admin')
    )
  );

-- Initialize inventory for all products in all branches with default quantities
INSERT INTO inventory (branch_id, product_id, quantity_on_hand, reorder_level)
SELECT b.id, p.id, 50, 10
FROM branches b
CROSS JOIN products p
ON CONFLICT (branch_id, product_id) DO NOTHING;
