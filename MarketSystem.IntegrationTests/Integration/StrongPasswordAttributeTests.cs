using MarketSystem.Application.Validation;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Y2 — pins the strong-password contract so a future tweak (raise min
/// length, add symbol requirement, …) is a deliberate one-file change
/// caught by tests instead of a silent regression on every password DTO.
/// </summary>
public class StrongPasswordAttributeTests
{
    private static readonly StrongPasswordAttribute Attr = new();

    private static bool IsValid(string? value) => Attr.IsValid(value);

    [Theory]
    [InlineData("Password123")]       // 11 chars, mixed letter+digit
    [InlineData("ab1cdefg")]           // exactly min length 8
    [InlineData("Parol2026!")]         // symbol allowed but not required
    [InlineData("Парол123ru")]         // Cyrillic letters
    public void IsValid_AcceptsStrongPasswords(string input)
    {
        IsValid(input).Should().BeTrue();
    }

    [Theory]
    [InlineData("short1")]              // length 6 — below min 8
    [InlineData("1234567")]             // 7 chars
    [InlineData("alllettersnodigit")]   // no digit
    [InlineData("12345678")]            // no letter
    [InlineData("")]                    // empty (caller's [Required] catches this; the attribute on its own
                                        // returns true for empty to allow optional fields to skip)
    public void IsValid_ReturnsExpected(string input)
    {
        // The "empty" case intentionally returns true so optional password
        // fields (UpdateUserDto.Password, UpdateProfileDto.NewPassword)
        // can be omitted without tripping the validator. [Required] handles
        // the mandatory case separately.
        if (input == "")
        {
            IsValid(input).Should().BeTrue();
        }
        else
        {
            IsValid(input).Should().BeFalse();
        }
    }

    [Fact]
    public void IsValid_NullValue_ReturnsTrue()
    {
        // Same rationale as the empty-string case — optional fields rely
        // on this for "don't change password" semantics.
        IsValid(null).Should().BeTrue();
    }

    [Fact]
    public void IsValid_NonStringValue_ReturnsFalse()
    {
        Attr.IsValid(42).Should().BeFalse("the attribute only knows how to validate strings");
    }

    [Fact]
    public void IsValid_AtMaxLength_PassesValidation()
    {
        // 100 chars with letter + digit.
        var password = new string('A', 99) + "1";
        IsValid(password).Should().BeTrue();
    }

    [Fact]
    public void IsValid_OverMaxLength_Rejected()
    {
        var password = new string('A', 100) + "1";
        IsValid(password).Should().BeFalse();
    }
}
