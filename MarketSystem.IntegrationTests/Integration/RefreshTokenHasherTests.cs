using MarketSystem.Application.Services;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Pins the K1 contract: refresh tokens land in the DB as a deterministic
/// SHA-256 hex hash of the plaintext. If anyone ever swaps the algorithm
/// silently, existing rows in the table would stop matching on lookup —
/// these tests catch that immediately.
/// </summary>
public class RefreshTokenHasherTests
{
    [Fact]
    public void Hash_KnownInput_ProducesExpectedSha256Hex()
    {
        // Vector: SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
        // Asserted upper-case because Convert.ToHexString uses upper.
        RefreshTokenHasher.Hash("abc")
            .Should().Be("BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD");
    }

    [Fact]
    public void Hash_IsDeterministic_SameInputAlwaysMatches()
    {
        // Two independent calls must produce the same digest, otherwise
        // GetByTokenAsync can never find a stored row.
        var token = "any-random-refresh-token-value";
        RefreshTokenHasher.Hash(token).Should().Be(RefreshTokenHasher.Hash(token));
    }

    [Fact]
    public void Hash_DifferentInputs_ProduceDifferentHashes()
    {
        RefreshTokenHasher.Hash("token-a")
            .Should().NotBe(RefreshTokenHasher.Hash("token-b"));
    }

    [Fact]
    public void Hash_ProducesHexLengthFor256BitDigest()
    {
        // SHA-256 → 32 bytes → 64 hex chars. The DB column allows 500, so this
        // also guards against an accidental switch to a longer-output hash
        // that would silently truncate.
        RefreshTokenHasher.Hash("anything").Length.Should().Be(64);
    }

    [Fact]
    public void Hash_NullOrEmpty_Throws()
    {
        // Empty input is a developer error — a real refresh token is 64
        // random bytes. Surfacing it loudly catches a bug where the client
        // posts a missing field instead of silently looking up a row whose
        // Token column is "" (which would be a footgun).
        Action emptyAct = () => RefreshTokenHasher.Hash("");
        Action nullAct = () => RefreshTokenHasher.Hash(null!);
        emptyAct.Should().Throw<ArgumentException>();
        nullAct.Should().Throw<ArgumentException>();
    }
}
