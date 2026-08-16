CREATE OR REPLACE PACKAGE BODY pkg_fleet_billing AS

  -- Package-level state. Survives for the life of the session, so two calls in
  -- the same session see each other's writes.
  g_run_total      NUMBER := 0;
  g_batch_id       NUMBER := 0;
  g_last_driver_id NUMBER;

  PROCEDURE load_driver_batch (
    p_driver       IN  drivers%ROWTYPE,
    p_charge_codes IN  t_charge_code_list,
    p_charges      OUT t_charge_cur
  ) IS
    v_region VARCHAR2(8);
  BEGIN
    v_region := SYS_CONTEXT('fleet_ctx', 'region_code');

    g_last_driver_id := p_driver.driver_id;
    g_run_total      := 0;

    FOR i IN 1 .. p_charge_codes.COUNT LOOP
      INSERT INTO charges (charge_id, driver_id, charge_code, amount, batch_id)
      VALUES (p_driver.driver_id * 1000 + i,
              p_driver.driver_id,
              p_charge_codes(i),
              0,
              NULL);
    END LOOP;

    OPEN p_charges FOR
      SELECT charge_id, charge_code, amount
        FROM charges
       WHERE driver_id = p_driver.driver_id
         AND p_driver.region_code = v_region;
  END load_driver_batch;

  PROCEDURE post_batch_totals (
    p_batch_id IN NUMBER
  ) IS
    CURSOR c_staged (cp_batch_id NUMBER) IS
      SELECT vehicle_id, trip_id, amount
        FROM tmp_settlement_stage
       WHERE batch_id = cp_batch_id;
  BEGIN
    g_batch_id  := p_batch_id;
    g_run_total := 0;

    FOR r IN c_staged(p_batch_id) LOOP
      g_run_total := g_run_total + r.amount;

      UPDATE trips
         SET settled_flag = 'Y'
       WHERE trip_id = r.trip_id;
    END LOOP;

    UPDATE settlement_batches
       SET total_amount = g_run_total
     WHERE batch_id = p_batch_id;

    COMMIT;
  END post_batch_totals;

END pkg_fleet_billing;
/
