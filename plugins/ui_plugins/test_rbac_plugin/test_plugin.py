from airflow.plugins_manager import AirflowPlugin
from airflow.configuration import get_airflow_home
from flask import Blueprint
from flask_admin import BaseView, expose
from flask_admin.base import MenuLink

# Importing base classes that we need to derive
from airflow.hooks.base_hook import BaseHook
from airflow.models import BaseOperator
from airflow.sensors.base_sensor_operator import BaseSensorOperator
from airflow.executors.base_executor import BaseExecutor
from flask_appbuilder import BaseView as AppBuilderBaseView, expose as AppBuilderExpose

# Will show up under airflow.hooks.test_plugin.PluginHook
class PluginHook(BaseHook):
    pass

# Will show up under airflow.operators.test_plugin.PluginOperator
class PluginOperator(BaseOperator):
    pass

# Will show up under airflow.sensors.test_plugin.PluginSensorOperator
class PluginSensorOperator(BaseSensorOperator):
    pass

# Will show up under airflow.executors.test_plugin.PluginExecutor
class PluginExecutor(BaseExecutor):
    pass

# Will show up under airflow.macros.test_plugin.plugin_macro
def plugin_macro():
    pass

# Creating a flask admin BaseView
class TestView(BaseView):
    @expose('/')
    def test(self):
        # in this example, put your test_plugin/test.html template at airflow/plugins/templates/test_plugin/test.html
        return self.render("test.html", content="Hello galaxy!")
v = TestView(category="UI Plugins", name="Simple HTML")

# Creating a flask blueprint to integrate the templates and static folder
bp = Blueprint(
    "test_plugin", __name__,
    template_folder='test_rbac_plugin/templates', # registers airflow/plugins/templates as a Jinja template folder
    static_folder='static',
    static_url_path='/static/test_plugin')

ml = MenuLink(
    category='UI Plugins',
    name='Test Menu Link',
    url='https://airflow.incubator.apache.org/')

# Creating a flask appbuilder BaseView
class TestRbacBaseView(AppBuilderBaseView):
    template_folder = '{}/plugins/ui_plugins/test_rbac_plugin/templates'.format(get_airflow_home())
    @AppBuilderExpose("/")
    def list(self):
        return self.render_template("test.html", content="Hello galaxy!")

    @AppBuilderExpose("/2")
    def list_2(self):
        return self.render_template("test.html", content="Hello galaxy 2!")

v_appbuilder_view = TestRbacBaseView()
v_appbuilder_package = {"name": "Simple HTML",
                        "category": "UI Plugins",
                        "view": v_appbuilder_view}

# Creating a flask appbuilder Menu Item
appbuilder_mitem = {"name": "Google",
                    "category": "Search",
                    "category_icon": "fa-plug",
                    "icon": "fa-plug",
                    "href": "https://www.google.com"}
                    

# Defining the plugin class
class AirflowTestPlugin(AirflowPlugin):
    name = "test_plugin"
    operators = [PluginOperator]
    sensors = [PluginSensorOperator]
    hooks = [PluginHook]
    executors = [PluginExecutor]
    macros = [plugin_macro]
    # admin_views = [v]
    # flask_blueprints = [bp]
    menu_links = [ml]
    appbuilder_views = [v_appbuilder_package]
    appbuilder_menu_items = [appbuilder_mitem]