# 使用 .NET 10 SDK 镜像构建
FROM mcr.microsoft.com/dotnet/sdk:10.0-preview AS build
WORKDIR /src

# 复制项目文件并还原依赖
COPY ["CiticGmApi.csproj", "./"]
RUN dotnet restore "CiticGmApi.csproj"

# 复制所有源代码并构建
COPY . .
RUN dotnet build "CiticGmApi.csproj" -c Release -o /app/build

# 发布
FROM build AS publish
RUN dotnet publish "CiticGmApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 运行时镜像
FROM mcr.microsoft.com/dotnet/aspnet:10.0-preview AS final
WORKDIR /app

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 暴露端口
EXPOSE 8080

# 从发布阶段复制文件
COPY --from=publish /app/publish .

# 设置环境变量
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# 启动应用
ENTRYPOINT ["dotnet", "CiticGmApi.dll"]
