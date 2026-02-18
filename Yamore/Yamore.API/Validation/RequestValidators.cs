using FluentValidation;
using Yamore.Model.Requests.City;
using Yamore.Model.Requests.Country;
using Yamore.Model.Requests.Notification;
using Yamore.Model.Requests.Payment;
using Yamore.Model.Requests.Reservation;
using Yamore.Model.Requests.ReservationService;
using Yamore.Model.Requests.Review;
using Yamore.Model.Requests.Roles;
using Yamore.Model.Requests.Route;
using Yamore.Model.Requests.Service;
using Yamore.Model.Requests.SpecialRequest;
using Yamore.Model.Requests.User;
using Yamore.Model.Requests.UserRole;
using Yamore.Model.Requests.WeatherForecast;
using Yamore.Model.Requests.YachtCategory;
using Yamore.Model.Requests.Yachts;

namespace Yamore.API.Validation;

internal static class ValidationPatterns
{
    public const string Username = "^[a-zA-Z0-9._-]{3,32}$";
    public const string Phone = @"^\+?[0-9\s\-()]{7,20}$";
}

internal static class ValidationMessages
{
    public static string Required(string fieldLabel) =>
        $"{fieldLabel} is required.";

    public static string MaxLength(string fieldLabel, int max) =>
        $"{fieldLabel} must be at most {max} characters long.";

    public static string MinLength(string fieldLabel, int min) =>
        $"{fieldLabel} must be at least {min} characters long.";

    public static string Range(string fieldLabel, string range) =>
        $"{fieldLabel} must be in the range {range}.";
}

public sealed class UserInsertRequestValidator : AbstractValidator<UserInsertRequest>
{
    public UserInsertRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage(ValidationMessages.Required("First name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("First name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("First name", 50));

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage(ValidationMessages.Required("Last name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("Last name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Last name", 50));

        RuleFor(x => x.Username)
            .NotEmpty().WithMessage(ValidationMessages.Required("Username"))
            .Matches(ValidationPatterns.Username)
            .WithMessage("Username must be 3-32 characters and contain only letters, numbers, '.', '_' or '-'.");

        RuleFor(x => x.Email)
            .Cascade(CascadeMode.Stop)
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Email", 100))
            .EmailAddress().WithMessage("Please enter a valid email address (example: name@example.com).")
            .When(x => !string.IsNullOrWhiteSpace(x.Email));

        RuleFor(x => x.Phone)
            .Cascade(CascadeMode.Stop)
            .Matches(ValidationPatterns.Phone)
            .WithMessage("Please enter a valid phone number (7-20 digits; allowed: +, spaces, -, parentheses).")
            .When(x => !string.IsNullOrWhiteSpace(x.Phone));

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage(ValidationMessages.Required("Password"))
            .MinimumLength(8).WithMessage("Password must be at least 8 characters long.")
            .MaximumLength(128).WithMessage("Password must be at most 128 characters long.")
            .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter (a-z).")
            .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter (A-Z).")
            .Matches("[0-9]").WithMessage("Password must contain at least one digit (0-9).")
            .Matches(@"[^a-zA-Z0-9]").WithMessage("Password must contain at least one special character (example: !@#$%).");

        RuleFor(x => x.PasswordConfirmation)
            .NotEmpty().WithMessage(ValidationMessages.Required("Confirm password"))
            .Equal(x => x.Password).WithMessage("Password and confirmation password must match.");
    }
}

public sealed class UserUpdateRequestValidator : AbstractValidator<UserUpdateRequest>
{
    public UserUpdateRequestValidator()
    {
        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage(ValidationMessages.Required("First name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("First name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("First name", 50));

        RuleFor(x => x.LastName)
            .NotEmpty().WithMessage(ValidationMessages.Required("Last name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("Last name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Last name", 50));

        RuleFor(x => x.Phone)
            .Cascade(CascadeMode.Stop)
            .Matches(ValidationPatterns.Phone)
            .WithMessage("Please enter a valid phone number (7-20 digits; allowed: +, spaces, -, parentheses).")
            .When(x => !string.IsNullOrWhiteSpace(x.Phone));

        When(x => !string.IsNullOrWhiteSpace(x.Password), () =>
        {
            RuleFor(x => x.Password!)
                .MinimumLength(8).WithMessage("New password must be at least 8 characters long.")
                .MaximumLength(128).WithMessage("New password must be at most 128 characters long.")
                .Matches("[a-z]").WithMessage("New password must contain at least one lowercase letter (a-z).")
                .Matches("[A-Z]").WithMessage("New password must contain at least one uppercase letter (A-Z).")
                .Matches("[0-9]").WithMessage("New password must contain at least one digit (0-9).")
                .Matches(@"[^a-zA-Z0-9]").WithMessage("New password must contain at least one special character (example: !@#$%).");

            RuleFor(x => x.PasswordConfirmation)
                .NotEmpty().WithMessage("Please confirm the new password.")
                .Equal(x => x.Password).WithMessage("New password and confirmation password must match.");
        });

        When(x => string.IsNullOrEmpty(x.Password) && !string.IsNullOrEmpty(x.PasswordConfirmation), () =>
        {
            RuleFor(x => x.Password)
                .NotEmpty()
                .WithMessage("To change the password, enter a new password, or leave both password fields empty to keep the existing password.");
        });
    }
}

public sealed class RoleInsertRequestValidator : AbstractValidator<RoleInsertRequest>
{
    public RoleInsertRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Role name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("Role name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Role name", 50));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Role description", 255))
            .When(x => x.Description != null);
    }
}

public sealed class RoleUpdateRequestValidator : AbstractValidator<RoleUpdateRequest>
{
    public RoleUpdateRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Role name"))
            .MinimumLength(2).WithMessage(ValidationMessages.MinLength("Role name", 2))
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Role name", 50));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Role description", 255))
            .When(x => x.Description != null);
    }
}

