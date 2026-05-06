<?php

/**
 * LimeSurvey Auth permitted Surveys
 *
 * This plugin forces selected surveys to
 * be displayed/submitted only to/by authenticated users
 *
 * Author: Panagiotis Karatakis <karatakis@it.auth.gr>
 * Licence: GPL3
 *
 * Sources:
 * https://manual.limesurvey.org/Plugins_-_advanced
 * https://manual.limesurvey.org/Plugin_events
 * https://medium.com/@evently/creating-limesurvey-plugins-adcdf8d7e334
 */

class AuthSurvey extends Limesurvey\PluginManager\PluginBase
{
    protected $storage = 'DbStorage';
    static protected $description = 'This plugin forces selected surveys to be displayed/submitted only to/by authenticated users';
    static protected $name = 'AuthSurvey';

    protected $settings = [];

    public function init()
    {
        $this->subscribe('beforeSurveySettings');
        $this->subscribe('newSurveySettings');
        $this->subscribe('beforeSurveyPage');
        $this->subscribe('getGlobalBasePermissions');
    }

    public function beforeSurveySettings()
    {
        $permission = Permission::model()->hasGlobalPermission('plugin_settings', 'update');
        if ($permission) {
            $event = $this->event;
            $current = $this->get('auth_protection_enabled', 'Survey', $event->get('survey'));
            $event->set('surveysettings.' . $this->id, [
                'name' => get_class($this),
                'settings' => [
                    'auth_protection_enabled' => [
                        'type' => 'checkbox',
                        'label' => 'Enabled',
                        'help' => 'Only authenticated users should see the survey ?',
                        'default' => false,
                        'current' => $current,
                    ],
                    'redirect_on_unauthenticated' => [
                        'type'    => 'checkbox',
                        'label'   => 'Redirect to login',
                        'help'    => 'Redirect unauthenticated users to the admin login instead of showing a 401 error.',
                        'default' => false,
                        'current' => $this->get('redirect_on_unauthenticated', 'Survey', $event->get('survey')),
                    ],
                ]
            ]);
        }
    }

    public function newSurveySettings()
    {
        $event = $this->event;
        foreach ($event->get('settings') as $name => $value)
        {
            $default = $event->get($name, null, null, isset($this->settings[$name]['default']));
            $this->set($name, $value, 'Survey', $event->get('survey'), $default);
        }
    }

    public function beforeSurveyPage()
    {
        $event = $this->event;
        $id = $event->get('surveyId');
        $flag = $this->get('auth_protection_enabled', 'Survey', $id);

        if ($flag && is_null(Yii::app()->user->getId())) {
            if ($this->get('redirect_on_unauthenticated', 'Survey', $id)) {
                Yii::app()->user->setReturnUrl(Yii::app()->request->requestUri);
                Yii::app()->getController()->redirect(array('/admin/authentication/sa/login'));
            } else {
                throw new CHttpException(401, gT("We are sorry but you do not have permissions to do this."));
            }
        }
    }

    public function getGlobalBasePermissions() {
        $this->getEvent()->append('globalBasePermissions',array(
            'plugin_settings' => array(
                'create' => false,
                'update' => true, // allow only update permission to display
                'delete' => false,
                'import' => false,
                'export' => false,
                'read' => false,
                'title' => gT("Save Plugin Settings"),
                'description' => gT("Allow user to save plugin settings"),
                'img' => 'usergroup'
            ),
        ));
    }
}
