package com.bankcore.accounts.batch;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.util.logging.Logger;

import com.bankcore.accounts.ConnectionProvider;

/**
 * One-off batch job that backfills status-history rows for accounts whose
 * status was set by the legacy nightly bulk loader (a file import that
 * writes directly into the accounts table and does not go through the
 * normal status-change flow). Calls the status-logging procedure once per
 * backfilled row so the audit trail stays complete.
 */
public class StatusChangeBackfillJob {

    private static final Logger LOG = Logger.getLogger(StatusChangeBackfillJob.class.getName());

    private final ConnectionProvider connectionProvider;

    public StatusChangeBackfillJob(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    public void backfillOne(long accountId, String oldStatus, String newStatus) throws Exception {
        LOG.info("Backfilling status-log entry for account " + accountId);

        try (Connection conn = connectionProvider.getConnection();
             CallableStatement stmt = conn.prepareCall("{call prc_log_status_change(?, ?, ?)}")) {

            stmt.setLong(1, accountId);
            stmt.setString(2, oldStatus);
            stmt.setString(3, newStatus);
            stmt.execute();
        }
    }
}
