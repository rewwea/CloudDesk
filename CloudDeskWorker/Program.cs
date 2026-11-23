
using StackExchange.Redis;

var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "redis";

while (true)
{
    try
    {
        using var redis = await ConnectionMultiplexer.ConnectAsync(redisHost);
        var db = redis.GetDatabase();
        Console.WriteLine("Worker connected to Redis");

        while (redis.IsConnected)
        {
            var item = await db.ListLeftPopAsync("ticket_events_queue");
            if (!item.IsNull)
                Console.WriteLine($"Processed: {item} | {DateTime.UtcNow:O}");
            else
                await Task.Delay(500);
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Redis unavailable: {ex.Message}");
    }

    await Task.Delay(2000);
}
