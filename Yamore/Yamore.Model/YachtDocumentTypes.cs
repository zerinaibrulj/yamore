using System;
using System.Linq;

namespace Yamore.Model
{
    /// <summary>Mandatory yacht compliance document types required before publishing (Active).</summary>
    public static class YachtDocumentTypes
    {
        public const string Registration = "Registration";
        public const string Insurance = "Insurance";
        public const string SafetyCertificate = "SafetyCertificate";

        public static readonly string[] MandatoryForActivation =
        {
            Registration,
            Insurance,
            SafetyCertificate,
        };

        /// <summary>Maps client input to a canonical mandatory type, or null if not recognized.</summary>
        public static string? TryResolveMandatoryType(string? documentType)
        {
            if (string.IsNullOrWhiteSpace(documentType))
                return null;

            var trimmed = documentType.Trim();
            return MandatoryForActivation.FirstOrDefault(m =>
                string.Equals(m, trimmed, StringComparison.OrdinalIgnoreCase));
        }
    }
}
