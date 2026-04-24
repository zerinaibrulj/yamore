namespace Yamore.Model
{
    /// <summary>
    /// Canonical role name strings (must match seed data in <c>Roles</c> and JWT role claims).
    /// </summary>
    public static class AppRoles
    {
        public const string Admin = "Admin";
        public const string YachtOwner = "YachtOwner";
        public const string User = "User";
        public const string EndUser = "EndUser";
        public const string Owner = "Owner";

        public const string AdminYachtOwner = "Admin,YachtOwner";
    }
}
