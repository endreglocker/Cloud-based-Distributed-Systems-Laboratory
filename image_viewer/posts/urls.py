from django.urls import path
from . import views

app_name = 'posts'

urlpatterns = [
    path('', views.post_list, name="list"),
    path('new-post/', views.post_new, name="new-post"),
    path('delete/<int:post_id>/', views.post_delete, name='post_delete'),
    path('<slug:slug>', views.post_page, name="page"),
]