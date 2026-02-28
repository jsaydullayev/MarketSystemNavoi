using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.API
{
    public class TestRunner
    {
        public static async Task RunTestAsync(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            Console.WriteLine("STARTING TRANSACTION TEST...");

            var strategy = context.Database.CreateExecutionStrategy();
            
            try 
            {
                await strategy.ExecuteAsync(async () =>
                {
                    Console.WriteLine("Inside ExecuteAsync delegate. Attempting BeginTransactionAsync...");
                    await using var transaction = await context.Database.BeginTransactionAsync();
                    Console.WriteLine("SUCCESS! Transaction created inside ExecuteAsync.");
                    await transaction.CommitAsync();
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine("FAILED! Exception caught:");
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
