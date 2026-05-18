using System;

namespace SmartGuard.Model.SearchObjects
{
    public class ReportSearchObject : BaseSearchObject
    {
        public DateTime? Start { get; set; }
        public DateTime? End { get; set; }
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
    }
}

