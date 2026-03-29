using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Yamore.Services.Services;

namespace Yamore.Services.Database;

/// <summary>
/// Inserts minimal demo data on a completely empty database (no roles yet) so
/// docker compose up works for reviewers without manual registration.
/// Idempotent: skipped if any role already exists.
/// </summary>
public static class DemoDataSeeder
{
    public const string DemoPassword = "Demo123!";

    public static void SeedIfEmpty(_220245Context db, ILogger logger)
    {
        if (db.Roles.AsNoTracking().Any())
        {
            return;
        }

        logger.LogInformation("Database has no roles; applying demo seed data for first-time run.");

        var roles = new[]
        {
            new Role { Name = "Admin", Description = "System administrator" },
            new Role { Name = "User", Description = "End user / guest" },
            new Role { Name = "EndUser", Description = "Alternate name for end user (registration)" },
            new Role { Name = "YachtOwner", Description = "Yacht owner" },
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
            var salt = UsersService.GenerateSalt();
            return new User
            {
                Username = username,
                Email = email,
                FirstName = first,
                LastName = last,
                Phone = null,
                Status = true,
                PasswordSalt = salt,
                PasswordHash = UsersService.GenerateHash(salt, DemoPassword),
            };
        }

        var adminUser = MakeUser("demo.admin", "admin@yamore.local", "Demo", "Admin");
        var ownerUser = MakeUser("demo.owner", "owner@yamore.local", "Demo", "Owner");
        var endUser = MakeUser("demo.user", "user@yamore.local", "Demo", "User");
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
                StateMachine = "active",
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
                StateMachine = "active",
            }
        );
        db.SaveChanges();

        logger.LogInformation(
            "Demo seed finished. Test logins (username / password): demo.admin / {Pwd} (Admin), demo.owner / {Pwd} (YachtOwner), demo.user / {Pwd} (User).",
            DemoPassword,
            DemoPassword,
            DemoPassword);
    }
}
