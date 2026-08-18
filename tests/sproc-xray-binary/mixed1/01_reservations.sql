-- Reservation lifecycle routines (SQL Server / T-SQL)

CREATE PROCEDURE sp_create_reservation
    @CustomerId INT,
    @VehicleId INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate >= @EndDate
    BEGIN
        RAISERROR('Start date must precede end date.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM Reservations
        WHERE VehicleId = @VehicleId
          AND NOT (@EndDate <= StartDate OR @StartDate >= EndDate)
    )
    BEGIN
        RAISERROR('Vehicle is already booked for the requested window.', 16, 1);
        RETURN;
    END

    INSERT INTO Reservations (CustomerId, VehicleId, StartDate, EndDate, Status)
    VALUES (@CustomerId, @VehicleId, @StartDate, @EndDate, 'CONFIRMED');
END
GO

CREATE PROCEDURE sp_cancel_reservation
    @ReservationId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Reservations
    SET Status = 'CANCELLED'
    WHERE ReservationId = @ReservationId;
END
GO
