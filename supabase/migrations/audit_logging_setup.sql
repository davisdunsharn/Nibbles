-- Create audit log table for tracking all system actions
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'login', 'logout', 'payment', 'restock'
  entity_type VARCHAR(50) NOT NULL, -- 'product', 'user', 'transaction', 'inventory', etc.
  entity_id UUID,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  description TEXT,
  changes JSONB, -- Store before/after values for updates
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_branch_id ON audit_logs(branch_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action_type);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS policy: Users can view audit logs for their branches
CREATE POLICY "Users can view audit logs for their branches"
  ON audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND (
        branch_id IS NULL OR 
        up.branch_id = audit_logs.branch_id OR 
        up.role = 'admin'
      )
    )
  );

-- Function to log actions
CREATE OR REPLACE FUNCTION log_audit(
  p_action_type VARCHAR,
  p_entity_type VARCHAR,
  p_entity_id UUID DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_changes JSONB DEFAULT NULL,
  p_branch_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO audit_logs (
    action_type, entity_type, entity_id, user_id, branch_id,
    description, changes, created_at
  ) VALUES (
    p_action_type, p_entity_type, p_entity_id, auth.uid(), 
    COALESCE(p_branch_id, (SELECT branch_id FROM user_profiles WHERE id = auth.uid() LIMIT 1)),
    p_description, p_changes, NOW()
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get audit trail for an entity
CREATE OR REPLACE FUNCTION get_audit_trail(
  p_entity_type VARCHAR,
  p_entity_id UUID,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  action_type VARCHAR,
  user_name VARCHAR,
  description TEXT,
  changes JSONB,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    al.id,
    al.action_type,
    CONCAT(up.first_name, ' ', up.last_name) as user_name,
    al.description,
    al.changes,
    al.created_at
  FROM audit_logs al
  LEFT JOIN user_profiles up ON al.user_id = up.id
  WHERE al.entity_type = p_entity_type
    AND al.entity_id = p_entity_id
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Audit trigger for transactions
CREATE OR REPLACE FUNCTION audit_transaction_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM log_audit(
      'create',
      'transaction',
      NEW.id,
      CONCAT('New transaction: ', NEW.receipt_number),
      json_build_object('total', NEW.total_amount, 'payment_method', NEW.payment_method),
      NEW.branch_id
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status != OLD.status THEN
      PERFORM log_audit(
        'update',
        'transaction',
        NEW.id,
        CONCAT('Status changed from ', OLD.status, ' to ', NEW.status),
        json_build_object('old_status', OLD.status, 'new_status', NEW.status),
        NEW.branch_id
      );
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM log_audit(
      'delete',
      'transaction',
      OLD.id,
      CONCAT('Transaction deleted: ', OLD.receipt_number),
      NULL,
      OLD.branch_id
    );
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Audit trigger for products
CREATE OR REPLACE FUNCTION audit_product_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM log_audit(
      'create',
      'product',
      NEW.id,
      CONCAT('New product: ', NEW.name),
      json_build_object('name', NEW.name, 'price', NEW.unit_price, 'category', NEW.category),
      NULL
    );
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM log_audit(
      'update',
      'product',
      NEW.id,
      CONCAT('Product updated: ', NEW.name),
      json_build_object(
        'old_price', OLD.unit_price,
        'new_price', NEW.unit_price,
        'old_name', OLD.name,
        'new_name', NEW.name,
        'old_active', OLD.is_active,
        'new_active', NEW.is_active
      ),
      NULL
    );
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM log_audit(
      'delete',
      'product',
      OLD.id,
      CONCAT('Product deleted: ', OLD.name),
      NULL,
      NULL
    );
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach triggers
DROP TRIGGER IF EXISTS audit_transaction_changes_trigger ON transactions;
CREATE TRIGGER audit_transaction_changes_trigger
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW EXECUTE FUNCTION audit_transaction_changes();

DROP TRIGGER IF EXISTS audit_product_changes_trigger ON products;
CREATE TRIGGER audit_product_changes_trigger
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION audit_product_changes();

-- Log initial page loads / user logins (optional - can be called from frontend)
CREATE OR REPLACE FUNCTION log_user_login()
RETURNS void AS $$
BEGIN
  PERFORM log_audit(
    'login',
    'user',
    auth.uid(),
    'User logged in'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
