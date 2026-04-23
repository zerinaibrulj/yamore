namespace Yamore.Services
{
    public sealed class SampleYachtSeedResult
    {
        public bool Success { get; set; }
        public int StatusCode { get; set; }
        public string Message { get; set; } = "";
        public int? Count { get; set; }
        public int? Added { get; set; }
    }
}
