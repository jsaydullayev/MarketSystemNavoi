using System.ComponentModel.DataAnnotations;

namespace MarketSystem.Application.Validation;

/// <summary>
/// Y2 — single source of truth for the application's password policy.
///
/// Rules:
///   • Length 8–100 characters.
///   • Contains at least one letter (Unicode "Letter" category).
///   • Contains at least one digit (Unicode "Number" category).
///
/// The previous policy was <c>StringLength(100, MinimumLength = 6)</c> with
/// no complexity requirement, and the SuperAdmin bootstrap path independently
/// required 12 characters — three different policies across the codebase.
/// This attribute folds the application-tier rules into one place so a future
/// tightening (e.g. add a symbol requirement, or check against a breach list)
/// is a one-file change. The SuperAdmin bootstrap keeps its stricter 12-char
/// rule, because that account has cross-tenant powers.
///
/// We use Unicode categories rather than ASCII regex so usernames / passwords
/// in Cyrillic / Latin-extended characters still pass — the system already
/// supports Uzbek (uz) and Russian (ru) locales.
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter, AllowMultiple = false)]
public sealed class StrongPasswordAttribute : ValidationAttribute
{
    public const int MinLength = 8;
    public const int MaxLength = 100;

    public StrongPasswordAttribute()
        : base("Parol kamida 8 belgi, 1 harf va 1 raqam o'z ichiga olishi kerak.")
    {
    }

    public override bool IsValid(object? value)
    {
        // Null / empty is "valid" so optional-password fields (e.g. UpdateUserDto.Password
        // and UpdateProfileDto.NewPassword) can be omitted to mean "don't change".
        // The [Required] attribute on mandatory paths still catches missing values.
        if (value is null) return true;
        if (value is not string s) return false;
        if (s.Length == 0) return true;

        if (s.Length < MinLength || s.Length > MaxLength)
            return false;

        bool hasLetter = false, hasDigit = false;
        foreach (var ch in s)
        {
            if (char.IsLetter(ch)) hasLetter = true;
            else if (char.IsDigit(ch)) hasDigit = true;
            if (hasLetter && hasDigit) break;
        }
        return hasLetter && hasDigit;
    }
}
