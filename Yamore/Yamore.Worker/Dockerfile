FROM mcr.microsoft.com/dotnet/sdk:8.0-bookworm-slim AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["Yamore.Configuration/Yamore.Configuration.csproj", "Yamore.Configuration/"]
COPY ["Yamore.Worker/Yamore.Worker.csproj", "Yamore.Worker/"]
COPY ["Yamore.Services/Yamore.Services.csproj", "Yamore.Services/"]
COPY ["Yamore.Model/Yamore.Model.csproj", "Yamore.Model/"]
RUN dotnet restore "./Yamore.Worker/Yamore.Worker.csproj"

COPY . .
WORKDIR "/src/Yamore.Worker"
RUN dotnet publish "./Yamore.Worker.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:8.0-bookworm-slim AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Yamore.Worker.dll"]