public sealed class UserRoleInsertRequestValidator : AbstractValidator<UserRoleInsertRequest>
{
    public UserRoleInsertRequestValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("Please select a valid user.");

        RuleFor(x => x.RoleId)
            .GreaterThan(0).WithMessage("Please select a valid role.");
    }
}

public sealed class UserRoleUpdateRequestValidator : AbstractValidator<UserRoleUpdateRequest>
{
    public UserRoleUpdateRequestValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("Please select a valid user.");

        RuleFor(x => x.RoleId)
            .GreaterThan(0).WithMessage("Please select a valid role.");
    }
}

public sealed class CountryInsertRequestValidator : AbstractValidator<CountryInsertRequest>
{
    public CountryInsertRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Country name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Country name", 100));
    }
}

public sealed class CountryUpdateRequestValidator : AbstractValidator<CountryUpdateRequest>
{
    public CountryUpdateRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Country name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Country name", 100));
    }
}

public sealed class CityInsertRequestValidator : AbstractValidator<CityInsertRequest>
{
    public CityInsertRequestValidator()
    {
        RuleFor(x => x.CountryId)
            .GreaterThan(0).WithMessage("Please select a valid country.");

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("City name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("City name", 100));
    }
}

public sealed class CityUpdateRequestValidator : AbstractValidator<CityUpdateRequest>
{
    public CityUpdateRequestValidator()
    {
        RuleFor(x => x.CountryId)
            .GreaterThan(0).WithMessage("Please select a valid country.");

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("City name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("City name", 100));
    }
}

public sealed class YachtCategoryInsertRequestValidator : AbstractValidator<YachtCategoryInsertRequest>
{
    public YachtCategoryInsertRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Category name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Category name", 100));
    }
}

public sealed class YachtCategoryUpdateRequestValidator : AbstractValidator<YachtCategoryUpdateRequest>
{
    public YachtCategoryUpdateRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Category name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Category name", 100));
    }
}

public sealed class ServiceInsertRequestValidator : AbstractValidator<ServiceInsertRequest>
{
    public ServiceInsertRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Service name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Service name", 100));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Service description", 255))
            .When(x => x.Description != null);

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0).WithMessage("Price must be 0 or greater.")
            .When(x => x.Price.HasValue);
    }
}

public sealed class ServiceUpdateRequestValidator : AbstractValidator<ServiceUpdateRequest>
{
    public ServiceUpdateRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Service name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Service name", 100));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Service description", 255))
            .When(x => x.Description != null);

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0).WithMessage("Price must be 0 or greater.")
            .When(x => x.Price.HasValue);
    }
}

