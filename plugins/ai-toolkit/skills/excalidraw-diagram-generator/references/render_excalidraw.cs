#:package Microsoft.Playwright@1.52.0
#:property JsonSerializerIsReflectionEnabledByDefault=true

// Render Excalidraw JSON to PNG using Playwright + headless Chromium.
//
// Usage:
//     dotnet run render_excalidraw.cs -- <path-to-file.excalidraw> [--output path.png] [--scale 2] [--width 1920]
//
// First-time setup (one-time only):
//     dotnet run render_excalidraw.cs -- install-browsers

using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Playwright;

const long MaxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

if (args is ["install-browsers"])
    return Microsoft.Playwright.Program.Main(["install", "chromium"]);

try
{
    var (inputPath, outputPath, scale, maxWidth) = ParseArgs(args);
    return await RenderAsync(inputPath, outputPath, scale, maxWidth);
}
catch (UserException ex)
{
    Console.Error.WriteLine($"ERROR: {ex.Message}");
    return 1;
}

async Task<int> RenderAsync(string inputPath, string? outputPath, float scale, int maxWidth)
{
    if (!File.Exists(inputPath))
        throw new UserException($"File not found: {inputPath}");

    var fileInfo = new FileInfo(inputPath);
    if (fileInfo.Length > MaxFileSizeBytes)
        throw new UserException($"File exceeds {MaxFileSizeBytes / 1024 / 1024}MB limit: {fileInfo.Length / 1024 / 1024}MB");

    var raw = await File.ReadAllTextAsync(inputPath);

    var data = JsonNode.Parse(raw)
        ?? throw new UserException("Parsed JSON is null");

    Validate(data);

    outputPath ??= Path.ChangeExtension(inputPath, ".png");
    var outputFull = Path.GetFullPath(outputPath);
    if (!outputFull.EndsWith(".png", StringComparison.OrdinalIgnoreCase))
        throw new UserException("Output path must have a .png extension");

    var elements = data["elements"]!.AsArray()
        .Where(e => e?["isDeleted"]?.GetValue<bool>() != true)
        .ToList();

    var (minX, minY, maxX, maxY) = ComputeBoundingBox(elements!);
    const int padding = 80;
    var vpWidth = Math.Min((int)(maxX - minX + padding * 2), maxWidth);
    var vpHeight = Math.Max((int)(maxY - minY + padding * 2), 600);

    var templatePath = Path.Combine(Directory.GetCurrentDirectory(), "render_template.html");
    if (!File.Exists(templatePath))
        throw new UserException("render_template.html not found. Run from the references/ directory.");

    var templateUrl = new Uri(Path.GetFullPath(templatePath)).AbsoluteUri;

    using var pw = await Playwright.CreateAsync();
    await using var browser = await LaunchBrowserAsync(pw);
    var page = await browser.NewPageAsync(new()
    {
        ViewportSize = new ViewportSize { Width = vpWidth, Height = vpHeight },
        DeviceScaleFactor = scale,
    });

    await page.GotoAsync(templateUrl);
    await page.WaitForFunctionAsync("window.__moduleReady === true", null, new() { Timeout = 30000 });

    var result = await page.EvaluateAsync<JsonElement>(
        "data => window.renderDiagram(data)", data.ToJsonString());

    if (!result.TryGetProperty("success", out var successProp) || !successProp.GetBoolean())
    {
        var errorMsg = result.TryGetProperty("error", out var errorProp)
            ? errorProp.GetString() : "Unknown render error";
        throw new UserException($"Render failed: {errorMsg}");
    }

    var svgEl = await page.QuerySelectorAsync("#root svg")
        ?? throw new UserException("No SVG element found after render.");

    await svgEl.ScreenshotAsync(new() { Path = outputFull });

    Console.WriteLine(outputFull);
    return 0;
}

async Task<IBrowser> LaunchBrowserAsync(IPlaywright pw)
{
    try
    {
        return await pw.Chromium.LaunchAsync(new() { Headless = true });
    }
    catch (PlaywrightException ex) when (
        ex.Message.Contains("Executable doesn't exist") ||
        ex.Message.Contains("browserType.launch"))
    {
        throw new UserException(
            "Chromium not installed for Playwright.\n" +
            "Run: dotnet run render_excalidraw.cs -- install-browsers", ex);
    }
}

