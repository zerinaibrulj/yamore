using DotNetEnv;

namespace Yamore.Worker;

/// <summary>
/// Same behavior as the API: loads <c>Yamore/.env</c> (found by walking up from the working directory) so Host configuration receives RabbitMQ, SMTP, etc.
/// </summary>
public static class LocalEnvFileLoader
{
    public static void Load()
    {
        if (TryLoadEnvInDockerComposeDirectory())
            return;

        var path = FindFirstEnvFilePath();
        if (string.IsNullOrEmpty(path) || !File.Exists(path))
            return;

        Env.Load(path, new LoadOptions(onlyExactPath: true, setEnvVars: true, clobberExistingVars: true));
    }

    private static bool TryLoadEnvInDockerComposeDirectory()
    {
        const string yml = "docker-compose.yml";
        foreach (var p in GetPathsToCheckFromDirectoryWalk())
        {
            if (!File.Exists(p) || !string.Equals(Path.GetFileName(p), yml, StringComparison.OrdinalIgnoreCase))
                continue;
            var envPath = Path.Combine(Path.GetDirectoryName(p)!, ".env");
            if (File.Exists(envPath))
            {
                Env.Load(envPath, new LoadOptions(onlyExactPath: true, setEnvVars: true, clobberExistingVars: true));
                return true;
            }
        }
        return false;
    }

    private static IEnumerable<string> GetPathsToCheckFromDirectoryWalk()
    {
        var seeds = new List<string?>();
        try { seeds.Add(Directory.GetCurrentDirectory()); } catch { }
        try { if (!string.IsNullOrEmpty(AppContext.BaseDirectory)) seeds.Add(AppContext.BaseDirectory); } catch { }

        foreach (var start in seeds)
        {
            if (string.IsNullOrEmpty(start))
                continue;
            for (var dir = new DirectoryInfo(start); dir != null && dir.Exists; dir = dir.Parent)
            {
                var p = Path.Combine(dir.FullName, "docker-compose.yml");
                if (File.Exists(p))
                {
                    yield return p;
                    break;
                }
            }
        }
    }

    private static string? FindFirstEnvFilePath()
    {
        foreach (var p in FindAllEnvFilePaths())
            return p;
        return null;
    }

    private static IEnumerable<string> FindAllEnvFilePaths()
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var seeds = new List<string?>();
        try
        {
            seeds.Add(Directory.GetCurrentDirectory());
        }
        catch
        {
            // ignored
        }

        try
        {
            if (!string.IsNullOrEmpty(AppContext.BaseDirectory))
                seeds.Add(AppContext.BaseDirectory);
        }
        catch
        {
            // ignored
        }

        foreach (var start in seeds)
        {
            if (string.IsNullOrEmpty(start))
                continue;
            for (var dir = new DirectoryInfo(start); dir != null && dir.Exists; dir = dir.Parent)
            {
                var p = Path.Combine(dir.FullName, ".env");
                if (File.Exists(p) && seen.Add(p))
                {
                    yield return p;
                    yield break;
                }
            }
        }
    }
}
