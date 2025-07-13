# Perry Chick Backend Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["PerryChick.Api.csproj", "./"]
RUN dotnet restore "PerryChick.Api.csproj"
COPY . .
RUN dotnet build "PerryChick.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PerryChick.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create logs directory
RUN mkdir -p /app/logs

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "PerryChick.Api.dll"]
