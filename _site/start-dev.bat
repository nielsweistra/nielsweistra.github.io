@echo off
REM Start the Jekyll site locally using Docker Compose

echo 🚀 Starting Jekyll site locally...
echo 📍 Site will be available at: http://localhost:4000
echo 🔄 LiveReload will be available at: http://localhost:35729
echo.

REM Build and start the containers
docker-compose up --build

echo.
echo ✅ Site is now running!
echo 📝 Make changes to your files and they will be automatically reloaded
echo 🛑 Press Ctrl+C to stop the server