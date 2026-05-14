using System;

namespace Yamore.Model
{
    /// <summary>
    /// Thrown when an authenticated caller is not permitted to perform an action (HTTP 403).
    /// </summary>
    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message)
            : base(message)
        {
        }
    }
}
