# Image Viewer - Project Documentation

## Project Overview

Image Viewer is a Django-based web application that allows multiple users to upload, view, and manage images. Users can register, login, upload images with automatic title generation, delete their own images, and sort the image gallery by title or upload date.

**Live URL**: https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu

---

## Project Structure

```

image_viewer/                      # Django project root
├── manage.py                      # Django management script
├── static/                        # Project static files
├── media/                         # User-uploaded images
├── image_viewer/                  # Main Django package
│   ├── __init__.py
│   ├── settings.py                # Django settings
│   ├── urls.py                    # Root URL configuration
│   ├── wsgi.py                    # WSGI entry point
│   ├── asgi.py                    # ASGI entry point
│   └── views.py                   # Root views
├── posts/                         # Posts app (images)
│   ├── __init__.py
│   ├── models.py                  # Post model
│   ├── views.py                   # Post views
│   ├── urls.py                    # Post URL patterns
│   ├── forms.py                   # CreatePost form
│   ├── admin.py                   # Django admin config
│   ├── apps.py                    # App configuration
│   ├── tests.py                   # Tests
│   └── migrations/               # Database migrations
└── users/                         # Users app
    ├── __init__.py
    ├── models.py                  # (Empty - uses Django auth)
    ├── views.py                   # Auth views
    ├── urls.py                    # User URL patterns
    ├── admin.py                   # Django admin config
    ├── apps.py                    # App configuration
    ├── tests.py                   # Tests
    └── migrations/                # Database migrations
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Django 5.0.1 |
| Database | PostgreSQL |
| Database URL Parser | dj-database-url |
| Image Processing | Pillow (PIL) |
| Deployment Platform | OKD (OpenShift) |
| Server | WhiteNoise (for static files) |

---

## Database Models

### Post (posts/models.py)

Represents an uploaded image in the system.

| Field | Type | Description |
|-------|------|-------------|
| `id` | AutoField | Primary key (auto-generated) |
| `title` | CharField(max_length=40) | Image title (max 40 characters), auto-generated from filename |
| `slug` | SlugField(unique=True) | URL-friendly identifier, auto-generated from filename + timestamp |
| `date` | DateTimeField(auto_now_add=True) | Upload timestamp, auto-set on creation |
| `banner` | ImageField | Uploaded image file, defaults to 'fallback.png' |
| `author` | ForeignKey(User) | Reference to the user who uploaded the image |

**Methods:**
- `__str__()`: Returns the post title

**Database Table:** `posts_post`

---

## Views

### Posts App (posts/views.py)

#### `post_list(request)`

Displays the list of all images, filtered by user permissions and sorted by user selection.

**URL:** `/`  
**Template:** `posts/posts_list.html`

**Parameters (GET):**
- `sort_by` (str): Sort field - `'title'` or `'date'` (default: `'date'`)
- `order` (str): Sort direction - `'asc'` or `'desc'` (default: `'desc'`)

**Access Control:**
- Anonymous users: See empty list
- Regular users: See only their own posts
- Staff/Superusers: See all posts

**Sorting Logic:**
- By title: Secondary sort by date (descending by default)
- By date: Secondary sort by title (descending by default)

**Context:**
```python
{
    'posts': QuerySet,      # Filtered and ordered posts
    'sort_by': str,         # Current sort field
    'order': str,          # Current sort direction
    'next_order': str,     # Next sort direction (toggle)
}
```

---

#### `post_page(request, slug)`

Displays a single image in detail.

**URL:** `/<slug:slug>/`  
**Template:** `posts/post_page.html`

**Parameters:**
- `slug` (str): The post's unique slug identifier

**Access Control:** Public (no login required)

**Context:**
```python
{
    'post': Post,  # The requested post object
}
```

---

#### `post_delete(request, post_id)`

Deletes a post by ID. Requires POST request for security.

**URL:** `/delete/<int:post_id>/`  
**Redirects to:** `posts:list`

**Parameters:**
- `post_id` (int): The post's primary key

**Access Control:** Requires authentication (`@login_required`)

**Method:** POST only

---

#### `post_new(request)`

Handles new image upload with automatic title and slug generation.

**URL:** `/new-post/`  
**Template:** `posts/post_new.html`

**Access Control:** Requires authentication (`@login_required`, redirect to `/users/login/`)

**Form:** `CreatePost` (from `posts.forms`)

**Automatic Processing:**
1. Title: Extracted from image filename (without extension)
2. Slug: Generated using `slugify(filename-timestamp)`
3. Author: Set to `request.user`

**Context:**
```python
{
    'form': CreatePost,  # The form instance
}
```

**Redirects to:** `posts:list` on success

---

### Users App (users/views.py)

#### `register_view(request)`

Handles user registration with automatic login.

**URL:** `/users/register/`  
**Template:** `users/register.html`

**Form:** `UserCreationForm` (Django built-in)

**Access Control:** Anonymous only (redirects to posts list if already logged in)

**Workflow:**
1. Validates username/password
2. Creates new user
3. Logs user in automatically
4. Redirects to `posts:list`

**Context:**
```python
{
    'form': UserCreationForm,
}
```

---

#### `login_view(request)`

Handles user authentication.

**URL:** `/users/login/`  
**Template:** `users/login.html`

**Form:** `AuthenticationForm` (Django built-in)

**Access Control:** Anonymous only

**Workflow:**
1. Validates credentials
2. Logs user in
3. Redirects to `next` parameter if present, otherwise `posts:list`

**Context:**
```python
{
    'form': AuthenticationForm,
}
```

---

#### `logout_view(request)`

Logs out the current user.

**URL:** `/users/logout/`  
**Method:** POST only

**Access Control:** Authenticated users

**Redirects to:** `posts:list` (anonymous view)

---

## URLs

### Root URL Configuration (image_viewer/urls.py)

| Pattern | Handler | Name |
|---------|---------|------|
| `admin/` | Django Admin | - |
| `` | posts.urls | - |
| `users/` | users.urls | - |
| `^media/(?P<path>.*)$` | static.serve | Media files |
| `^static/(?P<path>.*)$` | static.serve | Static files |

### Posts App URLs (posts/urls.py)

| Pattern | View | Name |
|---------|------|------|
| `` | post_list | list |
| `new-post/` | post_new | new-post |
| `delete/<int:post_id>/` | post_delete | post_delete |
| `<slug:slug>` | post_page | page |

### Users App URLs (users/urls.py)

| Pattern | View | Name |
|---------|------|------|
| `register/` | register_view | register |
| `login/` | login_view | login |
| `logout/` | logout_view | logout |

---

## Forms

### CreatePost (posts/forms.py)

ModelForm for creating new image posts.

**Model:** `Post`  
**Fields:** `banner` (ImageField)

**Field Labels:**
- `banner`: "Image"

**Validation Rules:**

1. **Required:** Image file must be present
2. **MIME Type Validation:** Only accepts:
   - `image/jpeg`
   - `image/png`
   - `image/gif`
   - `image/webp`

3. **Image Verification:** Uses Pillow to verify the file is a valid image
   - Opens image with `PIL.Image.open()`
   - Calls `img.verify()` to check integrity
   - Resets file pointer after verification

4. **Extension Validation:** Only accepts:
   - `.jpg`, `.jpeg`
   - `.png`
   - `.gif`
   - `.webp`

---

## Settings

### Key Configuration (image_viewer/settings.py)

**Database:**
- Engine: `django.db.backends.postgresql`
- Configuration: `dj_database_url` with `DATABASE_URL` environment variable
- Connection timeout: 600 seconds

**Media Files:**
- `MEDIA_URL`: `/media/`
- `MEDIA_ROOT`: `BASE_DIR / 'media'`

**Static Files:**
- `STATIC_URL`: `/static/`
- `STATIC_ROOT`: `BASE_DIR / 'assets'`
- `STATICFILES_DIRS`: `[BASE_DIR / 'static']`

**Security:**
- `CSRF_TRUSTED_ORIGINS`: Production OKD URL
- `ALLOWED_HOSTS`: `["*"]` (all hosts)

---

## Deployment

### OKD (OpenShift) Deployment

The application is deployed on BME's OKD cluster.

**Production URL:**
```
https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu
```

### Static/Media File Serving

The application uses WhiteNoise for serving static files in production:
- Static files are served from `/static/`
- Media files (user uploads) are served from `/media/`

### Database Migrations

To apply migrations in production:
```bash
python manage.py migrate
```

### Collecting Static Files

To collect static files for production:
```bash
python manage.py collectstatic
```

## OC Commands Used to Deploy the Project

### ImageStream and BuildConfig

```bash
oc create imagestream my-app

