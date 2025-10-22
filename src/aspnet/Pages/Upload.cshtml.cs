using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace UserUpload.Pages
{
    public class UploadModel : PageModel
    {
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<UploadModel> _logger;

        public string? Message { get; set; }
        public bool IsSuccess { get; set; }
        public List<string> UploadedFiles { get; set; } = new List<string>();

        public UploadModel(IWebHostEnvironment environment, ILogger<UploadModel> logger)
        {
            _environment = environment;
            _logger = logger;

            var uploadPath = Environment.GetEnvironmentVariable("WEBSITE_MOUNT_userupload-files")!;

            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }

            var files = new DirectoryInfo(uploadPath).GetFiles();

            foreach (var file in files)
            {
                UploadedFiles.Add(file.Name);
            }
        }

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostAsync(List<IFormFile> files)
        {
            if (files == null || files.Count == 0)
            {
                Message = "Please select at least one file to upload.";
                IsSuccess = false;
                return Page();
            }

            // var uploadPath = Path.Combine(_environment.ContentRootPath, "uploads");
            var uploadPath = Environment.GetEnvironmentVariable("WEBSITE_MOUNT_userupload-files")!;

            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }

            try
            {
                foreach (var file in files)
                {
                    if (file.Length > 0)
                    {
                        var fileName = Path.GetFileName(file.FileName);
                        var filePath = Path.Combine(uploadPath, fileName);

                        using (var stream = new FileStream(filePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                        }

                        UploadedFiles.Add(fileName);
                        _logger.LogInformation($"File uploaded: {fileName}");
                    }
                }

                Message = $"Successfully uploaded {UploadedFiles.Count} file(s).";
                IsSuccess = true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading files");
                Message = "An error occurred while uploading files.";
                IsSuccess = false;
            }

            return Page();
        }
    }
}
