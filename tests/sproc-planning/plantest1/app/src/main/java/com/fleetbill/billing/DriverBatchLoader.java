package com.fleetbill.billing;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Types;

/**
 * Loads one driver's pending charge codes ahead of a settlement run and
 * hands the resulting charge rows back to the batch-prep UI.
 */
public class DriverBatchLoader {

    private final ConnectionProvider connectionProvider;

    public DriverBatchLoader(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    public ResultSet loadPendingCharges(Object driverRow, Object[] chargeCodes) throws Exception {
        Connection conn = connectionProvider.getConnection();
        CallableStatement stmt = conn.prepareCall(
                "{call PKG_FLEET_BILLING.LOAD_DRIVER_BATCH(?, ?, ?)}");

        stmt.setObject(1, driverRow);
        stmt.setObject(2, chargeCodes);
        stmt.registerOutParameter(3, Types.REF_CURSOR);
        stmt.execute();

        return (ResultSet) stmt.getObject(3);
    }
}
