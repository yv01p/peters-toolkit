-- Procedure that reads/writes the same shared package variable
-- Forms a GLOBAL_STATE cluster with prc_finalize_order
-- No app caller (DB-only)
CREATE OR REPLACE PROCEDURE prc_reset_batch_totals IS
  v_old_total NUMBER;
BEGIN
  -- Read from shared package variable (GLOBAL_STATE coupling)
  v_old_total := pkg_order_state.g_batch_total;

  -- Log or archive the old total (simulated)
  NULL; -- Would normally INSERT INTO batch_totals_log...

  -- Reset the shared package variable (GLOBAL_STATE write)
  pkg_order_state.g_batch_total := 0;
  pkg_order_state.g_current_batch_id := pkg_order_state.g_current_batch_id + 1;
END prc_reset_batch_totals;
/
