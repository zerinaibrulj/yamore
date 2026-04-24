using System;

namespace Yamore.Model
{
    public class BusinessException : Exception
    {
        public BusinessException(string message) : base(message) { }
    }
}
