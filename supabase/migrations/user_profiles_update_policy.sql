-- Admins can update any user profile (Edit User). Without this RLS policy,
-- profile updates were silently blocked (0 rows changed, no error).
DROP POLICY IF EXISTS profiles_update ON user_profiles;
CREATE POLICY profiles_update ON user_profiles
  FOR UPDATE
  USING (current_role_name() = 'admin')
  WITH CHECK (current_role_name() = 'admin');
