namespace Yamore.Model.Requests.YachtDocument
{
    public class YachtDocumentVerifyRequest
    {
        /// <summary>Approved or Rejected (see <see cref="YachtDocumentVerificationStatus"/>).</summary>
        public string VerificationStatus { get; set; } = null!;

        /// <summary>Required when rejecting.</summary>
        public string? RejectionReason { get; set; }
    }
}
