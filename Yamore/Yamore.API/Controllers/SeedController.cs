using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Yamore.Services.Database;

namespace Yamore.API.Controllers
{
    /// <summary>
    /// One-time seed endpoint to add sample yacht data for testing the admin UI.
    /// Call once from Swagger when the database has no yachts.
    /// </summary>
    [ApiController]
    [Route("[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly _220245Context _context;

        public SeedController(_220245Context context)
        {
            _context = context;
        }

        [HttpPost("sample-yachts")]
        [AllowAnonymous]
        public ActionResult<object> SeedSampleYachts()
        {
            if (_context.Yachts.Any())
            {
                return Ok(new { message = "Yachts already exist. No seed applied.", count = _context.Yachts.Count() });
            }

            var ownerRoleIds = _context.Roles
                .Where(r => r.Name == "Owner" || r.Name == "YachtOwner")
                .Select(r => r.RoleId)
                .ToList();
            var ownerUserId = _context.UserRoles
                .Where(ur => ownerRoleIds.Contains(ur.RoleId))
                .Select(ur => ur.UserId)
                .FirstOrDefault();
            if (ownerUserId == 0)
            {
                return BadRequest(new { message = "No user with the Owner (or YachtOwner) role found. Assign a user the Owner role in the UserRole table, then run seed again." });
            }
            var owner = _context.Users.Find(ownerUserId);
            if (owner == null)
            {
                return BadRequest(new { message = "User with Owner role not found." });
            }

            int countryId;
            if (!_context.Countries.Any())
            {
                var c = new Country { Name = "Croatia" };
                _context.Countries.Add(c);
                _context.SaveChanges();
                countryId = c.CountryId;
            }
            else
            {
                countryId = _context.Countries.First().CountryId;
            }

            var cityNames = new[] { "Split", "Dubrovnik", "Rijeka", "Opatija" };
            var cityIds = new List<int>();
            foreach (var name in cityNames)
            {
                var existing = _context.Cities.FirstOrDefault(x => x.Name == name);
                if (existing != null)
                {
                    cityIds.Add(existing.CityId);
                }
                else
                {
                    var city = new City { Name = name, CountryId = countryId };
                    _context.Cities.Add(city);
                    _context.SaveChanges();
                    cityIds.Add(city.CityId);
                }
            }

            int categoryId;
            if (!_context.YachtCategories.Any())
            {
                var cat = new YachtCategory { Name = "Sailboat" };
                _context.YachtCategories.Add(cat);
                _context.SaveChanges();
                categoryId = cat.CategoryId;
            }
            else
            {
                categoryId = _context.YachtCategories.First().CategoryId;
            }

            var yachts = new[]
            {
                new Yacht { OwnerId = owner.UserId, Name = "Bavaria Cruiser 46", Description = "Comfortable family cruiser.", YearBuilt = 2018, Length = 13.60m, Capacity = 5, Cabins = 3, PricePerDay = 2550, LocationId = cityIds[0], CategoryId = categoryId, StateMachine = "active", IsActive = true },
                new Yacht { OwnerId = owner.UserId, Name = "Cheetah Moon", Description = "Luxury motor yacht.", YearBuilt = 2012, Length = 38.36m, Capacity = 15, Cabins = 6, PricePerDay = 25470, LocationId = cityIds[3], CategoryId = categoryId, StateMachine = "active", IsActive = true },
                new Yacht { OwnerId = owner.UserId, Name = "Sunseeker SuperHawk", Description = "Sporty motor yacht.", YearBuilt = 2010, Length = 14.80m, Capacity = 6, Cabins = 2, PricePerDay = 7300, LocationId = cityIds[2], CategoryId = categoryId, StateMachine = "active", IsActive = true },
                new Yacht { OwnerId = owner.UserId, Name = "Hanse 588", Description = "Modern sailing yacht.", YearBuilt = 2024, Length = 17.02m, Capacity = 8, Cabins = 4, PricePerDay = 12000, LocationId = cityIds[1], CategoryId = categoryId, StateMachine = "active", IsActive = true },
            };

            _context.Yachts.AddRange(yachts);
            _context.SaveChanges();

            return Ok(new { message = "Sample yachts seeded successfully.", added = yachts.Length });
        }
    }
}
