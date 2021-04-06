FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
# If you want specific port
# EXPOSE 5085
# ENV ASPNETCORE_URLS=http://+:5085
ARG compile=__BuildConfiguration__


FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
# If you have more than one project(s)
# COPY ["<location>/", "<destination>/"]
COPY ["DockerTerraApiDemo/DockerTerraApiDemo/", "DockerTerraApiDemo/DockerTerraApiDemo/"]
COPY ["NuGet.config","NuGet.config"] 

RUN dotnet restore --configfile NuGet.config DockerTerraApiDemo/DockerTerraApiDemo/DockerTerraApiDemo.csproj --force

COPY . .

WORKDIR /src/DockerTerraApiDemo/DockerTerraApiDemo/
RUN dotnet build DockerTerraApiDemo.csproj -c $compile -o /build

FROM build AS publish
RUN dotnet publish DockerTerraApiDemo.csproj -c $compile -o /app/publish --self-contained true -r linux-x64

FROM base as final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DockerTerraApiDemo.csproj.dll"]