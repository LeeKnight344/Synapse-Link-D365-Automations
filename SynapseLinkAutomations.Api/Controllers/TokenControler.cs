using Microsoft.AspNetCore.Mvc;
using SynapseLinkAutomations.Core.Services;

namespace SynapseLinkAutomations.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TokenController : ControllerBase
    {
        [HttpPost("fetch")]
        public async Task<IActionResult> FetchToken([FromBody] TokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.EnvironmentGuid) ||
                string.IsNullOrWhiteSpace(request.Username) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest("All parameters are required.");
            }

            try
            {
                var token = await BearerTokenFetcher.FetchBearerToken(
                    request.EnvironmentGuid,
                    request.Username,
                    request.Password
                );

                if (string.IsNullOrWhiteSpace(token))
                    return StatusCode(500, "Bearer token was not captured.");

                return Ok(new { token });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Error fetching bearer token: {ex.Message}");
            }
        }
    }

    public class TokenRequest
    {
        public string? EnvironmentGuid { get; set; }
        public string? Username { get; set; }
        public string? Password { get; set; }
    }
}
