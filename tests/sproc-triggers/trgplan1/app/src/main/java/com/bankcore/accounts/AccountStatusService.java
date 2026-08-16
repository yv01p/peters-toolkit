package com.bankcore.accounts;

import java.sql.CallableStatement;
import java.sql.Connection;

/**
 * Support-desk workflow for correcting an account's status-history log when
 * a customer-support agent has to insert a missing history row after a
 * manual data fix (e.g. an account whose status was corrected directly by
 * an engineer, outside the normal status-change flow). Calls the
 * status-logging procedure directly — this workflow does not itself change
 * {@code accounts.status}, it only backfills the audit-trail row.
 */
public class AccountStatusService {

    private final ConnectionProvider connectionProvider;

    public AccountStatusService(ConnectionProvider connectionProvider) {
        this.connectionProvider = connectionProvider;
    }

    /** Records a status-change entry for the given account. */
    public void recordStatusChange(long accountId, String oldStatus, String newStatus) throws Exception {
        try (Connection conn = connectionProvider.getConnection();
             CallableStatement stmt = conn.prepareCall("{call prc_log_status_change(?, ?, ?)}")) {

            stmt.setLong(1, accountId);
            stmt.setString(2, oldStatus);
            stmt.setString(3, newStatus);
            stmt.execute();
        }
    }
}
