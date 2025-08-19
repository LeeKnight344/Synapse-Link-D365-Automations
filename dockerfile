# ---------- Build ----------
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# copy solution + projects (adjust names/paths if yours differ)
COPY Synapse-Link-D365-Automations.sln ./
COPY SynapseLinkAutomations.Api/*.csproj SynapseLinkAutomations.Api/
COPY SynapseLinkAutomations.Core/*.csproj SynapseLinkAutomations.Core/
RUN dotnet restore "Synapse-Link-D365-Automations.sln"

# copy rest + publish
COPY . .
WORKDIR /src/SynapseLinkAutomations.Api
RUN dotnet publish -c Release -o /app/publish

# ---------- Runtime with Edge ----------
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Install Microsoft Edge (Linux)
RUN apt-get update \
 && apt-get install -y wget gnupg apt-transport-https ca-certificates unzip \
 && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
    > /etc/apt/sources.list.d/microsoft-edge.list \
 && apt-get update \
 && apt-get install -y microsoft-edge-stable \
 && rm -rf /var/lib/apt/lists/* \
 && apt install -y apt-transport-https ca-certificates gnupg \
 && apt-get install wget \
 && wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.de \
 && dpkg -i packages-microsoft-prod.deb \
 && apt update 

RUN apt-get update \
&& apt-get install -y dotnet-sdk-9.0

RUN apt-get update \
&& apt-get install -y aspnetcore-runtime-9.0

# (Linux) msedgedriver to match Edge
RUN set -eux; \
    EDGE_VER="$(microsoft-edge --version | awk '{print $3}')" ; \
    MAJOR="${EDGE_VER%%.*}" ; \
    wget -q "https://msedgedriver.microsoft.com/139.0.3405.86/edgedriver_linux64.zip" -O /tmp/edgedriver.zip \
      || wget -q "hhttps://msedgedriver.microsoft.com/139.0.3405.86/edgedriver_linux64.zip" -O /tmp/edgedriver.zip ; \
    unzip -o /tmp/edgedriver.zip -d /usr/local/bin/ ; \
    chmod +x /usr/local/bin/msedgedriver ; \
    rm -f /tmp/edgedriver.zip

# copy published app
COPY --from=build /app/publish ./

# configure port
EXPOSE 5227
ENV ASPNETCORE_URLS=http://+:5227

# IMPORTANT: use the correct DLL name
CMD ["dotnet", "SynapseLinkAutomations.Api.dll"]
