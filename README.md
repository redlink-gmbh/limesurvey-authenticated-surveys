# LimeSurvey Auth Surveys
This plugin allows selected surveys to be displayed/submited only to/by authenticated users.

Every survey can have a different configuration/policy.

## Installation instructions

1. Copy **AuthSurvey** folder with its content at **limesurvey/plugins** folder
2. Go to **Admin > Configuration > Plugin Manager** or **https:/example.com/index.php/admin/pluginmanager/sa/index**
and **Enable** the plugin
![Plugin manager with AuthSurveys Enabled](images/plugin_manager.png)
3. Also update the user permissions. As this plugin needs a special permission to be set, please gp to **Configuration > User/User Roles > Select a User/Role > Edit permissions > toggle "Allow user to save plugin settings" on**

## How to enable plugin for specific survey
  1. Go to **Surveys > (Select desired survey) > Simple Plugins** or
**https:/example.com/index.php/admin/survey/sa/rendersidemenulink/surveyid/{survey_id}/subaction/plugins**
  2. Open **Settings for plugin AuthSurvey** accordion
  3. Click **Enabled** checkbox
  ![Plugin settings](images/plugin_settings.png)

## Images for the plugin

This is how the plugin settings look for a specific survey.

![Admin panel image](images/admin_panel.png)

This is what an unauthorized user sees when they try to view/submit a survey that is protected by the plugin.

![Unauthorized Error image](images/unauthorized.png)

## Auth Redirect Extension

Unauthenticated users can optionally be redirected to the admin login instead of seeing a 401 error. After logging in, they are automatically returned to the original survey URL — including the participant token.

Configure it per survey under **Surveys > (Select survey) > Simple Plugins > AuthSurvey** by enabling both **Enabled** and **Redirect to login**.

See the [Auth Redirect Extension](docs/AuthRedirectExtension.md) for full details.
