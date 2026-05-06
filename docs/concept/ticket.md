## [Auth2 Plugin Extension]: Redirect #36

The Auth2 Plugin isn't able to provide a redirect from the survey to the login and back. It will only lock the survey itself, when the user isn't logged in limesurvey auth.

To help with usability and enable sending the survey links directly to the user (without confusion), the 3rd party plugin has to be extended with a redirect, that works as follows:

1. An logged in Admin copies the url for the survey for a specific participant (with token) from the adimn interface and sends it to anyone that needs that
2. The reciever of that link clicks directly on the link
   a. if they are logged in he can immediately work with the limesurvey in question
   b. if they are not logged in the plugin redirects to the admin interface where they can logg in
   c. if possible the admin interface should redirect back to the link they came from (with participant token) so the user can continue with his work immediately (workaround -> the user has to reopen the link with token in the browser)

### Acceptace criteria
- [ ] If survey url is opened without a logged in user, it should redirect to admin login
- [ ] After login the user should be redirected back to where they came from (needs to be verified if possible)

### Implementation notes
- If it is needed to set a redirect link, it should be set in the plugin settings directly. If lime survey can handle that out of the box - that would be the preferred solution.
- The redirect should be possible to activate via survey plugin settings

