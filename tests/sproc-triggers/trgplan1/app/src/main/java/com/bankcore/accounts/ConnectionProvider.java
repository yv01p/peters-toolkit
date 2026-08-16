package com.bankcore.accounts;

import java.sql.Connection;

/**
 * Thin seam over the connection pool so the call sites in this package can
 * be exercised without a real database. Implementation intentionally
 * omitted — this application tree exists to be read, not run.
 */
public interface ConnectionProvider {
    Connection getConnection() throws Exception;
}
