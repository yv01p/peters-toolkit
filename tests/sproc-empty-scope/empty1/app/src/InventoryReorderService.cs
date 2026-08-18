using System;
using System.Collections.Generic;

namespace PartsTrack.Services
{
    /// <summary>
    /// Reorder-quantity and rush-order pricing logic lives here, in
    /// application code — not in the database. This class is the point of
    /// the fixture: PartsTrack has real business rules, but none of them
    /// are DB-resident (no stored procedures, functions, triggers, views,
    /// or logic-bearing constraints anywhere in app/db/schema.sql).
    /// </summary>
    public class InventoryReorderService
    {
        private const int TargetDaysOfStock = 30;
        private const decimal RushOrderSurchargeRate = 0.15m;

        public IEnumerable<ReorderRecommendation> BuildReorderPlan(
            IEnumerable<Data.Product> lowStockProducts,
            IDictionary<int, decimal> averageDailyDemandByProduct)
        {
            foreach (var product in lowStockProducts)
            {
                var dailyDemand = averageDailyDemandByProduct.TryGetValue(product.ProductId, out var d) ? d : 0m;
                var targetQuantity = (int)Math.Ceiling(dailyDemand * TargetDaysOfStock);
                var quantityToOrder = Math.Max(0, targetQuantity - product.QuantityOnHand);

                var isRush = product.QuantityOnHand == 0;
                var unitCost = isRush
                    ? product.UnitPrice * (1 + RushOrderSurchargeRate)
                    : product.UnitPrice;

                yield return new ReorderRecommendation
                {
                    ProductId = product.ProductId,
                    Sku = product.Sku,
                    QuantityToOrder = quantityToOrder,
                    IsRush = isRush,
                    EstimatedCost = quantityToOrder * unitCost
                };
            }
        }
    }

    public class ReorderRecommendation
    {
        public int ProductId { get; set; }
        public string Sku { get; set; }
        public int QuantityToOrder { get; set; }
        public bool IsRush { get; set; }
        public decimal EstimatedCost { get; set; }
    }
}
