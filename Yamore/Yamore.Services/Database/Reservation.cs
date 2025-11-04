using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class Reservation
{
    public int ReservationId { get; set; }

    public int UserId { get; set; }

    public int YachtId { get; set; }

    public DateTime StartDate { get; set; }       //DateOnly - bilo je prvobitno ali smo ga promijenili zbog mapiranja

    public DateTime EndDate { get; set; }         //DateOnly

    public decimal? TotalPrice { get; set; }

    public string? Status { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<ReservationService> ReservationServices { get; set; } = new List<ReservationService>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<SpecialRequest> SpecialRequests { get; set; } = new List<SpecialRequest>();

    public virtual User User { get; set; } = null!;

    public virtual Yacht Yacht { get; set; } = null!;
}
