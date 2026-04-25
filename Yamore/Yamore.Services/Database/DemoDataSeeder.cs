using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Yamore.Model;
using Yamore.Services.Services;

namespace Yamore.Services.Database;

/// <summary>
/// Inserts minimal demo data on a completely empty database (no roles yet) so
/// docker compose up works for reviewers without manual registration.
/// Idempotent: skipped if any role already exists.
/// Optional <paramref name="notificationEmail"/>: when set (e.g. from env DEMO_NOTIFICATION_EMAIL in Docker),
/// demo users get Gmail "+" aliases derived from this address (distinct emails, but all deliver to the same inbox).
/// This avoids @yamore.local bounces and also respects the unique Users.Email constraint.
/// </summary>
/// <remarks>
/// <see cref="DemoPassword"/> is fixed <b>demo seed data</b> for the seeded accounts only (demo.admin / demo.owner / demo.user).
/// It is not infrastructure configuration (unlike SMTP, DB connection strings, or API keys) and must not be used for real users in production.
/// </remarks>
public static class DemoDataSeeder
{
    /// <summary>Password assigned only to seeded demo users — sample data, not app configuration.</summary>
    public const string DemoPassword = "Demo123!";

    public static void SeedIfEmpty(_220245Context db, ILogger logger, string? notificationEmail = null)
    {
        if (db.Roles.AsNoTracking().Any())
        {
            return;
        }

        logger.LogInformation("Database has no roles; applying demo seed data for first-time run.");

        var baseEmail = string.IsNullOrWhiteSpace(notificationEmail)
            ? null
            : notificationEmail.Trim();
        if (baseEmail != null)
        {
            logger.LogInformation(
                "Demo seed will derive demo.admin/demo.owner/demo.user emails from notification base: {Email}",
                baseEmail);
        }

        using var transaction = db.Database.BeginTransaction();
        try
        {
        var roles = new[]
        {
            new Role { Name = AppRoles.Admin, Description = "System administrator" },
            new Role { Name = AppRoles.User, Description = "End user / guest" },
            new Role { Name = AppRoles.EndUser, Description = "Alternate name for end user (registration)" },
            new Role { Name = AppRoles.YachtOwner, Description = "Yacht owner" },
        };
        db.Roles.AddRange(roles);
        db.SaveChanges();

        var adminRole = roles[0];
        var userRole = roles[1];
        var yachtOwnerRole = roles[3];

        var country = new Country { Name = "Croatia" };
        db.Countries.Add(country);
        db.SaveChanges();

        var split = new City { Name = "Split", CountryId = country.CountryId };
        var dubrovnik = new City { Name = "Dubrovnik", CountryId = country.CountryId };
        db.Cities.AddRange(split, dubrovnik);
        db.SaveChanges();

        var category = new YachtCategory { Name = "Motor yacht" };
        db.YachtCategories.Add(category);
        db.SaveChanges();

        var serviceCategory = new ServiceCategory
        {
            Name = "General",
            Description = "Default service category",
        };
        db.ServiceCategories.Add(serviceCategory);
        db.SaveChanges();

        static User MakeUser(string username, string email, string first, string last)
        {
            return new User
            {
                Username = username,
                Email = email,
                FirstName = first,
                LastName = last,
                Phone = null,
                Status = true,
                PasswordSalt = string.Empty,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(DemoPassword, workFactor: 11),
            };
        }

        static string CreateAlias(string? baseAddr, string tag, string fallback)
        {
            if (string.IsNullOrWhiteSpace(baseAddr))
                return fallback;

            var atIndex = baseAddr.IndexOf('@');
            if (atIndex <= 0 || atIndex >= baseAddr.Length - 1)
                return fallback;

            var local = baseAddr[..atIndex];
            var domain = baseAddr[(atIndex + 1)..];
            return $"{local}+{tag}@{domain}";
        }

        var adminAddr = CreateAlias(baseEmail, "admin", "admin@yamore.local");
        var ownerAddr = CreateAlias(baseEmail, "owner", "owner@yamore.local");
        var userAddr = CreateAlias(baseEmail, "user", "user@yamore.local");

        var adminUser = MakeUser("demo.admin", adminAddr, "Demo", "Admin");
        var ownerUser = MakeUser("demo.owner", ownerAddr, "Demo", "Owner");
        var endUser = MakeUser("demo.user", userAddr, "Demo", "User");
        db.Users.AddRange(adminUser, ownerUser, endUser);
        db.SaveChanges();

        var now = DateTime.UtcNow;
        db.UserRoles.AddRange(
            new UserRole { UserId = adminUser.UserId, RoleId = adminRole.RoleId, DateModification = now },
            new UserRole { UserId = ownerUser.UserId, RoleId = yachtOwnerRole.RoleId, DateModification = now },
            new UserRole { UserId = endUser.UserId, RoleId = userRole.RoleId, DateModification = now }
        );
        db.SaveChanges();

        db.Yachts.AddRange(
            new Yacht
            {
                OwnerId = ownerUser.UserId,
                Name = "Demo Cruiser 46",
                Description = "Sample yacht for Docker / professor review.",
                YearBuilt = 2019,
                Length = 14.2m,
                Capacity = 8,
                Cabins = 4,
                Bathrooms = 2,
                PricePerDay = 450m,
                LocationId = split.CityId,
                CategoryId = category.CategoryId,
                IsActive = true,
                StateMachine = YachtStateNames.Active,
            },
            new Yacht
            {
                OwnerId = ownerUser.UserId,
                Name = "Adriatic Explorer",
                Description = "Second sample listing.",
                YearBuilt = 2015,
                Length = 18m,
                Capacity = 10,
                Cabins = 4,
                Bathrooms = 3,
                PricePerDay = 890m,
                LocationId = dubrovnik.CityId,
                CategoryId = category.CategoryId,
                IsActive = true,
                StateMachine = YachtStateNames.Active,
            }
        );
        db.SaveChanges();

        transaction.Commit();

        logger.LogInformation(
            "Demo seed finished. Test logins (username / password): demo.admin / {Pwd} (Admin), demo.owner / {Pwd} (YachtOwner), demo.user / {Pwd} (User).",
            DemoPassword,
            DemoPassword,
            DemoPassword);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}
