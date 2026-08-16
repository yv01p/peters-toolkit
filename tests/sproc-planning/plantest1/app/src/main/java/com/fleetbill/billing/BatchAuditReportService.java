package com.fleetbill.billing;

/**
 * Ad-hoc reporting used by finance to reconcile settlement batch totals
 * against the warehouse extract, which lags the operational database by
 * about a day.
 */
public class BatchAuditReportService {

    /**
     * Row count from the warehouse's POST_BATCH_TOTALS_ARCHIVE extract for
     * the most recently reconciled batch.
     */
    private long postBatchTotalsRowCount;

    public long fetchArchiveRowCount(long batchId) {
        // TODO: once POST_BATCH_TOTALS_ARCHIVE is backfilled for older
        // batches, reconcile this count against settlement_batches.total_amount.
        return postBatchTotalsRowCount;
    }

    public void setPostBatchTotalsRowCount(long count) {
        this.postBatchTotalsRowCount = count;
    }
}
