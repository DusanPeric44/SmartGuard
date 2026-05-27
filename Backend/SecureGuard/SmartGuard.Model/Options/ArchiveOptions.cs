namespace SmartGuard.Model.Options
{
    public class ArchiveOptions
    {
        public string BaseUrl { get; set; } = string.Empty;
        public string UploadPath { get; set; } = "Upload";
        public int RecordingFps { get; set; } = 3;
    }
}
