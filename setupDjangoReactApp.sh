#!/bin/bash

#setup Django
pip install Django
django-admin startproject 
echo Enter Django app project name:
read projectName
django-admin startproject ${projectName}
cd ${projectName}

#setup virtual env
pip install virtualenv
virtualenv env
source env/bin/activate

pip install Django
pip install djangorestframework
pip install markdown       # Markdown support for the browsable API.
pip install django-filter  # Filtering support
pip install django-cors-headers

#setup react (I like to organise files this way..feel free to change it)
npm init react-app src
mv src/package.json .
mv src/package-lock.json .
mv src/node_modules .
mv src/public .
mv src/yarn.lock .
cp -rf src/src .

npm run-script build
npm collectstatic

#Django settings file setup
cd ${projectName}
echo "
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'build/static'),
]

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ]
}
CORS_ORIGIN_WHITELIST = (
    'http://localhost:3000',
)

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CSRF_COOKIE_NAME = 'csrftoken'" >> settings.py

sed -i -e "/'DIRS': \[\]/c \\
\        'DIRS': \[os.path.join\(BASE_DIR, 'build'\)\],\\
" settings.py

sed -i -e "/INSTALLED_APPS/a \\
        \    'rest_framework',\\
    " settings.py

sed -i -e "/MIDDLEWARE/a \\
        \    'corsheaders.middleware.CorsMiddleware',\\
    " settings.py

#Django urls file setup
sed -i -e "/from django.contrib import admin/a \\
    from django.views.generic import TemplateView\\
    from django.conf.urls import url\\
" urls.py

sed -i -e "/urlpatterns/a \\
     \    url(r'^react/', TemplateView.as_view(template_name='index.html')),\\
" urls.py

cd ..
python manage.py makemigrations
python manage.py migrate
python manage.py runserver