public sealed class RouteInsertRequestValidator : AbstractValidator<RouteInsertRequest>
{
    public RouteInsertRequestValidator()
    {
        RuleFor(x => x.YachtId)
            .GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.StartCityId)
            .GreaterThan(0).WithMessage("Please select a valid start city.");

        RuleFor(x => x.EndCityId)
            .GreaterThan(0).WithMessage("Please select a valid end city.");

        RuleFor(x => x)
            .Must(x => x.StartCityId != x.EndCityId)
            .WithMessage("Start city and end city must be different.");

        RuleFor(x => x.EstimatedDurationHours)
            .GreaterThan(0).WithMessage("Estimated duration must be greater than 0 hours.")
            .LessThanOrEqualTo(1000).WithMessage("Estimated duration must be 1000 hours or less.")
            .When(x => x.EstimatedDurationHours.HasValue);

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Route description", 255))
            .When(x => x.Description != null);
    }
}

public sealed class RouteUpdateRequestValidator : AbstractValidator<RouteUpdateRequest>
{
    public RouteUpdateRequestValidator()
    {
        RuleFor(x => x.YachtId)
            .GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.StartCityId)
            .GreaterThan(0).WithMessage("Please select a valid start city.");

        RuleFor(x => x.EndCityId)
            .GreaterThan(0).WithMessage("Please select a valid end city.");

        RuleFor(x => x)
            .Must(x => x.StartCityId != x.EndCityId)
            .WithMessage("Start city and end city must be different.");

        RuleFor(x => x.EstimatedDurationHours)
            .GreaterThan(0).WithMessage("Estimated duration must be greater than 0 hours.")
            .LessThanOrEqualTo(1000).WithMessage("Estimated duration must be 1000 hours or less.")
            .When(x => x.EstimatedDurationHours.HasValue);

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Route description", 255))
            .When(x => x.Description != null);
    }
}

public sealed class YachtsInsertRequestValidator : AbstractValidator<YachtsInsertRequest>
{
    public YachtsInsertRequestValidator()
    {
        RuleFor(x => x.OwnerId)
            .GreaterThan(0).WithMessage("Please select a valid owner.")
            .When(x => x.OwnerId.HasValue);

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Yacht name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Yacht name", 100));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Yacht description", 255))
            .When(x => x.Description != null);

        var currentYear = DateTime.UtcNow.Year;
        RuleFor(x => x.YearBuilt)
            .InclusiveBetween(1900, currentYear + 1)
            .WithMessage($"Year built must be between 1900 and {currentYear + 1}.");

        RuleFor(x => x.Length)
            .GreaterThan(0).WithMessage("Length must be greater than 0.")
            .LessThanOrEqualTo(300).WithMessage("Length must be 300 meters or less.");

        RuleFor(x => x.Capacity)
            .InclusiveBetween(1, 500)
            .WithMessage("Capacity must be between 1 and 500.");

        RuleFor(x => x.Cabins)
            .InclusiveBetween(0, 100)
            .WithMessage("Cabins must be between 0 and 100.");

        RuleFor(x => x.Bathrooms)
            .InclusiveBetween(0, 100)
            .WithMessage("Bathrooms must be between 0 and 100.")
            .When(x => x.Bathrooms.HasValue);

        RuleFor(x => x.PricePerDay)
            .GreaterThanOrEqualTo(0).WithMessage("Price per day must be 0 or greater.");

        RuleFor(x => x.LocationId)
            .GreaterThan(0).WithMessage("Please select a valid location.");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0).WithMessage("Please select a valid category.");
    }
}

