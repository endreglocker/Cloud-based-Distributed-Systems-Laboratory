"""
Locust testing file for Image-Gallery App.
Testcases: register, login, browse gallery, sort, view image, upload image, delete image, logout.

Run locally:
    locust -f locustfile.py --host https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu

Run headless (CI / OKD pod):
    locust -f locustfile.py
        --host https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu \
        --headless -u 50 -r 5 --run-time 3m \
        --csv=results/locust
"""

import io
import re
import random
import string

from locust import HttpUser, SequentialTaskSet, between, task
from PIL import Image

def _random_suffix(n=8) -> str:
    '''
    Add random suffix for the test user / test image
    '''
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=n))


def _make_png_bytes() -> bytes:
    """
    Generate a valid PNG image in memory with Pillow
    """
    img = Image.new("RGB", (64, 64), color=(
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255),
    ))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return buf.read()


def _get_csrf(client, url: str) -> str:
    """GET a page and return the csrfmiddlewaretoken hidden field value."""
    resp = client.get(url)
    # Django sets csrftoken cookie on every response
    return client.cookies.get("csrftoken", "")

class ImageViewerTasks(SequentialTaskSet):
    """
    register --> login --> gallery (browse + sort) --> upload --> view --> delete --> logout
    """

    username: str = ""
    password: str = ""
    # Maps post_id -> True for posts uploaded by this virtual user.
    # Scraped from /delete/<id>/ links, which Django only renders for the post's author.
    own_post_ids: list = []

    def on_start(self):
        '''
        Creates pseudo user credentials
        '''
        self.username = "testuser_" + _random_suffix()
        self.password = "Passw0rd!" + _random_suffix(4)
        self.own_post_ids = []

    @task
    def register(self):
        '''
        Register the pseudo user
        '''
        csrf = _get_csrf(self.client, "/users/register/")
        with self.client.post(
            "/users/register/",
            data={
                "username": self.username,
                "password1": self.password,
                "password2": self.password,
                "csrfmiddlewaretoken": csrf,
            },
            headers={"Referer": self.client.base_url + "/users/register/"},
            name="/users/register/ [POST]",
            allow_redirects=True,
            catch_response=True,
        ) as resp:
            if resp.status_code not in (200, 302):
                resp.failure(f"Register failed: {resp.status_code}")

    @task
    def login(self):
        '''
        Test pseudo user login
        '''
        # First logout to avoid "stuck" / halted accounts when we retry the test
        csrf_logout = _get_csrf(self.client, "/")
        self.client.post(
            "/users/logout/",
            data={"csrfmiddlewaretoken": csrf_logout},
            headers={"Referer": self.client.base_url + "/"},
            name="/users/logout/ [POST]",
            allow_redirects=True,
        )

        csrf = _get_csrf(self.client, "/users/login/")
        with self.client.post(
            "/users/login/",
            data={
                "username": self.username,
                "password": self.password,
                "csrfmiddlewaretoken": csrf,
            },
            headers={"Referer": self.client.base_url + "/users/login/"},
            name="/users/login/ [POST]",
            allow_redirects=True,
            catch_response=True,
        ) as resp:
            if resp.status_code not in (200, 302):
                resp.failure(f"Login failed: {resp.status_code}")

    @task
    def browse_gallery_default(self):
        '''
        GET / == gallery
        '''
        self.client.get("/", name="/ [gallery default]")

    @task
    def sort_by_title_asc(self):
        '''
        Test alphabetic sorting
        '''
        self.client.get("/?sort_by=title&order=asc", name="/ [sort title asc]")

    @task
    def sort_by_date_desc(self):
        '''
        Test date-based sorting
        '''
        self.client.get("/?sort_by=date&order=desc", name="/ [sort date desc]")

    @task
    def upload_image(self):
        '''
        Upload the Pillow generated image
        '''
        csrf = _get_csrf(self.client, "/new-post/")
        png_bytes = _make_png_bytes()
        filename = f"test_image_{_random_suffix()}.png"

        with self.client.post(
            "/new-post/",
            files={"banner": (filename, png_bytes, "image/png")},
            data={"csrfmiddlewaretoken": csrf},
            headers={"Referer": self.client.base_url + "/new-post/"},
            name="/new-post/ [POST upload]",
            allow_redirects=True,
            catch_response=True,
        ) as resp:
            if resp.status_code not in (200, 302):
                resp.failure(f"Upload failed: {resp.status_code}")
                return

        # Refresh own post IDs after upload
        self._refresh_own_post_ids()

    @task
    def view_image(self):
        '''
        View the uploaded image
        '''
        if not self.own_post_ids:
            self._refresh_own_post_ids()
        if not self.own_post_ids:
            return  # nothing uploaded yet

        # Visit the gallery to get a slug for one of our own posts
        gallery = self.client.get("/", name="/ [pre-view gallery]")
        slugs = re.findall(r'href="/([a-z0-9]+(?:-[a-z0-9]+)+)"', gallery.text)
        skip = {"users", "new-post", "admin", "static", "media"}
        slugs = [s for s in slugs if s not in skip]
        if slugs:
            slug = random.choice(slugs)
            self.client.get(f"/{slug}", name="/<slug> [image detail]", allow_redirects=True)

    @task
    def delete_image(self):
        '''
        Delete the uploaded image.
        Posts directly to /delete/<id>/ — no JS confirm dialog needed
        because Locust does not execute JavaScript.
        '''
        if not self.own_post_ids:
            self._refresh_own_post_ids()
        if not self.own_post_ids:
            return

        post_id = self.own_post_ids.pop()
        csrf = self.client.cookies.get("csrftoken", "")
        self.client.post(
            f"/delete/{post_id}/",
            data={"csrfmiddlewaretoken": csrf},
            headers={"Referer": self.client.base_url + "/"},
            name="/delete/<id>/ [POST]",
            allow_redirects=True,
        )

    @task
    def logout(self):
        '''
        Logout user
        '''
        csrf = self.client.cookies.get("csrftoken", "")
        self.client.post(
            "/users/logout/",
            data={"csrfmiddlewaretoken": csrf},
            headers={"Referer": self.client.base_url + "/"},
            name="/users/logout/ [POST final]",
            allow_redirects=True,
        )
        # Reset for next iteration
        self.own_post_ids = []

    def _refresh_own_post_ids(self):
        """
        Scrape /delete/<id>/ links from the gallery.
        Django only renders these links for the logged-in user's own posts,
        so this reliably returns only IDs we are allowed to delete.
        """
        gallery = self.client.get("/", name="/ [id refresh]")
        self.own_post_ids = re.findall(r'/delete/(\d+)/', gallery.text)


class ImageViewerUser(HttpUser):
    """
    Simulated user of the Image Viewer app.
    wait_time: realistic think time between tasks.
    """
    tasks = [ImageViewerTasks]
    wait_time = between(1, 3)

    # Disable SSL verification for the self-signed OKD cert
    # (remove if you have a valid cert)
    def on_start(self):
        self.client.verify = False