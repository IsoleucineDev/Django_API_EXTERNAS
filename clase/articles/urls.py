# articles/urls.py
from django.urls import path
from . import views

# ¡ESTA ES LA LÍNEA CRUCIAL!
app_name = 'articles' 

urlpatterns = [
    path('', views.ArticleView.as_view(), name='articles_list'),
    path('all/', views.ArticlesListViews.as_view(), name="all_articles"),
    path('new/', views.NewArticleForm.as_view(), name="new_article"),
    path('<int:pk>/', views.ArticlesDetailView.as_view(), name="article_detail"),
    path('edit/<int:pk>/', views.EditArticleView.as_view(), name="article_edit"),
]