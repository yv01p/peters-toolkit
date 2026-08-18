-- Billing calculation routine (SQL Server / T-SQL)

CREATE FUNCTION fn_compute_rental_total
(
    @DailyRate DECIMAL(10,2),
    @Days INT,
    @InsuranceOptIn BIT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Total DECIMAL(10,2);
    SET @Total = @DailyRate * @Days;

    IF @InsuranceOptIn = 1
    BEGIN
        SET @Total = @Total + (@Days * 12.50);
    END

    RETURN @Total;
END
GO