public sealed class YachtsUpdateRequestValidator : AbstractValidator<YachtsUpdateRequest>
{
    public YachtsUpdateRequestValidator()
    {
        RuleFor(x => x.OwnerId)
            .GreaterThan(0).WithMessage("Please select a valid owner.")
            .When(x => x.OwnerId.HasValue);

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(ValidationMessages.Required("Yacht name"))
            .MaximumLength(100).WithMessage(ValidationMessages.MaxLength("Yacht name", 100));

        RuleFor(x => x.Description)
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Yacht description", 255))
            .When(x => x.Description != null);

        var currentYear = DateTime.UtcNow.Year;
        RuleFor(x => x.YearBuilt)
            .InclusiveBetween(1900, currentYear + 1)
            .WithMessage($"Year built must be between 1900 and {currentYear + 1}.");

        RuleFor(x => x.Length)
            .GreaterThan(0).WithMessage("Length must be greater than 0.")
            .LessThanOrEqualTo(300).WithMessage("Length must be 300 meters or less.");

        RuleFor(x => x.Capacity)
            .InclusiveBetween(1, 500)
            .WithMessage("Capacity must be between 1 and 500.");

        RuleFor(x => x.Cabins)
            .InclusiveBetween(0, 100)
            .WithMessage("Cabins must be between 0 and 100.");

        RuleFor(x => x.Bathrooms)
            .InclusiveBetween(0, 100)
            .WithMessage("Bathrooms must be between 0 and 100.")
            .When(x => x.Bathrooms.HasValue);

        RuleFor(x => x.PricePerDay)
            .GreaterThanOrEqualTo(0).WithMessage("Price per day must be 0 or greater.");

        RuleFor(x => x.LocationId)
            .GreaterThan(0).WithMessage("Please select a valid location.");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0).WithMessage("Please select a valid category.");
    }
}

public sealed class ReservationInsertRequestValidator : AbstractValidator<ReservationInsertRequest>
{
    public ReservationInsertRequestValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.YachtId).GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.StartDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("Start date"));

        RuleFor(x => x.EndDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("End date"))
            .GreaterThan(x => x.StartDate).WithMessage("End date must be after the start date.");

        RuleFor(x => x.TotalPrice)
            .GreaterThanOrEqualTo(0).WithMessage("Total price must be 0 or greater.")
            .When(x => x.TotalPrice.HasValue);

        RuleFor(x => x.Status)
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Status", 20))
            .When(x => x.Status != null);
    }
}

public sealed class ReservationUpdateRequestValidator : AbstractValidator<ReservationUpdateRequest>
{
    public ReservationUpdateRequestValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.YachtId).GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.StartDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("Start date"));

        RuleFor(x => x.EndDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("End date"))
            .GreaterThan(x => x.StartDate).WithMessage("End date must be after the start date.");

        RuleFor(x => x.TotalPrice)
            .GreaterThanOrEqualTo(0).WithMessage("Total price must be 0 or greater.")
            .When(x => x.TotalPrice.HasValue);

        RuleFor(x => x.Status)
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Status", 20))
            .When(x => x.Status != null);
    }
}

public sealed class ReviewInsertRequestValidator : AbstractValidator<ReviewInsertRequest>
{
    public ReviewInsertRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.YachtId).GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.Rating)
            .NotNull().WithMessage("Please enter a rating from 1 to 5.")
            .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.")
            .When(x => x.Rating.HasValue || x.Comment != null);

        RuleFor(x => x.Comment)
            .MaximumLength(500).WithMessage(ValidationMessages.MaxLength("Comment", 500))
            .When(x => x.Comment != null);
    }
}

public sealed class ReviewUpdateRequestValidator : AbstractValidator<ReviewUpdateRequest>
{
    public ReviewUpdateRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.YachtId).GreaterThan(0).WithMessage("Please select a valid yacht.");

        RuleFor(x => x.Rating)
            .NotNull().WithMessage("Please enter a rating from 1 to 5.")
            .InclusiveBetween(1, 5).WithMessage("Rating must be between 1 and 5.")
            .When(x => x.Rating.HasValue || x.Comment != null);

        RuleFor(x => x.Comment)
            .MaximumLength(500).WithMessage(ValidationMessages.MaxLength("Comment", 500))
            .When(x => x.Comment != null);
    }
}

public sealed class PaymentInsertRequestValidator : AbstractValidator<PaymentInsertRequest>
{
    public PaymentInsertRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than 0.");

        RuleFor(x => x.PaymentDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("Payment date"));

        RuleFor(x => x.PaymentMethod)
            .NotEmpty().WithMessage("Payment method is required (example: Card, Cash, BankTransfer).")
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Payment method", 20))
            .When(x => x.PaymentMethod != null || x.Status != null);

        RuleFor(x => x.Status)
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Payment status", 20))
            .When(x => x.Status != null);
    }
}

public sealed class PaymentUpdateRequestValidator : AbstractValidator<PaymentUpdateRequest>
{
    public PaymentUpdateRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than 0.");

        RuleFor(x => x.PaymentDate)
            .NotEmpty().WithMessage(ValidationMessages.Required("Payment date"));

