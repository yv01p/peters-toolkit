CREATE OR REPLACE PACKAGE pkg_fleet_billing AS

  -- Weak ref cursor handed back to the caller by load_driver_batch.
  TYPE t_charge_cur IS REF CURSOR;

  -- Loads one driver's charge codes and returns the resulting charge rows.
  PROCEDURE load_driver_batch (
    p_driver       IN  drivers%ROWTYPE,
    p_charge_codes IN  t_charge_code_list,
    p_charges      OUT t_charge_cur
  );

  -- Totals the staged rows for a batch and stamps the batch header.
  PROCEDURE post_batch_totals (
    p_batch_id IN NUMBER
  );

END pkg_fleet_billing;
/
