using System.Net;
using System.Net.Http.Json;
using Xunit;

namespace CustomerService.Tests;

public class CustomerApiTests : IClassFixture<TestApiFactory>
{
    private readonly HttpClient _client;

    public CustomerApiTests(TestApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateCustomer_ReturnsCreated_ForValidPayload()
    {
        var payload = new
        {
            name = "Northwind",
            email = "qa@northwind.test"
        };

        var response = await _client.PostAsJsonAsync("/api/customers", payload);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateCustomer_ReturnsBadRequest_ForMissingEmail()
    {
        var payload = new
        {
            name = "Northwind"
        };

        var response = await _client.PostAsJsonAsync("/api/customers", payload);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
