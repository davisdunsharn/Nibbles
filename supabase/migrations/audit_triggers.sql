-- Automatic audit logging via triggers.
-- Logs create/update/delete on key business tables into audit_log.
-- FAIL-SAFE: any error inside the trigger is swallowed so it can NEVER
-- block or roll back the underlying business operation.

CREATE OR REPLACE FUNCTION log_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_action text;
  v_entity uuid;
  v_branch uuid;
BEGIN
  v_action := CASE TG_OP WHEN 'INSERT' THEN 'create' WHEN 'UPDATE' THEN 'update' WHEN 'DELETE' THEN 'delete' END;

  BEGIN
    v_entity := CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END;
  EXCEPTION WHEN OTHERS THEN v_entity := NULL; END;

  -- branch_id only exists on some tables
  BEGIN
    v_branch := CASE WHEN TG_OP = 'DELETE' THEN OLD.branch_id ELSE NEW.branch_id END;
  EXCEPTION WHEN OTHERS THEN v_branch := NULL; END;

  INSERT INTO audit_log (user_id, action, entity_type, entity_id, branch_id, old_value, new_value)
  VALUES (
    auth.uid(), v_action, TG_TABLE_NAME, v_entity, v_branch,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
EXCEPTION WHEN OTHERS THEN
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END; -- never block the business op
END;
$$;

-- Attach to meaningful entities (skip high-frequency inventory/iot to avoid noise).
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['transactions','purchase_orders','products','user_profiles','shifts','branches','suppliers']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%1$s ON %1$I', t);
    EXECUTE format('CREATE TRIGGER trg_audit_%1$s AFTER INSERT OR UPDATE OR DELETE ON %1$I FOR EACH ROW EXECUTE FUNCTION log_audit()', t);
  END LOOP;
END $$;
