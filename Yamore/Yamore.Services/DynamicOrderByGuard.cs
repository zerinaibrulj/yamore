using System;
using System.Collections.Generic;
using System.Linq;
using Yamore.Model;

namespace Yamore.Services
{
    /// <summary>
    /// Validates <c>OrderBy</c> search parameters before passing them to System.Linq.Dynamic.Core.
    /// </summary>
    public static class DynamicOrderByGuard
    {
        private static readonly string[] UserAllowedFields =
        {
            "UserId",
            "FirstName",
            "LastName",
            "Email",
            "Phone",
            "Username",
            "Status",
        };

        private static readonly string[] YachtAllowedFields =
        {
            "YachtId",
            "Name",
            "YearBuilt",
            "Length",
            "Capacity",
            "Cabins",
            "Bathrooms",
            "PricePerDay",
            "LocationId",
            "CategoryId",
            "StateMachine",
        };

        private static readonly HashSet<string> UserFieldSet =
            new(UserAllowedFields, StringComparer.OrdinalIgnoreCase);

        private static readonly HashSet<string> YachtFieldSet =
            new(YachtAllowedFields, StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// Builds a safe Dynamic LINQ order expression (e.g. <c>PricePerDay desc</c>).
        /// </summary>
        /// <exception cref="UserException">Invalid field, direction, or format (HTTP 400).</exception>
        public static string BuildUserOrderExpression(string orderBy) =>
            BuildOrderExpression(orderBy, UserAllowedFields, UserFieldSet);

        /// <exception cref="UserException">Invalid field, direction, or format (HTTP 400).</exception>
        public static string BuildYachtOrderExpression(string orderBy) =>
            BuildOrderExpression(orderBy, YachtAllowedFields, YachtFieldSet);

        private static string BuildOrderExpression(
            string orderBy,
            IReadOnlyList<string> canonicalFields,
            HashSet<string> allowedSet)
        {
            if (string.IsNullOrWhiteSpace(orderBy))
                throw new UserException("OrderBy cannot be empty.");

            var parts = orderBy.Trim()
                .Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);

            if (parts.Length == 0 || parts.Length > 2)
            {
                throw new UserException(
                    "You can only sort by one field with an optional direction (asc or desc).");
            }

            var fieldToken = parts[0];
            if (!allowedSet.Contains(fieldToken))
            {
                throw new UserException(
                    $"Sorting by '{fieldToken}' is not allowed. Allowed fields: {string.Join(", ", canonicalFields)}.");
            }

            var canonicalField = canonicalFields.First(f =>
                string.Equals(f, fieldToken, StringComparison.OrdinalIgnoreCase));

            if (parts.Length == 1)
                return canonicalField;

            if (!TryNormalizeDirection(parts[1], out var direction))
            {
                throw new UserException("Sort direction must be 'asc' or 'desc'.");
            }

            return $"{canonicalField} {direction}";
        }

        private static bool TryNormalizeDirection(string token, out string direction)
        {
            if (string.Equals(token, "asc", StringComparison.OrdinalIgnoreCase)
                || string.Equals(token, "ascending", StringComparison.OrdinalIgnoreCase))
            {
                direction = "asc";
                return true;
            }

            if (string.Equals(token, "desc", StringComparison.OrdinalIgnoreCase)
                || string.Equals(token, "descending", StringComparison.OrdinalIgnoreCase))
            {
                direction = "desc";
                return true;
            }

            direction = string.Empty;
            return false;
        }
    }
}
