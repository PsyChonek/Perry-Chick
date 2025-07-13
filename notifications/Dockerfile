# Perry Chick Notifications Service Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["PerryChick.Notifications.csproj", "./"]
RUN dotnet restore "PerryChick.Notifications.csproj"
COPY . .
RUN dotnet build "PerryChick.Notifications.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PerryChick.Notifications.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "PerryChick.Notifications.dll"]
