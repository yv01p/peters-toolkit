using System;
using PartsTrack.Data;
using PartsTrack.Services;

namespace PartsTrack
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            var connectionString = Environment.GetEnvironmentVariable("PARTSTRACK_CONNECTION_STRING")
                ?? "Server=localhost;Database=PartsTrack;Trusted_Connection=True;";

            var products = new ProductRepository(connectionString);
            var orders = new OrderRepository(connectionString);
            var reorderService = new InventoryReorderService();

            var lowStock = products.GetLowStock();
            Console.WriteLine($"{lowStock.Count} product(s) at or below reorder point.");

            foreach (var summary in orders.GetOrderSummaries())
            {
                Console.WriteLine($"Order {summary.OrderId}: {summary.CustomerName} - {summary.Status} - {summary.OrderTotal:C}");
            }
        }
    }
}
