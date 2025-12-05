# 🎬 act - Local GitHub Actions Testing

## What is act?

`act` allows you to run GitHub Actions workflows locally using Docker, eliminating the need to push constantly to test your CI/CD pipeline.

## Prerequisites

1. **Docker Desktop** must be running
2. **act** is installed (already done: `brew install act`)

## Quick Start

### 1. List Available Workflows

```bash
./scripts/validate-pipeline.sh
```

This shows all workflows and jobs that can be executed locally.

### 2. Run a Specific Workflow

```bash
# Run Apex tests workflow
./scripts/validate-pipeline.sh -w apex-tests.yml

# Run LWC tests workflow
./scripts/validate-pipeline.sh -w lwc-tests.yml

# Run E2E tests workflow (careful - this is heavy!)
./scripts/validate-pipeline.sh -w e2e-tests.yml
```

### 3. Run a Specific Job

```bash
# Run only the "test" job from apex-tests.yml
./scripts/validate-pipeline.sh -w apex-tests.yml -j test

# Run only the "lint" job
./scripts/validate-pipeline.sh -w apex-tests.yml -j lint
```

### 4. Dry Run (See What Would Execute)

```bash
# Show what would run without actually executing
./scripts/validate-pipeline.sh -d

# Dry run for specific workflow
./scripts/validate-pipeline.sh -w apex-tests.yml -d
```

## Configuration

### `.actrc`

Configuration file for act. Already created with:

- Docker image: `catthehacker/ubuntu:act-latest`
- Secrets file: `.env.act`
- Insecure mode (for local testing)

### `.env.act` (Optional)

Create this file for workflows that need secrets:

```bash
cp .env.act.example .env.act
# Edit .env.act with your credentials
```

**Note:** `.env.act` is gitignored for security.

## Common Use Cases

### Validate PR Before Pushing

```bash
# Run all CI checks locally
./scripts/validate-pipeline.sh -w ci.yml
```

### Test Deployment Workflow

```bash
# Dry run to see deployment steps
./scripts/validate-pipeline.sh -w deploy.yml -d
```

### Debug Failing Workflow

```bash
# Run specific job to debug
./scripts/validate-pipeline.sh -w apex-tests.yml -j test
```

## Limitations

⚠️ **What act CAN'T do:**

1. **Salesforce-specific actions** - Can't actually deploy to SFDX orgs
2. **GitHub-specific features** - Can't access GitHub secrets, environments, etc.
3. **Heavy workflows** - E2E tests might be slow or fail due to browser automation

✅ **What act CAN do:**

1. **Syntax validation** - Verify workflow YAML is correct
2. **Job dependencies** - Test job ordering and conditions
3. **Scripts & commands** - Run shell scripts, Node.js scripts
4. **Linting & unit tests** - Run locally without Salesforce connection

## Tips

### Speed Up Execution

```bash
# Use smaller Docker image for simple checks
act -P ubuntu-latest=node:18-alpine
```

### Interactive Debugging

```bash
# Run with interactive shell on failure
act --container-options "--interactive --tty"
```

### Clean Up Docker Containers

```bash
# Remove all act containers after testing
docker ps -a | grep act- | awk '{print $1}' | xargs docker rm
```

## Resources

- [act GitHub Repo](https://github.com/nektos/act)
- [act Documentation](https://nektosact.com/)
- [Docker Images for act](https://github.com/catthehacker/docker_images)

## Troubleshooting

### Docker Not Running

```
❌ Docker is not running
```

**Solution:** Start Docker Desktop

### act Not Installed

```
❌ act is not installed
```

**Solution:** `brew install act`

### Workflow Fails Locally But Works on GitHub

This is expected! Some workflows use GitHub-specific features. Focus on validating:

- YAML syntax
- Job structure
- Script logic
- Dependencies

---

**Remember:** act is a development tool. Always verify critical changes on actual GitHub Actions before merging to main.