cat <<EOF | oc apply -f -
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: my-app
  namespace: endre-cloud-based-distributed-systems-laboratory
spec:
  source:
    type: Git
    git:
      uri: 'https://github.com/endreglocker/Cloud-based-Distributed-Systems-Laboratory.git'
      ref: main
    sourceSecret:
      name: git-secret
  strategy:
    type: Docker
    dockerStrategy: {}
  output:
    to:
      kind: ImageStreamTag
      name: 'my-app:latest'
EOF
```

### PostgreSQL Database

```bash
oc new-app postgresql \
  -e POSTGRESQL_USER=django \
  -e POSTGRESQL_PASSWORD=mypassword \
  -e POSTGRESQL_DATABASE=myappdb
```

### Build and Deploy the App

```bash
oc start-build my-app --follow

oc new-app --image-stream=my-app:latest

oc set env deployment/my-app \
  DATABASE_URL=postgres://django:mypassword@postgresql:5432/myappdb

oc set volume deployment/my-app --remove --name=sqlite-data

oc set volume deployment/my-app \
  --add \
  --name=media-data \
  --type=persistentVolumeClaim \
  --claim-size=5Gi \
  --mount-path=/app/media
```

### Network Policy

```bash
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
spec:
  podSelector: {}
  ingress:
  - {}
  policyTypes:
  - Ingress
EOF
```

### Service and Route

```bash
oc expose deployment/my-app --port=8000 --target-port=8000 --name=my-app
oc expose service/my-app
oc patch route my-app -p '{"spec":{"tls":{"termination":"edge"}}}'
oc get route
```