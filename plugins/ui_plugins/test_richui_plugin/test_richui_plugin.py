# This is the class you derive to create a plugin
from airflow.plugins_manager import AirflowPlugin
import airflow
from airflow.configuration import get_airflow_home
from flask import Blueprint
from flask_admin import BaseView, expose
try:
    from flask_appbuilder import BaseView as AppBuilderBaseView, expose as AppBuilderExpose
except:
    pass
from flask_admin.base import MenuLink

# Importing base classes that we need to derive
from airflow.models import BaseOperator
from airflow.models.baseoperator import BaseOperatorLink
from airflow.utils.db import provide_session
from functools import wraps



def login_required(func):
# when airflow loads plugins, login is still None.
    @wraps(func)
    def func_wrapper(*args, **kwargs):
        if airflow.login:
            return airflow.login.login_required(func)(*args, **kwargs)
        return func(*args, **kwargs)
    return func_wrapper
    
    

# Creating a flask admin BaseView
class TestRichView(BaseView):
    @expose('/')
    @login_required
    @provide_session
    def index(self, session=None):
        # in this example, put your test_rich_ui/test.html template at airflow/plugins/templates/test_rich_ui/test.html
        return self.render("index.html")

v = TestRichView(category="UI Plugins", name="Rich UI Plugin")


# Creating a flask admin BaseView
class TestRichAppBuilderView(AppBuilderBaseView):
    template_folder = '{}/plugins/ui_plugins/test_richui_plugin/templates'.format(get_airflow_home())
    @AppBuilderExpose('/')
    @login_required
    @provide_session
    def list(self, session=None):
        # in this example, put your test_rich_ui/test.html template at airflow/plugins/templates/test_rich_ui/test.html
        return self.render_template("index.html")

v_appbuilder_view = TestRichAppBuilderView()
v_appbuilder_package = {"name": "Rich UI Plugin",
                        "category": "UI Plugins",
                        "view": v_appbuilder_view}

# Creating a flask blueprint to integrate the templates and static folder
bp = Blueprint(
    "test_rich_ui", __name__,
    template_folder='test_richui_plugin/templates', # registers airflow/plugins/thisplugin/templates as a Jinja template folder
    static_folder='static',
    static_url_path='/static/test_rich_ui')

# A global operator extra link that redirect you to
# task logs stored in S3
class GoogleLink(BaseOperatorLink):
    name = "Google"
    def get_link(self, operator, dttm):
        return "https://www.google.com"


# Defining the plugin class
class AirflowTestPlugin(AirflowPlugin):
    name = "test_rich_ui"
    admin_views = [v]
    appbuilder_views = [v_appbuilder_package]
    flask_blueprints = [bp]
    global_operator_extra_links = [GoogleLink(),]