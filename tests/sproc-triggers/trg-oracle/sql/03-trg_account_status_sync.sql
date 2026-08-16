-- Row-level trigger on accounts.status. Body: one cursor loop over
-- account_holds, one conditional and one CASE-expression branch arm, and
-- a call into the standalone procedure above (the trigger cascade).
--
-- The REFERENCING clause and the firing-condition clause in the header
-- below are part of the trigger's HEADER, not its body -- neither counts
-- as a branch, even though a naive keyword search matches the header
-- clause on the same keyword that also marks a CASE branch arm.
CREATE OR REPLACE TRIGGER trg_account_status_sync
    BEFORE UPDATE OF status ON accounts
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
    WHEN (NEW.status != OLD.status)
DECLARE
    v_open_holds account_holds.hold_amount%TYPE;
BEGIN
    IF :NEW.status = 'CLOSED' THEN
        SELECT NVL(SUM(hold_amount), 0)
          INTO v_open_holds
          FROM account_holds
         WHERE account_id = :NEW.account_id
           AND released = 'N';

        FOR h IN (SELECT hold_id
                    FROM account_holds
                   WHERE account_id = :NEW.account_id
                     AND released = 'N') LOOP
            UPDATE account_holds
               SET released = 'Y'
             WHERE hold_id = h.hold_id;
        END LOOP;
    END IF;

    UPDATE accounts
       SET risk_flag = CASE WHEN :NEW.status = 'FROZEN' THEN 'Y' ELSE 'N' END
     WHERE account_id = :NEW.account_id;

    prc_log_status_change(:NEW.account_id, :OLD.status, :NEW.status);
END;
/
