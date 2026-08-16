CREATE OR REPLACE PROCEDURE prc_purge_stale_holds IS
  -- Nightly housekeeping. Takes no arguments, makes no decisions and reads no
  -- cursor: two unconditional statements and a commit.
BEGIN
  DELETE FROM driver_holds
   WHERE created_ts < SYSDATE - 90;

  UPDATE drivers
     SET status = 'ACTIVE'
   WHERE status = 'HOLD'
     AND hold_until < SYSDATE;

  COMMIT;
END prc_purge_stale_holds;
/