static void Validate(JsonNode data)
{
    if (data["type"]?.GetValue<string>() is not "excalidraw")
        throw new UserException($"Expected type 'excalidraw', got '{data["type"]}'");

    if (data["elements"] is not JsonArray { Count: > 0 })
        throw new UserException("Missing or empty 'elements' array");
}

static (double minX, double minY, double maxX, double maxY) ComputeBoundingBox(List<JsonNode> elements)
{
    if (elements.Count == 0)
        return (0, 0, 800, 600);

    double minX = double.MaxValue, minY = double.MaxValue;
    double maxX = double.MinValue, maxY = double.MinValue;

    foreach (var el in elements)
    {
        if (el is null) continue;

        var x = el["x"]?.GetValue<double>() ?? 0;
        var y = el["y"]?.GetValue<double>() ?? 0;
        var w = el["width"]?.GetValue<double>() ?? 0;
        var h = el["height"]?.GetValue<double>() ?? 0;

        if (el["type"]?.GetValue<string>() is "arrow" or "line" && el["points"] is JsonArray points)
        {
            foreach (var pt in points)
            {
                if (pt is not JsonArray pair || pair.Count < 2) continue;
                var px = pair[0]?.GetValue<double>() ?? 0;
                var py = pair[1]?.GetValue<double>() ?? 0;
                minX = Math.Min(minX, x + px);
                minY = Math.Min(minY, y + py);
                maxX = Math.Max(maxX, x + px);
                maxY = Math.Max(maxY, y + py);
            }
        }
        else
        {
            minX = Math.Min(minX, x);
            minY = Math.Min(minY, y);
            maxX = Math.Max(maxX, x + Math.Abs(w));
            maxY = Math.Max(maxY, y + Math.Abs(h));
        }
    }

    return minX == double.MaxValue ? (0, 0, 800, 600) : (minX, minY, maxX, maxY);
}

static (string inputPath, string? outputPath, float scale, int maxWidth) ParseArgs(string[] args)
{
    string? input = null;
    string? output = null;
    float scale = 2;
    int maxWidth = 1920;

    for (int i = 0; i < args.Length; i++)
    {
        switch (args[i])
        {
            case "--help" or "-h":
                throw new UserException(
                    "Usage: dotnet run render_excalidraw.cs -- <path-to-file.excalidraw> [--output path.png] [--scale 2] [--width 1920]\n" +
                    "       dotnet run render_excalidraw.cs -- install-browsers");
            case "--output" or "-o":
                output = NextArg(args, ref i, "--output");
                break;
            case "--scale" or "-s":
                var scaleStr = NextArg(args, ref i, "--scale");
                if (!float.TryParse(scaleStr, CultureInfo.InvariantCulture, out scale))
                    throw new UserException($"Invalid scale value: '{scaleStr}' (expected a number)");
                break;
            case "--width" or "-w":
                var widthStr = NextArg(args, ref i, "--width");
                if (!int.TryParse(widthStr, CultureInfo.InvariantCulture, out maxWidth))
                    throw new UserException($"Invalid width value: '{widthStr}' (expected an integer)");
                break;
            default:
                if (!args[i].StartsWith('-'))
                    input = args[i];
                break;
        }
    }

    if (scale is <= 0 or > 10)
        throw new UserException($"Scale must be between 0 (exclusive) and 10, got: {scale}");
    if (maxWidth is <= 0 or > 7680)
        throw new UserException($"Width must be between 1 and 7680, got: {maxWidth}");

    return input is not null
        ? (input, output, scale, maxWidth)
        : throw new UserException(
            "Usage: dotnet run render_excalidraw.cs -- <path-to-file.excalidraw> [--output path.png] [--scale 2] [--width 1920]\n" +
            "       dotnet run render_excalidraw.cs -- install-browsers");

    static string NextArg(string[] args, ref int i, string flag) =>
        ++i < args.Length ? args[i] : throw new UserException($"{flag} requires a value");
}

class UserException(string message, Exception? inner = null) : Exception(message, inner);
