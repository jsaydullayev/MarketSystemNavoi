using FluentAssertions;
using MarketSystem.API.Storage;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Covers the on-disk product-image storage: the save round-trip and — critically
/// — the path-traversal guard in DeleteAsync (a sibling directory that shares the
/// root's name prefix must NOT be reachable).
/// </summary>
public class LocalProductImageStorageTests : IDisposable
{
    private readonly string _tempBase;
    private readonly string _root;
    private readonly LocalProductImageStorage _storage;

    public LocalProductImageStorageTests()
    {
        _tempBase = Path.Combine(Path.GetTempPath(), "ms_imgtest_" + Guid.NewGuid().ToString("N"));
        _root = Path.Combine(_tempBase, "root");

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Storage:ProductImagesPath"] = _root,
            })
            .Build();

        _storage = new LocalProductImageStorage(
            Mock.Of<IWebHostEnvironment>(),
            config,
            NullLogger<LocalProductImageStorage>.Instance);
    }

    [Fact]
    public async Task Save_WritesFile_AndReturnsApiUploadsUrl()
    {
        var productId = Guid.NewGuid();
        var url = await _storage.SaveAsync(12, productId, new byte[] { 1, 2, 3 }, "webp");

        url.Should().StartWith("/api/uploads/products/12/");
        url.Should().EndWith(".webp");

        // The returned URL must map to a file that actually exists on disk.
        var relative = url["/api/uploads/products/".Length..].Replace('/', Path.DirectorySeparatorChar);
        File.Exists(Path.Combine(_root, relative)).Should().BeTrue();
    }

    [Fact]
    public async Task Delete_RemovesOwnFile()
    {
        var productId = Guid.NewGuid();
        var url = await _storage.SaveAsync(12, productId, new byte[] { 1, 2, 3 }, "png");
        var relative = url["/api/uploads/products/".Length..].Replace('/', Path.DirectorySeparatorChar);
        var physical = Path.Combine(_root, relative);
        File.Exists(physical).Should().BeTrue();

        await _storage.DeleteAsync(url);

        File.Exists(physical).Should().BeFalse();
    }

    [Fact]
    public async Task Delete_DoesNotEscapeToSiblingDirectorySharingPrefix()
    {
        // ".../root-evil" shares the "root" name prefix. The old StartsWith guard
        // (no trailing separator) would have let "../root-evil/..." through.
        var evilDir = _tempBase; // _root is {tempBase}/root; sibling lives in {tempBase}
        var siblingName = "root-evil";
        Directory.CreateDirectory(Path.Combine(evilDir, siblingName));
        var secret = Path.Combine(evilDir, siblingName, "secret.png");
        await File.WriteAllBytesAsync(secret, new byte[] { 9, 9, 9 });

        // Crafted URL that normalizes to {tempBase}/root-evil/secret.png.
        var traversalUrl = $"/api/uploads/products/../{siblingName}/secret.png";
        await _storage.DeleteAsync(traversalUrl);

        File.Exists(secret).Should().BeTrue("traversal to a prefix-sharing sibling must be rejected");
    }

    [Fact]
    public async Task Delete_NullOrUnknownPrefix_IsNoOp()
    {
        // Should not throw.
        await _storage.DeleteAsync(null);
        await _storage.DeleteAsync("");
        await _storage.DeleteAsync("/some/other/path.png");
    }

    public void Dispose()
    {
        try
        {
            if (Directory.Exists(_tempBase))
                Directory.Delete(_tempBase, recursive: true);
        }
        catch { /* best-effort temp cleanup */ }
    }
}
