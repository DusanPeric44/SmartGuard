namespace SmartGuard.Services
{
    public static class PaginationHelper
    {
        public const int DefaultPageSize = 20;
        public const int MaxPageSize = 100;

        public static (int Page, int PageSize) Normalize(int? page, int? pageSize)
        {
            var normalizedPage = page.HasValue && page.Value > 0 ? page.Value : 1;
            var normalizedPageSize = pageSize.HasValue && pageSize.Value > 0
                ? Math.Min(pageSize.Value, MaxPageSize)
                : DefaultPageSize;

            return (normalizedPage, normalizedPageSize);
        }
    }
}
