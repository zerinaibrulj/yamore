using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Yamore.Services.Database;

public partial class _220245Context : DbContext
{
    public _220245Context()
    {
    }

    public _220245Context(DbContextOptions<_220245Context> options)
        : base(options)
    {
    }

    public virtual DbSet<City> Cities { get; set; }

    public virtual DbSet<Country> Countries { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Payment> Payments { get; set; }

    public virtual DbSet<Reservation> Reservations { get; set; }

    public virtual DbSet<ReservationService> ReservationServices { get; set; }

    public virtual DbSet<Review> Reviews { get; set; }

    public virtual DbSet<Route> Routes { get; set; }

    public virtual DbSet<Service> Services { get; set; }

    public virtual DbSet<SpecialRequest> SpecialRequests { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<WeatherForecast> WeatherForecasts { get; set; }

    public virtual DbSet<Yacht> Yachts { get; set; }

    public virtual DbSet<YachtCategory> YachtCategories { get; set; }
    public virtual DbSet<Role> Roles { get; set; }   
    public virtual DbSet<UserRole> UserRoles { get; set; }   

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Data Source=localhost; Initial Catalog=220245; user=sa; Password=QWEasd123!; TrustServerCertificate=True");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<City>(entity =>
        {
            entity.HasKey(e => e.CityId).HasName("PK__Cities__F2D21B76AE4B32B9");

            entity.Property(e => e.Name).HasMaxLength(100);

            entity.HasOne(d => d.Country).WithMany(p => p.Cities)
                .HasForeignKey(d => d.CountryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Cities__CountryI__398D8EEE");
        });

        modelBuilder.Entity<Country>(entity =>
        {
            entity.HasKey(e => e.CountryId).HasName("PK__Countrie__10D1609FFB858505");

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.NotificationId).HasName("PK__Notifica__20CF2E12A532B107");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.IsRead).HasDefaultValue(false);
            entity.Property(e => e.Message).HasMaxLength(255);

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Notificat__UserI__6754599E");
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.HasKey(e => e.PaymentId).HasName("PK__Payments__9B556A386A72F213");

            entity.Property(e => e.Amount).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.PaymentDate).HasColumnType("datetime");
            entity.Property(e => e.PaymentMethod).HasMaxLength(20);
            entity.Property(e => e.Status).HasMaxLength(20);

            entity.HasOne(d => d.Reservation).WithMany(p => p.Payments)
                .HasForeignKey(d => d.ReservationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Payments__Reserv__4E88ABD4");
        });

        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.HasKey(e => e.ReservationId).HasName("PK__Reservat__B7EE5F244827094F");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Status).HasMaxLength(20);
            entity.Property(e => e.TotalPrice).HasColumnType("decimal(10, 2)");

            entity.HasOne(d => d.User).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reservati__UserI__48CFD27E");

            entity.HasOne(d => d.Yacht).WithMany(p => p.Reservations)
                .HasForeignKey(d => d.YachtId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reservati__Yacht__49C3F6B7");
        });

        modelBuilder.Entity<ReservationService>(entity =>
        {
            entity.HasKey(e => e.ReservationServicesId);

            entity.Property(e => e.ReservationId).HasColumnName("ReservationID");
            entity.Property(e => e.ServiceId).HasColumnName("ServiceID");

            entity.HasOne(d => d.Reservation).WithMany(p => p.ReservationServices)
                .HasForeignKey(d => d.ReservationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ReservationServices_Reservations");

            entity.HasOne(d => d.Service).WithMany(p => p.ReservationServices)
                .HasForeignKey(d => d.ServiceId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_ReservationServices_Services");
        });

        modelBuilder.Entity<Review>(entity =>
        {
            entity.HasKey(e => e.ReviewId).HasName("PK__Reviews__74BC79CE66E44F78");

            entity.Property(e => e.Comment).HasMaxLength(500);
            entity.Property(e => e.DatePosted)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.Reservation).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.ReservationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reviews__Reserva__59063A47");

            entity.HasOne(d => d.User).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reviews__UserId__59FA5E80");

            entity.HasOne(d => d.Yacht).WithMany(p => p.Reviews)
                .HasForeignKey(d => d.YachtId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Reviews__YachtId__5AEE82B9");
        });

        modelBuilder.Entity<Route>(entity =>
        {
            entity.HasKey(e => e.RouteId).HasName("PK__Routes__80979B4D3BEC4B3F");

            entity.Property(e => e.Description).HasMaxLength(255);

            entity.HasOne(d => d.EndCity).WithMany(p => p.RouteEndCities)
                .HasForeignKey(d => d.EndCityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Routes__EndCityI__619B8048");

            entity.HasOne(d => d.StartCity).WithMany(p => p.RouteStartCities)
                .HasForeignKey(d => d.StartCityId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Routes__StartCit__60A75C0F");

            entity.HasOne(d => d.Yacht).WithMany(p => p.Routes)
                .HasForeignKey(d => d.YachtId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Routes__YachtId__5FB337D6");
        });

        modelBuilder.Entity<Service>(entity =>
        {
            entity.HasKey(e => e.ServiceId).HasName("PK__Services__C51BB00AA4083F57");

            entity.Property(e => e.Description).HasMaxLength(255);
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(e => e.Price).HasColumnType("decimal(10, 2)");
        });

        modelBuilder.Entity<SpecialRequest>(entity =>
        {
            entity.HasKey(e => e.RequestId).HasName("PK__SpecialR__33A8517A69D944E8");

            entity.Property(e => e.Description).HasMaxLength(255);

            entity.HasOne(d => d.Reservation).WithMany(p => p.SpecialRequests)
                .HasForeignKey(d => d.ReservationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__SpecialRe__Reser__6C190EBB");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId).HasName("PK__Users__1788CC4C667A3DCC");

            entity.HasIndex(e => e.Email, "UQ__Users__A9D10534AFDA8DC1").IsUnique();

           
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.FirstName).HasMaxLength(50);
            entity.Property(e => e.LastName).HasMaxLength(50);
            entity.Property(e => e.PasswordHash).HasMaxLength(255);
            entity.Property(e => e.Phone).HasMaxLength(30);
            
        });

        modelBuilder.Entity<WeatherForecast>(entity =>
        {
            entity.HasKey(e => e.ForecastId).HasName("PK__WeatherF__7F2744781B839532");

            entity.Property(e => e.Condition).HasMaxLength(50);
            entity.Property(e => e.Temperature).HasColumnType("decimal(4, 1)");
            entity.Property(e => e.WindSpeed).HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.Route).WithMany(p => p.WeatherForecasts)
                .HasForeignKey(d => d.RouteId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__WeatherFo__Route__6477ECF3");
        });

        modelBuilder.Entity<Yacht>(entity =>
        {
            entity.HasKey(e => e.YachtId).HasName("PK__Yachts__0EE60D53D919624E");

            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.Length).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.Name).HasMaxLength(100);
            entity.Property(entity => entity.StateMachine).HasMaxLength(100);
            entity.Property(e => e.PricePerDay).HasColumnType("decimal(10, 2)");

            entity.HasOne(d => d.Category).WithMany(p => p.Yachts)
                .HasForeignKey(d => d.CategoryId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Yachts__Category__44FF419A");

            entity.HasOne(d => d.Location).WithMany(p => p.Yachts)
                .HasForeignKey(d => d.LocationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Yachts__Location__440B1D61");

            entity.HasOne(d => d.Owner).WithMany(p => p.Yachts)
                .HasForeignKey(d => d.OwnerId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__Yachts__OwnerId__4316F928");
        });

        modelBuilder.Entity<YachtCategory>(entity =>
        {
            entity.HasKey(e => e.CategoryId).HasName("PK__YachtCat__19093A0B21D26F14");

            entity.Property(e => e.Name).HasMaxLength(100);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
