using System;

namespace Yamore.Model
{
    /// <summary>Date range when a yacht cannot be booked (reservation or owner block).</summary>
    public class YachtCalendarBlockDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }

        /// <summary><c>reservation</c> or <c>owner_block</c>.</summary>
        public string Kind { get; set; } = null!;
    }
}
