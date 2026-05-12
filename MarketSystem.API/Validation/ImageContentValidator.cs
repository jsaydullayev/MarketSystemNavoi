namespace MarketSystem.API.Validation;

/// <summary>
/// Validates that an uploaded byte array actually starts with one of the magic-byte
/// signatures of an allowed image format. Catches attacks where an executable or
/// HTML payload is renamed to .jpg/.png.
/// </summary>
public static class ImageContentValidator
{
    public enum ImageKind { Unknown, Jpeg, Png, Gif, WebP }

    /// <summary>
    /// Detects the image format from the first bytes. Returns Unknown if no known
    /// signature matches — callers should reject those payloads.
    /// </summary>
    public static ImageKind Detect(ReadOnlySpan<byte> bytes)
    {
        // JPEG: FF D8 FF (any third byte after)
        if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
            return ImageKind.Jpeg;

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (bytes.Length >= 8
            && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
            && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A)
            return ImageKind.Png;

        // GIF: "GIF87a" or "GIF89a"
        if (bytes.Length >= 6
            && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46
            && bytes[3] == 0x38 && (bytes[4] == 0x37 || bytes[4] == 0x39) && bytes[5] == 0x61)
            return ImageKind.Gif;

        // WebP: "RIFF" .... "WEBP"
        if (bytes.Length >= 12
            && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
            && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50)
            return ImageKind.WebP;

        return ImageKind.Unknown;
    }

    public static string ToMimeType(ImageKind kind) => kind switch
    {
        ImageKind.Jpeg => "image/jpeg",
        ImageKind.Png => "image/png",
        ImageKind.Gif => "image/gif",
        ImageKind.WebP => "image/webp",
        _ => "application/octet-stream"
    };
}
