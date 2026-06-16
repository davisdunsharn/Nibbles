-- Let any staff member clock IN/OUT of their OWN shift for today.
-- SECURITY DEFINER so cashiers (who have no shifts UPDATE grant) can clock
-- themselves; scoped strictly to auth.uid()'s own shift.
CREATE OR REPLACE FUNCTION clock_shift(p_action text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_shift shifts%ROWTYPE; v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT * INTO v_shift FROM shifts
    WHERE staff_id = v_uid AND shift_date = current_date
    ORDER BY planned_start LIMIT 1;
  IF NOT FOUND THEN RETURN json_build_object('ok', false, 'message', 'No shift scheduled for you today'); END IF;
  IF p_action = 'in' THEN
    UPDATE shifts SET actual_clock_in = now(), status = 'in_progress' WHERE id = v_shift.id;
    RETURN json_build_object('ok', true, 'status', 'in_progress');
  ELSIF p_action = 'out' THEN
    UPDATE shifts SET actual_clock_out = now(), status = 'completed' WHERE id = v_shift.id;
    RETURN json_build_object('ok', true, 'status', 'completed');
  END IF;
  RETURN json_build_object('ok', false, 'message', 'Invalid action');
END; $$;
