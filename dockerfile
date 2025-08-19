# ─────────────────────────────────────────────────────────────────────────────
# Build stage: restore, build, and publish the .NET 8 app
# Base image is Ubuntu-based .NET SDK
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS build
WORKDIR /src

RUN apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    apt-get install -y aspnetcore-runtime-8.0

# (Optional) Set this to your web project's csproj path relative to the build context.
# If your Dockerfile sits next to the .csproj, the default is fine.
ARG PROJECT=SynapseLinkAutomations.Api/SynapseLinkAutomations.Api.csproj

# Copy everything (simpler when there are project references like SynapseLinkAutomations.Core)
COPY . .

# Restore, build, and publish
RUN dotnet restore "$PROJECT" \
 && dotnet build "$PROJECT" -c Release --no-restore \
 && dotnet publish "$PROJECT" -c Release -o /app/publish --no-build

# ─────────────────────────────────────────────────────────────────────────────
# Runtime stage: ASP.NET Core runtime + Google Chrome + Microsoft Edge
# (Selenium.WebDriver.ChromeDriver & .MSEdgeDriver NuGet packages place
# the drivers alongside the app; we install the browsers here.)
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS runtime
WORKDIR /app

RUN apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    apt-get install -y aspnetcore-runtime-8.0

# Install prerequisites and browsers (Google Chrome + Microsoft Edge)
# Notes:
# - Keep layer count small with a single RUN.
# - We install recommended libs that headless browsers often need.
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg apt-transport-https fonts-liberation \
      libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libdrm2 \
      libgbm1 libgtk-3-0 libnss3 libxcomposite1 libxdamage1 libxfixes3 \
      libxkbcommon0 libxrandr2 xdg-utils; \
    \
    # Google Chrome repo
    install -d /usr/share/keyrings /etc/apt/sources.list.d; \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/googlechrome.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    \
    # Microsoft Edge repo
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
      > /etc/apt/sources.list.d/microsoft-edge.list; \
    \
    # Install browsers
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      google-chrome-stable microsoft-edge-stable; \
    \
    # Clean up apt caches to keep image small
    rm -rf /var/lib/apt/lists/*

# Copy published app (contains your Selenium drivers from NuGet packages)
COPY --from=build /app/publish ./

# ASP.NET Core config
ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Helps some environments; harmless otherwise
    COMPlus_EnableDiagnostics=0

EXPOSE 8080

# Optional: simple health check (adjust path if your app has a custom health endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1

# Run the app
# If your output DLL name differs, the ENTRYPOINT will still resolve the only *.dll present.
# Otherwise, replace with: ENTRYPOINT ["dotnet", "YourWebProject.dll"]
ENTRYPOINT ["bash", "-lc", "exec dotnet SynapseLinkAutomations.Api.dll"]
