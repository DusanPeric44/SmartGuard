using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SmartGuard.Model.DTOs.ReportDocuments;

namespace SmartGuard.Services.Reports.Pdf
{
    public static class MonthlyAlarmReportPdf
    {
        public static byte[] Render(MonthlyAlarmReportDocument document)
        {
            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(25);
                    page.Size(PageSizes.A4);
                    page.DefaultTextStyle(x => x.FontSize(10));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("Monthly Alarm Report").FontSize(18).SemiBold();
                        col.Item().Text($"Period (UTC): {document.PeriodStartUtc:yyyy-MM-dd} - {document.PeriodEndUtc:yyyy-MM-dd}").FontSize(10);
                    });

                    page.Content().Column(col =>
                    {
                        col.Spacing(15);

                        col.Item().Text("Alarms").FontSize(14).SemiBold();
                        col.Item().Element(e => BuildAlertsTable(e, document));

                        col.Item().Text("Face Detections").FontSize(14).SemiBold();
                        col.Item().Element(e => BuildFaceDetectionsTable(e, document));
                    });

                    page.Footer().AlignCenter().Text(x =>
                    {
                        x.Span("Page ");
                        x.CurrentPageNumber();
                        x.Span(" / ");
                        x.TotalPages();
                    });
                });
            }).GeneratePdf();
        }

        private static void BuildAlertsTable(IContainer container, MonthlyAlarmReportDocument document)
        {
            if (document.Alerts.Count == 0)
            {
                container.Text("No alarms in this period.");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.ConstantColumn(40);
                    columns.RelativeColumn(1);
                    columns.RelativeColumn(1);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                });

                table.Header(header =>
                {
                    header.Cell().Element(CellStyle).Text("ID");
                    header.Cell().Element(CellStyle).Text("Status");
                    header.Cell().Element(CellStyle).Text("Type");
                    header.Cell().Element(CellStyle).Text("By");
                    header.Cell().Element(CellStyle).Text("Alarm Time (UTC)");
                    header.Cell().Element(CellStyle).Text("Device / Person");
                });

                foreach (var a in document.Alerts)
                {
                    table.Cell().Element(CellStyle).Text(a.Id.ToString());
                    table.Cell().Element(CellStyle).Text(a.Status ?? string.Empty);
                    table.Cell().Element(CellStyle).Text(a.Type ?? string.Empty);
                    table.Cell().Element(CellStyle).Text(a.ConfirmedOrDismissedBy ?? string.Empty);
                    table.Cell().Element(CellStyle).Text(a.CreatedAtUtc.ToString("yyyy-MM-dd HH:mm:ss"));

                    var person = string.IsNullOrWhiteSpace(a.PersonFirstName) && string.IsNullOrWhiteSpace(a.PersonLastName)
                        ? string.Empty
                        : $" ({a.PersonFirstName} {a.PersonLastName})";
                    table.Cell().Element(CellStyle).Text($"{a.DeviceName}{person}".Trim());
                }
            });
        }

        private static void BuildFaceDetectionsTable(IContainer container, MonthlyAlarmReportDocument document)
        {
            if (document.FaceDetections.Count == 0)
            {
                container.Text("No face detections in this period.");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.ConstantColumn(40);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(1);
                    columns.RelativeColumn(2);
                });

                table.Header(header =>
                {
                    header.Cell().Element(CellStyle).Text("ID");
                    header.Cell().Element(CellStyle).Text("Time (UTC)");
                    header.Cell().Element(CellStyle).Text("Device");
                    header.Cell().Element(CellStyle).Text("FaceId");
                    header.Cell().Element(CellStyle).Text("Person");
                });

                foreach (var d in document.FaceDetections)
                {
                    table.Cell().Element(CellStyle).Text(d.Id.ToString());
                    table.Cell().Element(CellStyle).Text(d.TimestampUtc.ToString("yyyy-MM-dd HH:mm:ss"));
                    table.Cell().Element(CellStyle).Text(d.DeviceName ?? string.Empty);
                    table.Cell().Element(CellStyle).Text(d.FaceId?.ToString() ?? string.Empty);
                    table.Cell().Element(CellStyle).Text($"{d.PersonFirstName} {d.PersonLastName}".Trim());
                }
            });
        }

        private static IContainer CellStyle(IContainer container)
        {
            return container
                .Border(1)
                .BorderColor(Colors.Grey.Lighten2)
                .PaddingVertical(4)
                .PaddingHorizontal(6);
        }
    }
}

