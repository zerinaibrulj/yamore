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
    }
}
