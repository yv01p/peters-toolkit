package com.fleetbill.billing;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.util.logging.Logger;

/**
 * Retries a failed nightly sweep for a region. Invoked by the ops on-call
 * runbook when {@link SettlementBatchJob} reports a failure, rather than by
 * the scheduler directly. Deliberately re-implements the call rather than
 * reusing SettlementBatchJob, so the two code paths can be tuned
 * independently (different timeout, different retry/backoff policy).
 */
public class SettlementRetryRunner {

    private static final Logger LOG = Logger.getLogger(SettlementRetryRunner.class.getName());

    private final ConnectionProvider connectionProvider;

    public SettlementRetryRunner(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    public long retrySweep(String regionCode, int attempt) throws Exception {
        LOG.info("Retrying prc_settlement_sweep for region " + regionCode
                + ", attempt " + attempt);

        try (Connection conn = connectionProvider.getConnection();
             CallableStatement stmt = conn.prepareCall("{call prc_settlement_sweep(?, ?)}")) {

            stmt.setString(1, regionCode);
            stmt.registerOutParameter(2, Types.NUMERIC);
            stmt.execute();

            return stmt.getLong(2);
        }
    }
}
