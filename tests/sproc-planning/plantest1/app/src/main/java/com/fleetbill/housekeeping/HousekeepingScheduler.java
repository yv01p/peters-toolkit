package com.fleetbill.housekeeping;

import java.sql.CallableStatement;
import java.sql.Connection;

import com.fleetbill.billing.ConnectionProvider;

/**
 * Runs off-peak cleanup jobs. Currently a single job: releasing driver holds
 * that have expired.
 */
public class HousekeepingScheduler {

    private final ConnectionProvider connectionProvider;

    public HousekeepingScheduler(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    /** Runs every night at 02:00, well before {@code SettlementBatchJob}. */
    public void releaseExpiredHolds() throws Exception {
        try (Connection conn = connectionProvider.getConnection();
             CallableStatement stmt = conn.prepareCall("{call prc_purge_stale_holds}")) {
            stmt.execute();
        }
    }
}
