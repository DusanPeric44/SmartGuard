using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
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

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override Task<Report> Insert([FromBody] ReportInsertRequest insert)
        {
            return base.Insert(insert);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<Report> Update(int id, [FromBody] ReportUpdateRequest update)
        {
            return base.Update(id, update);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public override Task<bool> Delete(int id)
        {
            return base.Delete(id);
        }

        [HttpPost("generate")]
        public async Task<Report> GenerateSecurityActivity([FromBody] SecurityActivityReportGenerateRequest request)
        {
            // The "UserId" claim carries the Identity id; ClaimTypes.NameIdentifier carries the email
            // (see AuthService.GenerateJwtToken). Reports are owned by user id, which is what
            // OpenReportFileAsync and the list filter compare against.
            var userId = User.FindFirstValue("UserId");
            return await _reportsService.GenerateSecurityActivityAsync(request.Start, request.End, userId);
        }

        [HttpGet("{id}/download")]
        public async Task<IActionResult> Download(int id)
        {
            var (stream, contentType, fileName) = await _reportsService.OpenReportFileAsync(id);
            return File(stream, contentType, fileName);
        }
    }
}
