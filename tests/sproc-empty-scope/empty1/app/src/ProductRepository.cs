using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;

namespace PartsTrack.Data
{
    public class ProductRepository
    {
        private readonly string _connectionString;

        public ProductRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public Product GetById(int productId)
        {
            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                SELECT ProductId, Sku, Name, UnitPrice, QuantityOnHand, ReorderPoint, CreatedAt
                FROM dbo.Products
                WHERE ProductId = @ProductId", conn);
            cmd.Parameters.AddWithValue("@ProductId", productId);

            using var reader = cmd.ExecuteReader();
            if (!reader.Read())
            {
                return null;
            }

            return new Product
            {
                ProductId = reader.GetInt32(0),
                Sku = reader.GetString(1),
                Name = reader.GetString(2),
                UnitPrice = reader.GetDecimal(3),
                QuantityOnHand = reader.GetInt32(4),
                ReorderPoint = reader.GetInt32(5),
                CreatedAt = reader.GetDateTime(6)
            };
        }

        public List<Product> GetLowStock()
        {
            var results = new List<Product>();

            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                SELECT ProductId, Sku, Name, UnitPrice, QuantityOnHand, ReorderPoint, CreatedAt
                FROM dbo.Products
                WHERE QuantityOnHand <= ReorderPoint
                ORDER BY Sku", conn);

            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                results.Add(new Product
                {
                    ProductId = reader.GetInt32(0),
                    Sku = reader.GetString(1),
                    Name = reader.GetString(2),
                    UnitPrice = reader.GetDecimal(3),
                    QuantityOnHand = reader.GetInt32(4),
                    ReorderPoint = reader.GetInt32(5),
                    CreatedAt = reader.GetDateTime(6)
                });
            }

            return results;
        }

        public void AdjustStock(int productId, int delta)
        {
            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                UPDATE dbo.Products
                SET QuantityOnHand = QuantityOnHand + @Delta
                WHERE ProductId = @ProductId", conn);
            cmd.Parameters.AddWithValue("@Delta", delta);
            cmd.Parameters.AddWithValue("@ProductId", productId);
            cmd.ExecuteNonQuery();
        }

        public int Insert(Product product)
        {
            using var conn = new SqlConnection(_connectionString);
            conn.Open();

            using var cmd = new SqlCommand(@"
                INSERT INTO dbo.Products (Sku, Name, UnitPrice, QuantityOnHand, ReorderPoint, CreatedAt)
                OUTPUT INSERTED.ProductId
                VALUES (@Sku, @Name, @UnitPrice, @QuantityOnHand, @ReorderPoint, @CreatedAt)", conn);
            cmd.Parameters.AddWithValue("@Sku", product.Sku);
            cmd.Parameters.AddWithValue("@Name", product.Name);
            cmd.Parameters.AddWithValue("@UnitPrice", product.UnitPrice);
            cmd.Parameters.AddWithValue("@QuantityOnHand", product.QuantityOnHand);
            cmd.Parameters.AddWithValue("@ReorderPoint", product.ReorderPoint);
            cmd.Parameters.AddWithValue("@CreatedAt", DateTime.UtcNow);

            return (int)cmd.ExecuteScalar();
        }
    }

    public class Product
    {
        public int ProductId { get; set; }
        public string Sku { get; set; }
        public string Name { get; set; }
        public decimal UnitPrice { get; set; }
        public int QuantityOnHand { get; set; }
        public int ReorderPoint { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
