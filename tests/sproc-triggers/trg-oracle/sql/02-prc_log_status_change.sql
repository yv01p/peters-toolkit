-- Standalone procedure. Called from the trigger body below (the trigger's
-- firing DML cascades into this procedure). Zero branches, zero cursor
-- loops -- a plain insert.
CREATE OR REPLACE PROCEDURE prc_log_status_change (
    p_account_id  IN NUMBER,
    p_old_status  IN VARCHAR2,
    p_new_status  IN VARCHAR2
) IS
BEGIN
    INSERT INTO account_status_log (log_id, account_id, old_status, new_status, changed_at)
    VALUES (seq_status_log.NEXTVAL, p_account_id, p_old_status, p_new_status, SYSDATE);
END prc_log_status_change;
/
