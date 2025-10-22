# Use a simple Nginx image
FROM nginx:alpine
# Remove default content
RUN rm /usr/share/nginx/html/index.html
# Add a file to show which version we are
RUN echo "Welcome - Version 1 (Blue)" > /usr/share/nginx/html/index.html
EXPOSE 80
