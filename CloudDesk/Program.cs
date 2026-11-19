
var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/", () => new
{
    name = "CloudDesk",
    message = "Support ticket API",
    version = "1.0"
});

app.MapGet("/health", () => Results.Ok(new
{
    status = "ok",
    service = "CloudDesk"
}));

app.Run();
