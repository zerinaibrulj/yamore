using DotNetEnv;

namespace Yamore.API.Configuration;

/// <summary>
/// Loads a <c>.env</c> file into process environment variables so <c>WebApplication.CreateBuilder</c> picks them up.
/// Searches upward from the current directory and app base path for a file named <c>.env</c> (e.g. <c>Yamore/.env</c> next to <c>docker-compose.yml</c>).
/// Does not load committed JSON for secrets; Docker Compose and CI still inject the same <c>KEY__Nested</c> variable names.
/// </summary>
public static class LocalEnvFileLoader
{
    public static void Load()
    {
        // Prefer .env in the same folder as docker-compose.yml (e.g. Yamore/.env next to Yamore/docker-compose.yml).
        // A plain "first .env walking up" can match an unrelated file if one exists high in the tree, leaving STRIPE_*
        // unset in process and allowing User Secrets to supply a different (invalid) Stripe key.
        if (TryLoadEnvInDockerComposeDirectory())
            return;

        var path = FindFirstEnvFilePath();
        if (string.IsNullOrEmpty(path) || !File.Exists(path))
            return;

        // Makes KEY=value available as environment variables; nested keys use double-underscore, e.g. ConnectionStrings__DefaultConnection
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
