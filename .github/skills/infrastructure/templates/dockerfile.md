# Dockerfile Template

Multi-stage Dockerfile for .NET 10 services.

## Template

```dockerfile
# Base runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER app
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
ARG GITHUB_PAT
ARG VERSION

# Configure NuGet for private packages
RUN dotnet nuget add source https://nuget.pkg.github.com/myorganization/index.json \
    -n "github" -u "docker" -p "$GITHUB_PAT" --store-password-in-clear-text

WORKDIR /build

# Copy build configuration files first (better layer caching)
COPY ["Directory.Packages.props", "./"]
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Build.targets", "./"]
COPY ["global.json", "./"]

# Copy project file and restore
COPY ["src/{ProjectName}/{ProjectName}.csproj", "src/{ProjectName}/"]
RUN dotnet restore "./src/{ProjectName}/{ProjectName}.csproj" -p:Configuration=Release

# Copy source and build
COPY . .
WORKDIR "/build/src/{ProjectName}"

# Publish stage
FROM build AS publish
RUN dotnet publish "./{ProjectName}.csproj" \
    -c $BUILD_CONFIGURATION \
    -o /app/publish \
    /p:UseAppHost=false \
    /p:Version=${VERSION:-$(date "+%y.%m%d.%H%M")}

# Final runtime image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "{ProjectName}.dll"]
```

## Placeholders

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `{ProjectName}` | Your project name | `MyOrganization.MyService.Host` |

## Usage

### Build Command

```bash
docker build \
  --build-arg GITHUB_PAT=$GITHUB_PAT \
  --build-arg VERSION=1.0.0 \
  -t myservice:1.0.0 \
  -f src/MyService.Host/Dockerfile \
  .
```

### Multi-Project Solution

If your service depends on other projects in the solution, ensure all project files are copied before restore:

```dockerfile
# Copy all project files for restore
COPY ["src/MyService.Host/MyService.Host.csproj", "src/MyService.Host/"]
COPY ["src/MyService.Core/MyService.Core.csproj", "src/MyService.Core/"]
COPY ["src/MyService.Infrastructure/MyService.Infrastructure.csproj", "src/MyService.Infrastructure/"]
RUN dotnet restore "./src/MyService.Host/MyService.Host.csproj" -p:Configuration=Release
```

## Layer Optimization

The Dockerfile is structured for optimal layer caching:

1. **Base image** - Changes rarely
2. **Build configuration files** - Changes occasionally
3. **Project files + restore** - Changes when dependencies change
4. **Source code** - Changes frequently
5. **Publish** - Rebuilds when source changes
6. **Final image** - Always rebuilt

## Security Notes

- `USER app` runs as non-root (UID 1654)
- No secrets stored in image layers
- GitHub PAT only used during build (not in final image)
- Use specific version tags, not `latest`
