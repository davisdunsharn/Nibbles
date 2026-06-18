-- Collaboration / knowledge-sharing tool: team announcement board.
-- Admins & managers post; everyone in the org (or a branch) reads.
CREATE TABLE IF NOT EXISTS announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  author_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  audience text NOT NULL DEFAULT 'all' CHECK (audience IN ('all','branch')),
  branch_id uuid REFERENCES branches(id) ON DELETE CASCADE,
  is_pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_announcements_created ON announcements(created_at DESC);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Read: org-wide posts visible to everyone; branch posts to that branch; admin sees all.
DROP POLICY IF EXISTS announcements_select ON announcements;
CREATE POLICY announcements_select ON announcements FOR SELECT
  USING (
    current_role_name() = 'admin'
    OR audience = 'all'
    OR branch_id = current_branch_id()
  );

-- Post: admins and managers only, as themselves.
DROP POLICY IF EXISTS announcements_insert ON announcements;
CREATE POLICY announcements_insert ON announcements FOR INSERT
  WITH CHECK (
    current_role_name() IN ('admin','manager') AND author_id = auth.uid()
  );

-- Delete: author or admin.
DROP POLICY IF EXISTS announcements_delete ON announcements;
CREATE POLICY announcements_delete ON announcements FOR DELETE
  USING (current_role_name() = 'admin' OR author_id = auth.uid());

-- Seed a few realistic posts (idempotent-ish: only if empty)
INSERT INTO announcements (title, body, author_id, audience, branch_id, is_pinned, created_at)
SELECT * FROM (VALUES
  ('Welcome to the new Nibbles system 🎉','All branches are now live on the Nibbles management system. Please clock in via the POS each shift and report any stock issues through Inventory.', 'ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420'::uuid, 'all', NULL::uuid, true, now() - interval '2 days'),
  ('Public holiday trading hours','We will trade 08:00–14:00 on the upcoming public holiday. Managers, please adjust the weekly shift schedule accordingly.', 'ccdf7dfd-4b0c-4c8e-bb7c-55d775f73420'::uuid, 'all', NULL::uuid, false, now() - interval '20 hours'),
  ('Gateway: new croissant supplier','Gateway Umhlanga is switching to the new pastry supplier from Monday. Please scan all incoming stock so inventory stays accurate.', 'a5371ea1-7b76-4058-a87e-1eda67df4e93'::uuid, 'branch', '5179a5a3-9d62-49a2-b047-1cc4a0ab316a'::uuid, false, now() - interval '5 hours')
) v
WHERE NOT EXISTS (SELECT 1 FROM announcements);
