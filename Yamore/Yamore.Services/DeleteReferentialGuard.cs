using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Yamore.Model;

namespace Yamore.Services;

/// <summary>
/// Maps EF <see cref="DbUpdateException"/> from SQL Server referential integrity (FK) failures
/// to <see cref="BusinessException"/> so <c>ExceptionFilter</c> returns HTTP 400 + <c>errors.userError</c>
/// instead of HTTP 500 with raw SQL text.
/// </summary>
internal static class DeleteReferentialGuard
{
    /// <summary>
    /// If <paramref name="ex"/> is a FK / reference constraint violation, throws <see cref="BusinessException"/>
    /// with <paramref name="userFacingMessage"/>; otherwise returns normally (caller should rethrow <paramref name="ex"/>).
    /// </summary>
    public static void ThrowBusinessIfReferentialIntegrity(DbUpdateException ex, string userFacingMessage)
    {
        if (IsReferentialIntegrityViolation(ex))
            throw new BusinessException(userFacingMessage);
    }

    public static bool IsReferentialIntegrityViolation(DbUpdateException ex)
    {
        for (Exception? inner = ex.InnerException; inner != null; inner = inner.InnerException)
        {
            if (inner is SqlException sql && sql.Number == 547)
                return true;

            if (inner.Message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase))
                return true;
            if (inner.Message.Contains("conflicted with the REFERENCE", StringComparison.OrdinalIgnoreCase))
                return true;
            if (inner.Message.Contains("FOREIGN KEY constraint", StringComparison.OrdinalIgnoreCase))
                return true;
        }

        return false;
    }
}
