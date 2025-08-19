
FROM ubuntu:22.04 AS build
WORKDIR /src

ENV http_proxy= \
    https_proxy= \
    HTTP_PROXY= \
    HTTPS_PROXY= \
    ALL_PROXY=

RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" \
      > /etc/apt/sources.list.d/microsoft-prod.list && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/apt/apt.conf.d/*proxy* /etc/apt/apt.conf.d/proxy.conf || true && \
    git config --global --unset-all http.proxy || true && \
    git config --global --unset-all https.proxy || true && \
    rm -f /root/.nuget/NuGet/NuGet.Config || true

ARG PROJECT=SynapseLinkAutomations.Api/SynapseLinkAutomations.Api.csproj

COPY . .
RUN dotnet restore "$PROJECT" \
 && dotnet build "$PROJECT" -c Release --no-restore \
 && dotnet publish "$PROJECT" -c Release -o /app/publish --no-build

FROM ubuntu:22.04 AS runtime
WORKDIR /app

ENV http_proxy= \
    https_proxy= \
    HTTP_PROXY= \
    HTTPS_PROXY= \
    ALL_PROXY=

RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" \
      > /etc/apt/sources.list.d/microsoft-prod.list && \
    apt-get update && \
    apt-get install -y aspnetcore-runtime-8.0 curl && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  apt-get update; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg xdg-utils fonts-liberation unzip \
    libglib2.0-0 libnss3 libasound2 libatk-bridge2.0-0 libatk1.0-0 \
    libdrm2 libgbm1 libgtk-3-0 libxcomposite1 libxdamage1 libxfixes3 \
    libxkbcommon0 libxrandr2; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/googlechrome.gpg; \
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/googlechrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list; \
  apt-get update; \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends google-chrome-stable; \
  rm -rf /var/lib/apt/lists/*
COPY --from=build /app/publish ./

ENV SELENIUM_MANAGER_DISABLED=true
RUN find /app -type f -name "msedgedriver*" -exec chmod +x {} \; || true \
 && find /app -type f -name "chromedriver*" -exec chmod +x {} \; || true
ENV PATH="/app:${PATH}"

#force use of port 5227, this can be changed
ENV ASPNETCORE_URLS=http://+:5227 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    COMPlus_EnableDiagnostics=0
EXPOSE 5227

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:5227/ || exit 1

ENTRYPOINT ["bash", "-lc", "exec dotnet SynapseLinkAutomations.Api.dll"]
