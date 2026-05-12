using MarketSystem.Domain.Common;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Entities;

/// <summary>
/// Public sign-up request. An anonymous visitor submits FullName + Phone; a
/// SuperAdmin later approves or rejects from the admin console. On approval a
/// new <see cref="User"/> (Role=Owner) and a dedicated <see cref="Market"/>
/// are created so that the owner's data stays isolated from every other tenant.
/// </summary>
public class RegistrationRequest : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;

    public RegistrationRequestStatus Status { get; set; } = RegistrationRequestStatus.Pending;
    // CreatedAt inherited from BaseEntity.
    public DateTime? ProcessedAt { get; set; }

    /// <summary>
    /// Optimistic-concurrency token (PostgreSQL system column xmin). Two SuperAdmins
    /// trying to approve the same request simultaneously will collide here and one
    /// of them will get a DbUpdateConcurrencyException → 409 instead of silently
    /// producing duplicate User/Market rows.
    /// </summary>
    public uint Xmin { get; set; }

    /// <summary>The SuperAdmin who approved or rejected this request.</summary>
    public Guid? ProcessedByUserId { get; set; }
    public User? ProcessedByUser { get; set; }

    /// <summary>The owner user created when this request was approved.</summary>
    public Guid? CreatedUserId { get; set; }
    public User? CreatedUser { get; set; }

    /// <summary>The market created when this request was approved.</summary>
    public int? CreatedMarketId { get; set; }
    public Market? CreatedMarket { get; set; }

    /// <summary>Optional rejection reason (shown back to the SuperAdmin only).</summary>
    public string? RejectReason { get; set; }
}
