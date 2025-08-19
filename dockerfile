# ---------- Build (Ubuntu) ----------
FROM ubuntu:24.04 AS build
WORKDIR /src

# Install .NET SDK
RUN apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    apt-get install -y dotnet-runtime-9.0


# copy solution + projects (adjust names/paths if yours differ)
COPY Synapse-Link-D365-Automations.sln ./
COPY SynapseLinkAutomations.Api/*.csproj SynapseLinkAutomations.Api/
COPY SynapseLinkAutomations.Core/*.csproj SynapseLinkAutomations.Core/
RUN dotnet restore "Synapse-Link-D365-Automations.sln"

# copy rest + publish
COPY . .
WORKDIR /src/SynapseLinkAutomations.Api
RUN dotnet publish -c Release -o /app/publish

FROM ubuntu:24.04 AS runtime


# Install Microsoft Edge (Ubuntu) + matching WebDriver
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget gnupg ca-certificates apt-transport-https unzip; \
    install -d -m 0755 /etc/apt/keyrings; \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg; \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends microsoft-edge-stable; \
    # Download the WebDriver that matches the installed Edge version
    EDGE_VER="$(microsoft-edge --version | awk '{print $3}')"; \
    wget -q "https://msedgedriver.azureedge.net/${EDGE_VER}/edgedriver_linux64.zip" -O /tmp/edgedriver.zip; \
    unzip -o /tmp/edgedriver.zip -d /usr/local/bin/; \
    chmod +x /usr/local/bin/msedgedriver; \
    rm -f /tmp/edgedriver.zip; \
    rm -rf /var/lib/apt/lists/*

# copy published app
COPY --from=build /app/publish ./

# configure port
EXPOSE 5227
ENV ASPNETCORE_URLS=http://+:5227

# IMPORTANT: use the correct DLL name
CMD ["dotnet", "SynapseLinkAutomations.Api.dll"]
