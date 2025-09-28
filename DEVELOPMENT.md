# Development Guide

## 🐳 Docker Development Setup

This guide will help you get your Jekyll site running locally using Docker.

### Quick Start

1. **Clone and navigate to the repository**
   ```bash
   git clone https://github.com/nielsweistra/nielsweistra.github.io.git
   cd nielsweistra.github.io
   ```

2. **Start the development server**
   
   **Windows:**
   ```cmd
   start-dev.bat
   ```
   
   **Linux/macOS:**
   ```bash
   chmod +x start-dev.sh
   ./start-dev.sh
   ```

3. **Open your browser**
   - Navigate to [http://localhost:4000](http://localhost:4000)
   - The site will automatically reload when you make changes

### Docker Commands Reference

```bash
# Build and start (with logs)
docker-compose up --build

# Start in background
docker-compose up -d

# Stop the containers
docker-compose down

# View logs
docker-compose logs -f

# Rebuild from scratch
docker-compose down
docker-compose up --build --force-recreate
```

### Development Workflow

1. **Make changes** to your files (HTML, CSS, Markdown)
2. **Save the files** - changes are automatically detected
3. **Browser refreshes automatically** via LiveReload
4. **No manual restart needed** for most changes

### Troubleshooting

#### Port Already in Use
If port 4000 is already in use:

```bash
# Find what's using port 4000
netstat -ano | findstr :4000

# Kill the process (Windows)
taskkill /PID <PID> /F

# Or use different ports in docker-compose.yml
ports:
  - "4001:4000"  # Change 4001 to any available port
```

#### Container Won't Start
```bash
# Clean up and restart
docker-compose down
docker system prune -f
docker-compose up --build
```

#### Permission Issues (Linux/macOS)
```bash
# Fix ownership of generated files
sudo chown -R $USER:$USER _site .sass-cache .jekyll-cache
```

### File Structure

```
├── Dockerfile              # Docker image configuration
├── docker-compose.yml      # Docker Compose services
├── .dockerignore           # Files to exclude from Docker build
├── start-dev.sh            # Development startup script (Linux/macOS)
├── start-dev.bat           # Development startup script (Windows)
└── DEVELOPMENT.md          # This file
```

### Environment Variables

You can customize the Jekyll environment by editing `docker-compose.yml`:

```yaml
environment:
  - JEKYLL_ENV=development    # development, production
  - BUNDLE_PATH=/usr/local/bundle
```

### Performance Tips

1. **Use volume caching** - The Docker Compose file includes bundle caching
2. **Exclude unnecessary files** - Update `.dockerignore` if needed
3. **Use polling** - Force polling is enabled for better file change detection

### Production Build

To build for production:

```bash
# Build production version
docker-compose exec jekyll bundle exec jekyll build --env=production

# Or build a production Docker image
docker build -t nielsweistra-site:production --build-arg JEKYLL_ENV=production .
```

## 🚀 Deployment

The site automatically deploys to GitHub Pages when you push to the `main` branch. No additional deployment steps are needed.

### Manual GitHub Pages Deployment

If you need to trigger a manual deployment:

1. Go to your GitHub repository
2. Navigate to **Actions** tab
3. Find the **Jekyll** workflow
4. Click **Run workflow** button

## 📝 Content Updates

### Adding Blog Posts

1. Create a new file in `_posts/` with the format: `YYYY-MM-DD-title.md`
2. Add front matter:
   ```yaml
   ---
   layout: post
   title: "Your Post Title"
   date: 2025-09-28
   categories: [devops, kubernetes]
   tags: [docker, azure, ci-cd]
   ---
   ```
3. Write your content in Markdown
4. Save and the site will automatically update

### Updating Skills Matrix

Edit the skills section in `index.html`:
- Update skill names, experience years, and proficiency levels
- Modify progress bar values (`data-width` attribute)
- Add or remove skill categories as needed

### Customizing Design

- **Colors**: Update CSS custom properties in `_layouts/default.html`
- **Fonts**: Modify the Google Fonts import in the `<head>` section
- **Layout**: Adjust the grid and flexbox layouts in the CSS

## 🔍 Debugging

### Jekyll Build Issues

```bash
# Check Jekyll version and dependencies
docker-compose exec jekyll bundle exec jekyll --version
docker-compose exec jekyll bundle list

# Verbose build output
docker-compose exec jekyll bundle exec jekyll build --verbose
```

### Checking Logs

```bash
# Real-time logs
docker-compose logs -f jekyll

# Specific container logs
docker logs nielsweistra-github-io
```

### Common Issues

1. **Gemfile.lock conflicts**: Delete `Gemfile.lock` and rebuild
2. **Cache issues**: Clear Jekyll cache: `rm -rf .jekyll-cache _site .sass-cache`
3. **Live reload not working**: Check that port 35729 is accessible

## 📞 Support

If you encounter issues:

1. Check this development guide
2. Review the [Jekyll documentation](https://jekyllrb.com/docs/)
3. Check [GitHub Pages documentation](https://docs.github.com/en/pages)
4. Open an issue in the repository