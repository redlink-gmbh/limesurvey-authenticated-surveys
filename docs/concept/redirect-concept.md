# Redirect Extension Concept — AuthSurvey Plugin

**Ticket:** [Auth2 Plugin Extension]: Redirect #36
**Status:** Concept / Pre-implementation review

---

## 1. Current Behavior

The plugin subscribes to `beforeSurveyPage`. When `auth_protection_enabled` is `true` for a survey and the visitor has no active session (`Yii::app()->user->getId()` returns `null`), it throws a **hard HTTP 401 exception**:

```php
throw new CHttpException(401, gT("We are sorry but you do not have permissions to do this."));
```

This produces a generic error page. There is no redirect, no return path, and no way for the user to recover without manually navigating to the login page and then re-opening their link.

---

## 2. Proposed Behavior (from Ticket)

| Step | Who | Action |
|------|-----|--------|
| 1 | Admin | Copies survey URL with participant token, sends it |
| 2a | Recipient (logged in) | Opens link → sees survey immediately |
| 2b | Recipient (not logged in) | Opens link → redirected to admin login |
| 2c | Recipient (after login) | Redirected back to original URL with token intact |

---

## 3. Technical Approach

### 3.1 The return URL requires no configuration

The ticket asks: *"if it is needed to set a redirect link, it should be set in the plugin settings"*. No manual configuration is needed. The return URL is captured automatically from the incoming HTTP request (`requestUri`) at the moment the unauthenticated user hits the survey page. It is written to the server-side session by the plugin — neither the sending admin nor the receiving user needs to do anything special. The admin sends the survey link exactly as they would today.

### 3.2 How the return URL survives the login

The round-trip works via the same Yii1 session mechanism LimeSurvey uses internally for admin pages.

**AdminController.php** — when an unauthenticated request hits any admin page, LimeSurvey does:
```php
App()->user->setReturnUrl(App()->request->requestUri);
$this->redirect(array('/admin/authentication/sa/login'));
```

**Authentication.php** — after every successful login:
```php
private static function doRedirect()
{
    // ...
    $returnUrl = App()->user->getReturnUrl(array('/admin'));
    Yii::app()->getController()->redirect($returnUrl);
}
```

`setReturnUrl` / `getReturnUrl` are Yii1 `CWebUser` methods that read/write a key in the PHP session. They are not tied to `AdminController` — they are available globally via `Yii::app()->user` from any context, including our plugin. Since the survey page never passes through `AdminController`, that automatic `setReturnUrl` call never happens for survey URLs. **Our plugin replicates that one call itself** before redirecting to login, and `doRedirect()` picks it up after successful authentication.

The full round-trip:

1. User hits survey URL (unauthenticated)
2. Plugin calls `setReturnUrl(requestUri)` → survey URL + token written to session
3. Plugin redirects to `/admin/authentication/sa/login`
4. User logs in → `Authentication.php::doRedirect()` calls `getReturnUrl()` → reads survey URL from session → redirects there
5. User lands on survey page, now authenticated → survey loads

No GET parameters, no changes to LimeSurvey itself, no workarounds needed.

### 3.3 New plugin setting

A second per-survey checkbox is added alongside `auth_protection_enabled`:

| Setting key | Type | Default | Label |
|---|---|---|---|
| `redirect_on_unauthenticated` | checkbox | `false` | Redirect to login instead of showing error |

Behavior matrix:

| `auth_protection_enabled` | `redirect_on_unauthenticated` | Result |
|---|---|---|
| OFF | — | Survey loads normally |
| ON | OFF | HTTP 401 error page (existing behavior) |
| ON | ON | Redirect to admin login, return to survey after login |

This is a non-breaking addition: existing surveys keep their current 401 behavior until an admin explicitly opts in to the redirect.

---

## 4. Questions & Decisions

### Q1 — Does LimeSurvey's admin login page respect `returnUrl`? *(resolved)*

