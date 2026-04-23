namespace Yamore.Model
{
    /// <summary>Enforces bounded pagination for list endpoints.</summary>
    public static class PagingConstraints
    {
        public const int MaxPageSize = 100;
        public const int DefaultPageSize = 20;

        public static int NormalizePage(int? page) => System.Math.Max(0, page ?? 0);

        public static int NormalizePageSize(int? pageSize)
        {
            var v = pageSize ?? DefaultPageSize;
            if (v < 1) return 1;
            if (v > MaxPageSize) return MaxPageSize;
            return v;
        }
    }
}
