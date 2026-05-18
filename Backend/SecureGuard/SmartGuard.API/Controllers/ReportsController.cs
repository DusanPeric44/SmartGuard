using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;

namespace SmartGuard.API.Controllers
{
    public class ReportsController : BaseCRUDController<Report, ReportSearchObject, ReportInsertRequest, ReportUpdateRequest>
    {
        private readonly IReportsService _reportsService;

        public ReportsController(IReportsService service) : base(service)
        {
            _reportsService = service;
        }

        [HttpPost("generate")]
        public async Task<Report> GenerateSecurityActivity([FromBody] SecurityActivityReportGenerateRequest request)
        {
            var email = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return await _reportsService.GenerateSecurityActivityAsync(request.Start, request.End, email);
        }

        [HttpGet("{id}/download")]
        public async Task<IActionResult> Download(int id)
        {
            var (stream, contentType, fileName) = await _reportsService.OpenReportFileAsync(id);
            return File(stream, contentType, fileName);
        }
    }
}
