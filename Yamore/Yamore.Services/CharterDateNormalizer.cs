using System;

namespace Yamore.Services
{
    /// <summary>
    /// Normalizes charter start/end instants to noon UTC on the calendar day so
    /// client time zones and <see cref="DateTime.ToUniversalTime"/> shifts do not change the day.
    /// </summary>
    public static class CharterDateNormalizer
    {
        public static DateTime ToCharterInstant(DateTime value)
        {
            var utc = value.Kind switch
            {
                DateTimeKind.Utc => value,
                DateTimeKind.Local => value.ToUniversalTime(),
                _ => DateTime.SpecifyKind(value, DateTimeKind.Utc),
            };

            return new DateTime(utc.Year, utc.Month, utc.Day, 12, 0, 0, DateTimeKind.Utc);
        }
    }
}
