-- Manager CRUD enablement (branch-scoped)
-- Applied to the linked project via `supabase db query --linked`.

-- Allow managers (and admins) to DELETE inventory rows for their own branch.
-- Completes branch-scoped CRUD on inventory (SELECT/INSERT/UPDATE already exist).
DROP POLICY IF EXISTS inventory_delete ON inventory;
CREATE POLICY inventory_delete ON inventory
  FOR DELETE
  USING (
    current_role_name() = 'admin'
    OR (branch_id = current_branch_id() AND current_role_name() = 'manager')
  );

-- Allow managers to read staff profiles in their OWN branch only (needed to
-- assign shifts and show staff names). Additive permissive SELECT policy;
-- admins + self-access remain covered by the existing profiles_select policy.
-- Approved by the user.
DROP POLICY IF EXISTS profiles_manager_branch_select ON user_profiles;
CREATE POLICY profiles_manager_branch_select ON user_profiles
  FOR SELECT
  USING (
    current_role_name() = 'manager' AND branch_id = current_branch_id()
  );
