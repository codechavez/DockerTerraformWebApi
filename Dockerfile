FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS base
WORKDIR /app
# EXPOSE 5085
# ENV ASPNETCORE_URLS=http://+:5085

FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR /src
ARG compiling

COPY ["DockerTerraApiDemo/DockerTerraApiDemo/", "DockerTerraApiDemo/"]
COPY ["NuGet.config","NuGet.config"] 

RUN dotnet restore --configfile NuGet.config DockerTerraApiDemo/DockerTerraApiDemo.csproj

WORKDIR /src/DockerTerraApiDemo/
RUN dotnet build DockerTerraApiDemo.csproj -c $compiling -o /build

FROM build AS publish
RUN dotnet publish DockerTerraApiDemo.csproj -c $compiling -o /app/publish --self-contained true -r linux-x64

FROM base as final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DockerTerraApiDemo.dll"]