using System;
using System.Collections.Generic;

namespace Yamore.Services.Database;

public partial class User
{
    public int UserId { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string Username { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public string PasswordSalt { get; set; } = null!;
    public bool? Status { get; set; }


    public DateTime? DateCreated { get; set; }             //kasnije cemo ova 2 propertija izbrisati
    public string? Role { get; set; }


    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Yacht> Yachts { get; set; } = new List<Yacht>();
}
