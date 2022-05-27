using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace app
{
  public static class application
  {
    [FunctionName("application")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
        ILogger log)
    {
      log.LogInformation("C# HTTP trigger function processed a request.");

      string azureRegion = Environment.GetEnvironmentVariable("AZURE_REGION");

      string responseMessage = $"Howdy from {azureRegion}!";

      return new OkObjectResult(responseMessage);
    }
  }
}
