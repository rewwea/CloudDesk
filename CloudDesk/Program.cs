
using Npgsql;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.Use(async (context, next) =>
{
    Console.WriteLine($"{context.Request.Method} {context.Request.Path}");
    await next();
});

var cs = builder.Configuration.GetConnectionString("Default")!;

NpgsqlConnection Db() => new(cs);

bool Valid(Ticket t) =>
    !string.IsNullOrWhiteSpace(t.Title) &&
    t.Title.Length is >= 3 and <= 120 &&
    !string.IsNullOrWhiteSpace(t.Description) &&
    t.Priority is >= 1 and <= 3 &&
    t.Status is "new" or "in_progress" or "done";

app.MapGet("/", () => new { name = "CloudDesk", version = "1.1" });

app.MapGet("/health", async () =>
{
    try
    {
        await using var db = Db();
        await db.OpenAsync();
        await using var cmd = new NpgsqlCommand("SELECT 1", db);
        await cmd.ExecuteScalarAsync();
        return Results.Ok(new { status = "ok", database = "connected" });
    }
    catch
    {
        return Results.Json(new { status = "error" }, statusCode: 503);
    }
});

app.MapGet("/api/tickets", async (
    string? status, int? priority, string? q,
    string? sort, int? page, int? pageSize) =>
{
    if (status != null && status is not ("new" or "in_progress" or "done"))
        return Results.BadRequest(new { error = "Invalid status" });
    if (priority != null && priority is < 1 or > 3)
        return Results.BadRequest(new { error = "Invalid priority" });
    if (sort != null && sort is not ("asc" or "desc"))
        return Results.BadRequest(new { error = "Invalid sort" });
    if (page is < 1 || pageSize is < 1 or > 100)
        return Results.BadRequest(new { error = "Invalid pagination" });

    int p = page ?? 1, size = pageSize ?? 10;
    if ((long)(p - 1) * size > int.MaxValue)
        return Results.BadRequest(new { error = "Page too large" });

    var filters = new List<string>();
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand { Connection = db };

    if (status != null)
    {
        filters.Add("status = @status");
        cmd.Parameters.AddWithValue("status", status);
    }
    if (priority != null)
    {
        filters.Add("priority = @priority");
        cmd.Parameters.AddWithValue("priority", priority.Value);
    }
    if (!string.IsNullOrWhiteSpace(q))
    {
        filters.Add("title ILIKE '%' || @q || '%'");
        cmd.Parameters.AddWithValue("q", q);
    }

    string where = filters.Count == 0 ? "" : " WHERE " + string.Join(" AND ", filters);
    cmd.CommandText = "SELECT COUNT(*) FROM tickets" + where;
    long total = (long)(await cmd.ExecuteScalarAsync())!;

    string order = sort == "asc" ? "ASC" : "DESC";
    cmd.CommandText = $"""
        SELECT row_to_json(t)::text FROM (
            SELECT id, title, description, priority, status, created_at
            FROM tickets {where}
            ORDER BY created_at {order}, id {order}
            LIMIT @limit OFFSET @offset
        ) t
        """;
    cmd.Parameters.AddWithValue("limit", size);
    cmd.Parameters.AddWithValue("offset", (p - 1) * size);

    var tickets = new List<System.Text.Json.JsonElement>();
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
        tickets.Add(System.Text.Json.JsonSerializer.Deserialize<System.Text.Json.JsonElement>(reader.GetString(0)));

    return Results.Ok(new { total, page = p, pageSize = size, tickets });
});

app.MapGet("/api/tickets/{id:int}", async (int id) =>
{
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand(
        "SELECT row_to_json(t)::text FROM (SELECT * FROM tickets WHERE id = @id) t", db);
    cmd.Parameters.AddWithValue("id", id);
    var result = await cmd.ExecuteScalarAsync();
    return result == null
        ? Results.NotFound()
        : Results.Content((string)result, "application/json");
});

app.MapPost("/api/tickets", async (Ticket t) =>
{
    if (!Valid(t)) return Results.BadRequest(new { error = "Invalid ticket" });
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand("""
        INSERT INTO tickets (title, description, priority, status)
        VALUES (@title, @description, @priority, @status) RETURNING id
        """, db);
    AddTicketParams(cmd, t);
    int id = (int)(await cmd.ExecuteScalarAsync())!;
    return Results.Created($"/api/tickets/{id}", new { id });
});

app.MapPut("/api/tickets/{id:int}", async (int id, Ticket t) =>
{
    if (!Valid(t)) return Results.BadRequest(new { error = "Invalid ticket" });
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand("""
        UPDATE tickets SET title=@title, description=@description,
        priority=@priority, status=@status WHERE id=@id
        """, db);
    cmd.Parameters.AddWithValue("id", id);
    AddTicketParams(cmd, t);
    return await cmd.ExecuteNonQueryAsync() == 0
        ? Results.NotFound() : Results.Ok(new { message = "Updated" });
});

app.MapDelete("/api/tickets/{id:int}", async (int id) =>
{
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand("DELETE FROM tickets WHERE id=@id", db);
    cmd.Parameters.AddWithValue("id", id);
    return await cmd.ExecuteNonQueryAsync() == 0
        ? Results.NotFound() : Results.NoContent();
});

app.MapGet("/api/stats", async () =>
{
    await using var db = Db();
    await db.OpenAsync();
    await using var cmd = new NpgsqlCommand("""
        SELECT COUNT(*),
        COUNT(*) FILTER (WHERE status='new'),
        COUNT(*) FILTER (WHERE status='in_progress'),
        COUNT(*) FILTER (WHERE status='done')
        FROM tickets
        """, db);
    await using var r = await cmd.ExecuteReaderAsync();
    await r.ReadAsync();
    return Results.Ok(new {
        total = r.GetInt64(0),
        newTickets = r.GetInt64(1),
        inProgress = r.GetInt64(2),
        done = r.GetInt64(3)
    });
});

app.Run();

void AddTicketParams(NpgsqlCommand cmd, Ticket t)
{
    cmd.Parameters.AddWithValue("title", t.Title);
    cmd.Parameters.AddWithValue("description", t.Description);
    cmd.Parameters.AddWithValue("priority", t.Priority);
    cmd.Parameters.AddWithValue("status", t.Status);
}

record Ticket(string Title, string Description, int Priority, string Status);
