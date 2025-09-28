# Use the official Jekyll image with Ruby
FROM jekyll/jekyll:4.2.2

# Set the working directory
WORKDIR /srv/jekyll

# Set environment variables
ENV JEKYLL_ENV=development
ENV BUNDLE_PATH=/usr/local/bundle

# Copy Gemfile and Gemfile.lock first for better caching
COPY Gemfile* ./

# Install dependencies
RUN bundle install

# Copy the rest of the site
COPY . .

# Expose port 4000
EXPOSE 4000

# Set default command to serve the site with live reload
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--livereload", "--force_polling"]