FROM node:18

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first for better caching
COPY backend/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files from backend
COPY backend/. .

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["npm", "run", "start"]