Yes, via session. `Authentication.php::doRedirect()` calls `App()->user->getReturnUrl()` after every successful login. Our plugin writes to that same session slot using `setReturnUrl()` before redirecting. The full round-trip works with no external dependencies.

### Q2 — One setting or two? *(resolved)*

Two independent per-survey checkboxes. `redirect_on_unauthenticated` changes the behavior of `auth_protection_enabled` from a hard block to a redirect. Default is `false` to preserve existing behavior.

### Q3 — Which request method returns the right URL? *(resolved)*

`Yii::app()->request->requestUri`, mirroring what `AdminController` uses. This returns the path + query string as sent by the browser and preserves the participant token regardless of URL format (clean URLs or query string).

### Q4 — Security: open redirect risk *(non-issue)*

The `returnUrl` is written to the server-side session by our code using the server's own `requestUri` — it is never sourced from user input or a GET parameter. There is no open redirect vector.

### Q5 — Who are the users? *(resolved)*

All survey respondents in this deployment have a LimeSurvey admin account via the client's platform integration. Redirecting to `/admin/authentication/sa/login` is correct.

---

## 5. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `setReturnUrl` overwritten if admin middleware fires after our plugin | Low | Medium | `beforeSurveyPage` fires on frontend routes only; `AdminController` fires on admin routes — no overlap |
| Survey token expires between redirect and return | Low | Low | Tokens are typically long-lived or session-persistent |
| `requestUri` differs from the URL the user has in their browser (e.g. reverse proxy rewrites) | Very Low | Low | Standard server-side concern, not specific to this plugin |
| New setting not visible to admins without `plugin_settings` permission | None (by design) | None | Same permission guard as the existing setting |

---

## 6. Implementation Steps

### Step 1 — `AuthSurvey/AuthSurvey.php`: add the new setting to `beforeSurveySettings()`

Add `redirect_on_unauthenticated` as a second entry in the `settings` array, directly after `auth_protection_enabled`:

```php
'redirect_on_unauthenticated' => [
    'type'    => 'checkbox',
    'label'   => 'Redirect to login',
    'help'    => 'Redirect unauthenticated users to the admin login instead of showing a 401 error.',
    'default' => false,
    'current' => $this->get('redirect_on_unauthenticated', 'Survey', $event->get('survey')),
],
```

### Step 2 — `AuthSurvey/AuthSurvey.php`: update `beforeSurveyPage()`

Replace the current 401 throw with redirect logic. The plugin does not use `AdminController`, so it must call `setReturnUrl()` itself — this is the same call `AdminController` makes for admin pages, and `Authentication.php::doRedirect()` reads from the same session slot after login.

```php
public function beforeSurveyPage()
{
    $event = $this->event;
    $id = $event->get('surveyId');
    $flag = $this->get('auth_protection_enabled', 'Survey', $id);

    if ($flag && is_null(Yii::app()->user->getId())) {
        $redirectEnabled = $this->get('redirect_on_unauthenticated', 'Survey', $id);
        if ($redirectEnabled) {
            Yii::app()->user->setReturnUrl(Yii::app()->request->requestUri);
            Yii::app()->getController()->redirect(array('/admin/authentication/sa/login'));
            Yii::app()->end();
        } else {
            throw new CHttpException(401, gT("We are sorry but you do not have permissions to do this."));
        }
    }
}
```

### Step 3 — `AuthSurvey/config.xml`: bump the version

```xml
<version>1.1.0</version>
<lastUpdate>2026-05-06</lastUpdate>
```

### Step 4 — Manual verification

Test the following scenarios against a LimeSurvey 6 instance:

| Scenario | Expected result |
|---|---|
| Survey with both settings OFF | Survey loads normally |
| Survey with auth ON, redirect OFF, user not logged in | HTTP 401 error page |
| Survey with auth ON, redirect ON, user not logged in | Redirect to admin login |
| After login (redirect ON scenario) | User lands back on the original survey URL with token intact |
| Survey with auth ON, redirect ON, user already logged in | Survey loads normally, no redirect |
