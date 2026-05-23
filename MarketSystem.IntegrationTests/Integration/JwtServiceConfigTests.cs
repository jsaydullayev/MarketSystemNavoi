using MarketSystem.Application.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Guards the S5 fail-fast contract: JwtService must refuse to construct
/// when Jwt:Key is missing, empty, or shorter than 32 characters. Program.cs
/// validates the same constraint at startup, but Scoped services are
/// re-resolved per request — if configuration ever drifts (hot reload,
/// orchestrator pushing a bad value, broken sealed-secret rotation), we
/// want every subsequent JwtService resolution to throw INSTEAD of silently
/// signing tokens with an empty / weak HMAC key.
/// </summary>
public class JwtServiceConfigTests
{
    private static IConfiguration BuildConfig(Dictionary<string, string?> values)
    {
        return new ConfigurationBuilder()
            .AddInMemoryCollection(values!)
            .Build();
    }

    private static readonly string GoodKey =
        new string('x', 48); // 48 chars — comfortably above the 32-char floor.

    [Fact]
    public void Ctor_MissingJwtSection_Throws()
    {
        var config = BuildConfig(new Dictionary<string, string?>());

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*configuration section is missing*");
    }

    [Fact]
    public void Ctor_EmptyKey_Throws()
    {
        var config = BuildConfig(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "",
            ["Jwt:Issuer"] = "MarketSystemAPI",
            ["Jwt:Audience"] = "MarketSystemClient",
        });

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Jwt:Key*");
    }

    [Fact]
    public void Ctor_ShortKey_Throws()
    {
        var config = BuildConfig(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = new string('x', 31), // one char below the floor
            ["Jwt:Issuer"] = "MarketSystemAPI",
            ["Jwt:Audience"] = "MarketSystemClient",
        });

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*32 characters*");
    }

    [Fact]
    public void Ctor_MissingIssuer_Throws()
    {
        var config = BuildConfig(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = GoodKey,
            ["Jwt:Audience"] = "MarketSystemClient",
        });

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Issuer*");
    }

    [Fact]
    public void Ctor_MissingAudience_Throws()
    {
        var config = BuildConfig(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = GoodKey,
            ["Jwt:Issuer"] = "MarketSystemAPI",
        });

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Audience*");
    }

    [Fact]
    public void Ctor_ValidConfig_DoesNotThrow()
    {
        var config = BuildConfig(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = GoodKey,
            ["Jwt:Issuer"] = "MarketSystemAPI",
            ["Jwt:Audience"] = "MarketSystemClient",
        });

        var act = () => new JwtService(config, NullLogger<JwtService>.Instance);

        act.Should().NotThrow();
    }
}
