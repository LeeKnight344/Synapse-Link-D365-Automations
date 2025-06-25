var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();
app.Urls.Add("http://*:5000");

app.Run();