        RuleFor(x => x.PaymentMethod)
            .NotEmpty().WithMessage("Payment method is required (example: Card, Cash, BankTransfer).")
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Payment method", 20))
            .When(x => x.PaymentMethod != null || x.Status != null);

        RuleFor(x => x.Status)
            .MaximumLength(20).WithMessage(ValidationMessages.MaxLength("Payment status", 20))
            .When(x => x.Status != null);
    }
}

public sealed class NotificationInsertRequestValidator : AbstractValidator<NotificationInsertRequest>
{
    public NotificationInsertRequestValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.Message)
            .NotEmpty().WithMessage(ValidationMessages.Required("Message"))
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Message", 255));
    }
}

public sealed class NotificationUpdateRequestValidator : AbstractValidator<NotificationUpdateRequest>
{
    public NotificationUpdateRequestValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).WithMessage("Please select a valid user.");
        RuleFor(x => x.Message)
            .NotEmpty().WithMessage(ValidationMessages.Required("Message"))
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Message", 255));
    }
}

public sealed class SpecialRequestInsertRequestValidator : AbstractValidator<SpecialRequestInsertRequest>
{
    public SpecialRequestInsertRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.Description)
            .NotEmpty().WithMessage(ValidationMessages.Required("Description"))
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Description", 255));
    }
}

public sealed class SpecialRequestUpdateRequestValidator : AbstractValidator<SpecialRequestUpdateRequest>
{
    public SpecialRequestUpdateRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.Description)
            .NotEmpty().WithMessage(ValidationMessages.Required("Description"))
            .MaximumLength(255).WithMessage(ValidationMessages.MaxLength("Description", 255));
    }
}

public sealed class ReservationServiceInsertRequestValidator : AbstractValidator<ReservationServiceInsertRequest>
{
    public ReservationServiceInsertRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.ServiceId).GreaterThan(0).WithMessage("Please select a valid service.");
    }
}

public sealed class ReservationServiceUpdateRequestValidator : AbstractValidator<ReservationServiceUpdateRequest>
{
    public ReservationServiceUpdateRequestValidator()
    {
        RuleFor(x => x.ReservationId).GreaterThan(0).WithMessage("Please select a valid reservation.");
        RuleFor(x => x.ServiceId).GreaterThan(0).WithMessage("Please select a valid service.");
    }
}

public sealed class WeatherForecastInsertRequestValidator : AbstractValidator<WeatherForecastInsertRequest>
{
    public WeatherForecastInsertRequestValidator()
    {
        RuleFor(x => x.RouteId).GreaterThan(0).WithMessage("Please select a valid route.");
        RuleFor(x => x.ForecastDate)
            .NotNull().WithMessage("Forecast date is required (example: 2026-02-18).");

        RuleFor(x => x.Temperature)
            .InclusiveBetween(-50, 60).WithMessage("Temperature must be between -50 and 60 degrees.")
            .When(x => x.Temperature.HasValue);

        RuleFor(x => x.Condition)
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Condition", 50))
            .When(x => x.Condition != null);

        RuleFor(x => x.WindSpeed)
            .InclusiveBetween(0, 200).WithMessage("Wind speed must be between 0 and 200.")
            .When(x => x.WindSpeed.HasValue);

        RuleFor(x => x.ForecastId)
            .Equal(0)
            .WithMessage("ForecastId is generated by the server. Please leave it as 0.");
    }
}

public sealed class WeatherForecastUpdateRequestValidator : AbstractValidator<WeatherForecastUpdateRequest>
{
    public WeatherForecastUpdateRequestValidator()
    {
        RuleFor(x => x.RouteId).GreaterThan(0).WithMessage("Please select a valid route.");
        RuleFor(x => x.ForecastDate)
            .NotNull().WithMessage("Forecast date is required (example: 2026-02-18).");

        RuleFor(x => x.Temperature)
            .InclusiveBetween(-50, 60).WithMessage("Temperature must be between -50 and 60 degrees.")
            .When(x => x.Temperature.HasValue);

        RuleFor(x => x.Condition)
            .MaximumLength(50).WithMessage(ValidationMessages.MaxLength("Condition", 50))
            .When(x => x.Condition != null);

        RuleFor(x => x.WindSpeed)
            .InclusiveBetween(0, 200).WithMessage("Wind speed must be between 0 and 200.")
            .When(x => x.WindSpeed.HasValue);
    }
}

