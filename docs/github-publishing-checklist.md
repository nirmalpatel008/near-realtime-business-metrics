# GitHub Publishing Checklist

Use this before pushing the project to GitHub.

## Secrets

Do not commit:

- AWS access keys
- AWS secret keys
- AWS session tokens
- database passwords
- `.env` files
- generated CloudFormation output files
- private keys such as `.pem`, `.key`, `.p12`, or `.pfx`

Use:

```text
.env.example
```

as the public template, and keep real values in your local shell or AWS profile.

## Pre-Push Scan

Run:

```bash
rg -n "AKIA|ASIA|aws_secret_access_key|aws_access_key_id|aws_session_token|AWS_ACCESS_KEY|AWS_SECRET|DB_PASSWORD=|password='|rds.amazonaws.com" .
```

Expected:

- no AWS keys
- no real DB passwords
- no live RDS endpoints

Some harmless matches may appear in docs that explain what not to commit.

## Recommended Tools

Optional but useful:

```bash
pip install detect-secrets
detect-secrets scan > .secrets.baseline
```

Or use GitHub secret scanning after the repo is published.

## Demo Credentials

For articles and screenshots:

- use placeholder values like `<set-a-strong-demo-password>`
- blur account IDs if shown
- avoid showing CloudFormation outputs with live endpoints
- rotate demo passwords after public demos

## Large Files

The repo currently includes presentation and recording assets. Before publishing, decide whether to keep them:

- `.pptx` can be useful for portfolio context
- `.webm` recordings are large and may be better stored in Releases, YouTube, or external storage

The `.gitignore` excludes new video files, but existing tracked files would still need to be removed from git history before publishing if already committed.
