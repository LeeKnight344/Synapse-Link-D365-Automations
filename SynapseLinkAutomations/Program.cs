class Program
{
    static async Task Main(string[] args)
    {
        if (args.Length < 3)
        {
            Console.WriteLine("Usage: dotnet run <environmentGuid> <username> <password>");
            return;
        }

        string environmentGuid = args[0];
        string username = args[1];
        string password = args[2];

        string token = await BearerTokenFetcher.FetchBearerToken(environmentGuid, username, password);

        if (!string.IsNullOrEmpty(token))
        {
            Console.WriteLine("Retrieved Bearer Token:");
            Console.WriteLine(token);
        }
        else
        {
            Console.WriteLine("Failed to retrieve Bearer Token.");
        }
    }
}
