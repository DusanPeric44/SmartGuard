namespace SmartGuard.Model.Options
{
    public class FileStorageOptions
    {
        public string UploadsRootPath { get; set; } = string.Empty;
        public string UrlPrefix { get; set; } = "/uploads";
        public string ImagesSubfolder { get; set; } = "images";
    }
}

