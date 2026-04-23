namespace Yamore.Services.Interfaces
{
    /// <summary>Seeds demo yachts when the database has none. Returns a message and counts for the API response.</summary>
    public interface ISampleYachtSeedService
    {
        Yamore.Services.SampleYachtSeedResult TrySeedSampleYachts();
    }
}
