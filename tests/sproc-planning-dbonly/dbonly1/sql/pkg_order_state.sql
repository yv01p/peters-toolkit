-- Package to hold shared state
-- Used to demonstrate GLOBAL_STATE coupling
CREATE OR REPLACE PACKAGE pkg_order_state IS
  -- Package variable shared across routines
  g_current_batch_id NUMBER := 0;
  g_batch_total NUMBER := 0;
END pkg_order_state;
/
