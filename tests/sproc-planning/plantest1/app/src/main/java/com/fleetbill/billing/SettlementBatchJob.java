package com.fleetbill.billing;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;

/**
 * Nightly entry point for the settlement sweep. Triggered by the fleet-ops
 * scheduler once per region, once per night.
 */
public class SettlementBatchJob {

    private final ConnectionProvider connectionProvider;

    public SettlementBatchJob(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    /**
     * Runs the nightly settlement sweep for one region and returns the
     * generated batch id.
     */
    public long runNightlySweep(String regionCode) throws Exception {
        try (Connection conn = connectionProvider.getConnection();
             CallableStatement stmt = conn.prepareCall("{call PRC_Settlement_Sweep(?, ?)}")) {

            stmt.setString(1, regionCode);
            stmt.registerOutParameter(2, Types.NUMERIC);
            stmt.execute();

            return stmt.getLong(2);
        }
    }
}
