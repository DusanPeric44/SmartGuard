using System.Collections.Generic;

namespace SmartGuard.Model
{
    public class PagedResult<T>
    {
        public int Count { get; set; }
        public IEnumerable<T> Result { get; set; }
    }
}