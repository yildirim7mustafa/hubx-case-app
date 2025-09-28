# DevOps Engineer Test Case

## Core Tasks

- **Dockerize the application:** Create a `Dockerfile` for the application.
- **Use Docker Compose for local development:** Create a `docker-compose.yml` file to run the application and its database locally.
- **Deploy to the cloud:** Deploy the application and its database to a cloud provider of your choice (e.g., AWS, Azure, GCP).
- **Use Terraform for infrastructure:** The cloud infrastructure MUST be managed with Terraform.
- **Automate with GitHub Actions:** Create a GitHub Actions workflow to build and deploy the application.
- **Document your work:** Update this `README.md` with instructions on how to run and deploy the application.

## Requirements

### 1. Containerization

- The application MUST be containerized using Docker.
- A `docker-compose.yml` file MUST be provided for local development.

### 2. Infrastructure as Code (IaC)

- You MUST use Terraform to define and manage the cloud infrastructure.
- Your Terraform code MUST include the application and its dependencies.
- You SHOULD store your Terraform state in a remote backend (like an S3 bucket).

### 3. CI/CD

- You SHOULD create a GitHub Actions workflow to automate the deployment.
- The workflow SHOULD be triggered on pushes to the `main` branch.
- The workflow SHOULD build a Docker image, push it to a container registry, and then run Terraform to deploy.
- Secrets (like cloud provider credentials) MUST be stored in GitHub Secrets, not in the code.

### 4. Documentation

- You MUST update this `README.md` with clear, step-by-step instructions on:
  - How to run the application locally using Docker Compose.
  - How to deploy the application to the cloud using your scripts and Terraform.

### 5. Optionals

- **Infrastructure as Code:** Instead of writing Terraform HCL, use the Cloud Development Kit for Terraform (CDKTF) with TypeScript to define your infrastructure.
- **Testing:** Add a testing framework (like Jest) and write some example unit or integration tests.
- **Database Seeding:** Create a script to easily seed the database with test data for local development.
- **Hot-Reloading:** Configure the local development environment to automatically restart the application when code changes are detected.
- **Improved Documentation:** Enhance the documentation with more details, diagrams, or examples.

## Helpful Commands

- Code Generation: `prisma generate`
- Database Migrations: `prisma migrate deploy`
- API Documentation: `http://localhost:8080/api/documentation`
- Sign up flow
  Request:
  ```
  curl http://localhost:8080/api/auth/sign-up/email \
    --request POST \
    --header 'Content-Type: application/json' \
    --data '{ \
    "name": "asdfasdf", \
    "email": "asdfasdf@asdf.com", \
    "password": "asdfasdf", \
    "image": "", \
    "callbackURL": "", \
    "rememberMe": true \
  }'
  ```
  Response:
  ```
  {
    "token": "kU1bNj9pk8FHkUblgroNnuIeOYpj77tY",
    "user": {
      "id": "8iw7tA5paAgtfxevB9n9wI3WJZ5XQikG",
      "email": "asdfasdf@asdf.com",
      "name": "asdfasdf",
      "image": "",
      "emailVerified": false,
      "createdAt": "2025-09-07T17:33:29.553Z",
      "updatedAt": "2025-09-07T17:33:29.553Z"
    }
  }
  ```
- Sign in flow
  Request:
  ```
  curl http://localhost:8080/api/auth/sign-in/email \
    --request POST \
    --header 'Content-Type: application/json' \
    --data '{ \
    "email": "asdfasdf@asdf.com", \
    "password": "asdfasdf", \
    "callbackURL": "http://localhost:8080/api/documentation", \
    "rememberMe": true \
  }'
  ```
  Response:
  ```
  {
    "redirect": true,
    "token": "PZTM9GMD1oT8t57kcYGXIA1Dow0n6ip9",
    "url": "http://localhost:8080/api/documentation",
    "user": {
      "id": "8iw7tA5paAgtfxevB9n9wI3WJZ5XQikG",
      "email": "asdfasdf@asdf.com",
      "name": "asdfasdf",
      "image": "",
      "emailVerified": false,
      "createdAt": "2025-09-07T17:33:29.553Z",
      "updatedAt": "2025-09-07T17:33:29.553Z"
    }
  }
  ```
