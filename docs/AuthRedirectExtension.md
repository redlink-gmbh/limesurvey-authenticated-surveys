# AuthSurvey Plugin — User Documentation

## Overview

The AuthSurvey plugin restricts survey access to authenticated LimeSurvey users. This document covers the redirect feature added in version 1.1.0, which improves the experience for users who open a survey link without being logged in.

---

## Features

### Auth Protection

When enabled for a survey, unauthenticated users are blocked from viewing or submitting it.

### Redirect to Login (new in 1.1.0)

When enabled alongside auth protection, unauthenticated users are automatically redirected to the admin login page. After a successful login, they are sent back to the original survey URL — including the participant token — so they can continue without any extra steps.

---

## Per-Survey Settings

Both settings are configured per survey under **Surveys > (Select survey) > Simple Plugins > AuthSurvey**.

| Setting | Default | Description |
|---|---|---|
| **Enabled** | Off | Restrict the survey to authenticated users only |
| **Redirect to login** | Off | Redirect unauthenticated users to the admin login instead of showing a 401 error |

### Behavior matrix

| Enabled | Redirect to login | Result |
|---|---|---|
| Off | — | Survey is accessible to everyone |
| On | Off | Unauthenticated users see a 401 error page |
| On | On | Unauthenticated users are redirected to the admin login and returned to the survey after login |

---

## How to Use the Redirect Feature

1. Enable **Enabled** for the survey (auth protection must be active for the redirect to apply).
2. Enable **Redirect to login** for the same survey.
3. Copy the survey URL with the participant token from the admin interface and send it to the recipient.

When the recipient opens the link:
- If they are already logged in, the survey loads immediately.
- If they are not logged in, they are redirected to the admin login page. After logging in, they land back on the original survey URL with their token intact.

No additional configuration is needed. The return URL is captured automatically — neither the admin nor the recipient has to do anything special.

---

## Requirements

- LimeSurvey 6
- AuthSurvey plugin version 1.1.0 or later
- The survey respondents must have a LimeSurvey admin account (this is required for the login redirect to work)
