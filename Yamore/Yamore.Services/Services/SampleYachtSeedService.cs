using System;
using System.Collections.Generic;
using System.Linq;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;

namespace Yamore.Services.Services;

public class SampleYachtSeedService : ISampleYachtSeedService
{
    private readonly _220245Context _context;

    public SampleYachtSeedService(_220245Context context)
    {
        _context = context;
    }

    public SampleYachtSeedResult TrySeedSampleYachts()
    {
        if (_context.Yachts.Any())
        {
            return new SampleYachtSeedResult
            {
                Success = true,
                StatusCode = 200,
                Message = "Yachts already exist. No seed applied.",
                Count = _context.Yachts.Count(),
            };
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
            return new SampleYachtSeedResult
            {
                Success = false,
                StatusCode = 400,
                Message = "No user with the Owner (or YachtOwner) role found. Assign a user the Owner role in the UserRole table, then run seed again.",
            };
        }

        var owner = _context.Users.Find(ownerUserId);
        if (owner == null)
        {
            return new SampleYachtSeedResult
            {
                Success = false,
                StatusCode = 400,
                Message = "User with Owner role not found.",
            };
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
        var existingCities = _context.Cities
            .Where(c => c.CountryId == countryId && cityNames.Contains(c.Name))
            .ToList();
        foreach (var name in cityNames)
        {
            var existing = existingCities.FirstOrDefault(x => x.Name == name);
            if (existing != null)
            {
                cityIds.Add(existing.CityId);
            }
            else
            {
                var city = new City { Name = name, CountryId = countryId };
                _context.Cities.Add(city);
                _context.SaveChanges();
                existingCities.Add(city);
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

        return new SampleYachtSeedResult
        {
            Success = true,
            StatusCode = 200,
            Message = "Sample yachts seeded successfully.",
            Added = yachts.Length,
        };
    }
}
