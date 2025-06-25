using OpenQA.Selenium;
using OpenQA.Selenium.Edge;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Titanium.Web.Proxy;
using Titanium.Web.Proxy.EventArguments;
using Titanium.Web.Proxy.Models;

public class BearerTokenFetcher
{
    private static string bearerToken = null;
    private static ProxyServer proxyServer;
    private static ExplicitProxyEndPoint explicitEndPoint;

    public static async Task<string> FetchBearerToken(string environmentGuid, string username, string password)
    {
        string url = $"https://make.powerapps.com/environments/{environmentGuid}/exporttodatalake";

        proxyServer = new ProxyServer();
        explicitEndPoint = new ExplicitProxyEndPoint(System.Net.IPAddress.Any, 8000, true);
        proxyServer.AddEndPoint(explicitEndPoint);
        proxyServer.BeforeRequest += OnRequestCapture;
        proxyServer.Start();
        proxyServer.SetAsSystemProxy(explicitEndPoint, ProxyProtocolType.Http | ProxyProtocolType.Https);

        var options = new EdgeOptions();
        options.AddArgument("--proxy-server=127.0.0.1:8000");
        options.AddArgument("--headless=new");
        options.AddArgument("--disable-gpu");   
        options.AddArgument("start-maximized"); 
        options.AcceptInsecureCertificates = true;


        using var driver = new EdgeDriver(options);

        try
        {
            driver.Navigate().GoToUrl(url);
            Thread.Sleep(5000);

            var emailBox = driver.FindElement(By.Name("loginfmt"));
            emailBox.SendKeys(username);
            driver.FindElement(By.Id("idSIButton9")).Click();
            Thread.Sleep(5000);

            var passwordBox = driver.FindElement(By.Name("Password"));
            passwordBox.SendKeys(password);
            Thread.Sleep(5000);

            driver.FindElement(By.Id("submitButton")).Click();
            Thread.Sleep(5000);

            try
            {
                var staySignedInBtn = driver.FindElement(By.Id("idBtn_Back"));
                staySignedInBtn.Click();
                Thread.Sleep(5000);
            }
            catch { }

            await Task.Delay(30000);
            return bearerToken;
        }
        finally
        {
            driver.Quit();
            proxyServer.Stop();
        }
    }

    private static async Task OnRequestCapture(object sender, SessionEventArgs e)
    {
        try
        {
            var request = e.HttpClient.Request;
            if (request.Url.Contains("lakedetails?fetchLakehouseInfo=true", StringComparison.OrdinalIgnoreCase))
            {
                var authHeader = request.Headers.FirstOrDefault(h => h.Name.Equals("Authorization", StringComparison.OrdinalIgnoreCase))?.Value;
                if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                {
                    bearerToken = authHeader.Substring("Bearer ".Length);
                    Console.WriteLine("Bearer Token Captured.");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Request Error] {ex.Message}");
        }
    }
}
