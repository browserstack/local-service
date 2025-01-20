# TODO Application - Podman Setup Guide

This document includes step-by-step instructions for configuring the Rails application and MySQL database.

---

## 1. Cloning the Repository

Run the following commands to clone the application source code:

```bash
git clone <repository-url>
cd new_Rails
```

---

## 2. Building the Rails Application Container

To build the container image for the Rails application using Podman, run:

```bash
podman build -t new_rails -f Podmanfile .
```

This installs all necessary dependencies, including Ruby, Bundler, and associated gem libraries.

---

## 3. MySQL Database Configuration

### 3.1 Creating a Podman Network

Establish a custom network for the application and database communication:

```bash
podman network create my-network
```

### 3.2 Running the MySQL Container

Deploy the MySQL database container with:

```bash
podman run -d --name mysql-server \
  --network my-network \
  -e MYSQL_ROOT_PASSWORD=your_password \
  -e MYSQL_DATABASE=your_app_development \
  -p 3307:3306 \
  mysql:latest
```

**Access Credentials:**

- **Username:** `root`
- **Password:** `your_password`
- **Database:** `your_app_development`

---

## 4. Configuring Rails Application (if not already there)

Update the `config/database.yml` file with:

```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: 5
  username: root
  password: your_password
  host: mysql-server  # MySQL container hostname
  port: 3306

development:
  <<: *default
  database: your_app_development

test:
  <<: *default
  database: your_app_test
```

---

## 5. Running the Rails Application

Start the Rails application container within the established network:

```bash
podman run -d --rm --name my-new-app \
  --network my-network \
  -v $(pwd):/app -p 3000:3000 new_rails
```

The application will be accessible at **[http://localhost:3000](http://localhost:3000)**.

---

## 6. Initializing the Database

1. Access the running Rails container:

   ```bash
   podman exec -it my-new-app bash
   ```

2. Run database setup commands:

   ```bash
   rails db:create
   rails db:migrate
   ```

---

## 7. Accessing the Application

- Open `http://localhost:3000` in your web browser.
- Perform CRUD operations within the TODO list interface.

---

## 8. Stopping and Removing Containers

To stop running containers:

```bash
podman stop my-new-app
podman stop mysql-server
```

To remove containers permanently:

```bash
podman rm my-new-app
podman rm mysql-server
```

---

### Application Accessibility Issues

- Ensure the Rails container is running:
  ```bash
  podman ps
  ```
- Check Rails logs for errors:
  ```bash
  podman logs my-new-app
  ```
