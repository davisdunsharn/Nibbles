-- Run this in Supabase SQL Editor to debug user issues

-- Check all users in auth
SELECT id, email, email_confirmed_at, created_at 
FROM auth.users 
ORDER BY created_at DESC;

-- Check all user profiles
SELECT id, first_name, last_name, role, branch_id, is_active, created_at 
FROM user_profiles 
ORDER BY created_at DESC;

-- Find users that exist in profiles but NOT in auth
SELECT p.id, p.first_name, p.last_name, p.email, p.role
FROM user_profiles p
LEFT JOIN auth.users a ON p.id = a.id
WHERE a.id IS NULL;

-- Find users that exist in auth but NOT in profiles
SELECT a.id, a.email, a.email_confirmed_at
FROM auth.users a
LEFT JOIN user_profiles p ON a.id = p.id
WHERE p.id IS NULL;
