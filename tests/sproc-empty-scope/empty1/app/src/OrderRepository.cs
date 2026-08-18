using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;

namespace PartsTrack.Data
{
    public class OrderRepository
    {
        private readonly string _connectionString;

        public OrderRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public int CreateOrder(int customerId, IEnumerable<(int ProductId, int Quantity, decimal LineTotal)> lines)
        {
            using var conn = new SqlConnection(_connectionString);
            conn.Open();
            using var tx = conn.BeginTransaction();

            int orderId;
            using (var cmd = new SqlCommand(@"
                INSERT INTO dbo.Orders (CustomerId, OrderDate, Status)
                OUTPUT INSERTED.OrderId
                VALUES (@CustomerId, @OrderDate, @Status)", conn, tx))
            {
                cmd.Parameters.AddWithValue("@CustomerId", customerId);
                cmd.Parameters.AddWithValue("@OrderDate", DateTime.UtcNow);
                cmd.Parameters.AddWithValue("@Status", "OPEN");
                orderId = (int)cmd.ExecuteScalar();
            }

            foreach (var line in lines)
            {
                using var cmd = new SqlCommand(@"
                    INSERT INTO dbo.OrderLines (OrderId, ProductId, Quantity, LineTotal)
                    VALUES (@OrderId, @ProductId, @Quantity, @LineTotal)", conn, tx);
                cmd.Parameters.AddWithValue("@OrderId", orderId);
                cmd.Parameters.AddWithValue("@ProductId", line.ProductId);
                cmd.Parameters.AddWithValue("@Quantity", line.Quantity);
                cmd.Parameters.AddWithValue("@LineTotal", line.LineTotal);
                cmd.ExecuteNonQuery();
            }

            tx.Commit();
            return orderId;
        }

        public void MarkShipped(int orderId)
        {
            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                UPDATE dbo.Orders
                SET Status = @Status
                WHERE OrderId = @OrderId", conn);
            cmd.Parameters.AddWithValue("@Status", "SHIPPED");
            cmd.Parameters.AddWithValue("@OrderId", orderId);
            cmd.ExecuteNonQuery();
        }

        public List<(int OrderId, string CustomerName, string Status, decimal OrderTotal)> GetOrderSummaries()
        {
            var results = new List<(int, string, string, decimal)>();

            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                SELECT o.OrderId, c.CustomerName, o.Status, SUM(ol.LineTotal) AS OrderTotal
                FROM dbo.Orders o
                JOIN dbo.Customers c ON c.CustomerId = o.CustomerId
                JOIN dbo.OrderLines ol ON ol.OrderId = o.OrderId
                GROUP BY o.OrderId, c.CustomerName, o.Status", conn);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                results.Add((reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetDecimal(3)));
            }

            return results;
        }
    }
}
