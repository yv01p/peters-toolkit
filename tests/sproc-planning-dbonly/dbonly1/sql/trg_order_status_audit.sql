-- Trigger that fires on external DML (not in corpus)
-- Invokes prc_finalize_order when an order status changes to 'APPROVED'
-- This makes prc_finalize_order a confirmed-live entry point via trigger cascade
CREATE OR REPLACE TRIGGER trg_order_status_audit
  AFTER UPDATE OF status ON orders
  FOR EACH ROW
DECLARE
  v_tax_rate CONSTANT NUMBER := 0.08;
BEGIN
  IF :NEW.status = 'APPROVED' AND :OLD.status != 'APPROVED' THEN
    -- Trigger cascade: invokes prc_finalize_order
    prc_finalize_order(:NEW.order_id, :NEW.amount, v_tax_rate);
  END IF;
END trg_order_status_audit;
/
