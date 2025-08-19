using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Titanium.Web.Proxy;
using Titanium.Web.Proxy.EventArguments;
using Titanium.Web.Proxy.Models;

namespace SynapseLinkAutomations.Core.Services
{
    public class BearerTokenFetcher
    {
        private static string bearerToken;
        private static ProxyServer proxyServer;
        private static ExplicitProxyEndPoint explicitEndPoint;

        public static async Task<string> FetchBearerToken(string environmentGuid, string username, string password)
        {
            string url = $"https://make.powerapps.com/environments/{environmentGuid}/exporttodatalake";
            bearerToken = null;

            proxyServer = new ProxyServer();
            proxyServer.CertificateManager.SaveFakeCertificates = true;
            proxyServer.EnableHttp2 = true; // OK with MITM in most cases

            explicitEndPoint = new ExplicitProxyEndPoint(IPAddress.Loopback, 8000, true);
            proxyServer.AddEndPoint(explicitEndPoint);
            proxyServer.BeforeRequest += OnRequestCapture;
            proxyServer.Start();

            var options = new ChromeOptions();
            options.AddArgument("--headless=new");
            options.AddArgument("--disable-gpu");
            options.AddArgument("--no-sandbox");
            options.AddArgument("--disable-dev-shm-usage");
            options.AddArgument("--ignore-certificate-errors");
            options.AddArgument("--disable-quic");                
            options.AddArgument("--proxy-server=http://127.0.0.1:8000");

            using var driver = new ChromeDriver(options);


//Wait requests are to allow web page to load, please note that if the account used does not use ADFS  the element names will need to change
            try
            {
                driver.Navigate().GoToUrl(url);

                await Task.Delay(5000);
                var emailBox = driver.FindElement(By.Name("loginfmt"));
                emailBox.SendKeys(username);
                driver.FindElement(By.Id("idSIButton9")).Click();
                await Task.Delay(5000);

                var passwordBox = driver.FindElement(By.Name("Password"));
                passwordBox.SendKeys(password);
                driver.FindElement(By.Id("submitButton")).Click();
                await Task.Delay(5000);

                try { driver.FindElement(By.Id("idBtn_Back")).Click(); } catch { }

                await Task.Delay(30000);

                if (string.IsNullOrEmpty(bearerToken))
                    throw new Exception("Bearer token not observed via proxy.");

                Console.WriteLine("Bearer Token Captured.");
                return bearerToken;
            }
            finally
            {
                driver.Quit();
                try { proxyServer.BeforeRequest -= OnRequestCapture; } catch { }
                try { proxyServer.Stop(); } catch { }
            }
        }

        private static async Task OnRequestCapture(object sender, SessionEventArgs e)
        {
            try
            {
                var request = e.HttpClient.Request;
                if (request.Url.Contains("lakedetails?fetchLakehouseInfo=true", StringComparison.OrdinalIgnoreCase))
                {
                    var authHeader = request.Headers
                        .FirstOrDefault(h => h.Name.Equals("Authorization", StringComparison.OrdinalIgnoreCase))?.Value;

                    if (!string.IsNullOrEmpty(authHeader) &&
                        authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                    {
                        bearerToken = authHeader.Substring("Bearer ".Length);
                        Console.WriteLine("Bearer Token Captured (Titanium).");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Request Error] {ex.Message}");
            }

            await Task.CompletedTask;
        }
    }
}
