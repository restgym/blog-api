# Blog API for RESTgym

This repository is the RESTgym integration of Blog API. It is meant to be used as a Git submodule of [RESTgym](https://github.com/restgym/restgym) (in `apis/blog/`), which builds its Docker image and runs it with the testing tools: it does not work on its own.

## The API

| | |
|---|---|
| Name | Blog API |
| Version | 0.0.1-SNAPSHOT |
| Description | Restful CRUD blog API (posts, comments, albums, photos, todos and users), secured with JWT. |
| Domain | Content management |
| License | AGPL-3.0 |
| Original repository | https://github.com/osopromadze/Spring-Boot-Blog-REST-API, through the [WebFuzzing Dataset (EMB)](https://github.com/WebFuzzing/Dataset) |
| Technology | Java 11, Spring Boot 2.1.8, MySQL |
| Original specification | OpenAPI 3.0.0, JSON, written by the developers of the [WebFuzzing Dataset (EMB)](https://github.com/WebFuzzing/Dataset) in 2025 (the API has none) |
| Operations tested | 52 |
| Authentication | Required: the proxy of RESTgym authenticates the requests of the tools (`auth.py`) |
| External services | None |

More details (e.g., how 5XX responses are grouped into unique failures) are in the manifest, `restgym-api-manifest.yaml`.

## Contents

| File | Content |
|---|---|
| `blog-sut.jar` | The executable of the API in the [WebFuzzing Dataset (EMB)](https://github.com/WebFuzzing/Dataset), as packaged in RESTgym 1.0.0 (the same file as in the pre-built image `restgym/blog-api:1.0.0`). |
| `classes/` | The classes measured for code coverage: the classes of the packages of the API, as in the executable. |
| `specifications/blog-openapi.json` | The specification given to the tools (OpenAPI 3.0.0). |
| `specifications/blog-openapi.yaml` | The specification given to the tools (OpenAPI 3, YAML): not provided yet, the file contains only `TO BE PROVIDED`. |
| `specifications/blog-swagger.json` | The specification given to the tools (Swagger 2.0, JSON): not provided yet, the file contains only `TO BE PROVIDED`. |
| `specifications/blog-swagger.yaml` | The specification given to the tools (Swagger 2.0). |
| `specifications/original/blog-openapi.json` | The original specification (OpenAPI 3.0.0), unchanged. |
| `database/` | `database/blogapi.sql`: the schema and data of the API, loaded into MySQL when the image is built (`init-mysql.sh`). |
| `Dockerfile` | The Docker image of the API, built by RESTgym (`./restgym.sh b`). |
| `entrypoint.sh` | Starts the API (and the services it needs) in the container. |
| `init-mysql.sh` | Creates the MySQL database when the image is built. |
| `auth.py` | Script of the proxy of RESTgym, which authenticates the requests of the tools. |
| `restgym-api-manifest.yaml` | Metadata of the API for RESTgym. |

## How RESTgym runs it

The image starts from the base image of RESTgym for Java 11 (`restgym/api-base:java11`), which contains the proxy and the collection of code coverage. MySQL runs in the container, with the database created when the image is built. The proxy authenticates the requests of the tools (`auth.py`): it signs up a user, signs in, and adds the JWT to every request. The tools reach the API through the proxy of RESTgym, on port 9090.

## Changes made by RESTgym

### API

None by RESTgym: the executable is the version of the API in the [WebFuzzing Dataset (EMB)](https://github.com/WebFuzzing/Dataset), unchanged. EMB packages each API as a system under test, and may adapt it to run on its own (e.g., with an embedded database): see EMB for its changes to the original repository.

### Specification

The API has no specification of its own: EMB added one in 2025. The original specification is `original/blog-openapi.json` (OpenAPI 3.0.0): `jdk_8_maven/cs/rest/original/blogapi/src/main/resources/static/blogapi.json` in EMB (commit `9158590`), unchanged. It already has the host and port of the API in EMB (`http://localhost:30120`). (EMB also has a slightly different copy in `openapi-swagger/blogapi.json`, which is not used.)

- `blog-openapi.json`, given to the tools, is identical to the original (byte for byte).
- `blog-swagger.yaml`, given to the tools, is its conversion to Swagger 2.0 (from RESTgym 1.0.0, with the host and port of the API in EMB): the same operations, parameters, request bodies, responses and schemas, in the format of Swagger 2.0.

### Integration

- The MySQL database is created when the image is built, and MySQL is started with the shared functions of RESTgym.

## Endpoints that may interfere with authentication

RESTgym handles the authentication of the requests, and the tools are not aware of it: an endpoint that ends or changes the session of RESTgym (e.g., logout, login as another user, change or deletion of the user of the proxy, of its password or of its roles) may make the tools fail for the rest of the run. The proxy blocks the requests that would end its session (`471 Blocked by RESTgym`), instead of removing the endpoints from the specifications given to the tools.

The proxy signs up and signs in once, at the first request, as `userUsername` (password `userPassword`), and adds its JWT to every request; it never signs in again (`auth.py`). Since it is the first user of the API (the database has no users), it gets the roles USER **and ADMIN** (`AuthController.registerUser`: `if (userRepository.count() == 0)` adds both); its username is stored in lowercase, `userusername`. The user of the proxy is easy to find for a tool (e.g., `GET /api/users/me` returns it). What the endpoints about users do (verified at runtime, 2026-10, in its RESTgym container, through the proxy):

- `DELETE /api/users/{username}`: could delete the user of the proxy, whose token would then identify no user. Today it cannot: on the user of the proxy it answers 500 (`Unknown column 'posts0_.category_id'`: deleting a user loads its posts, which fails, see "Known issues"), and the user is not deleted; on another user, it answers 403 (`You don't have permission to delete profile of: ...`), also for ADMIN. If the database matched the API, the deletion of the user of the proxy would end its session.
- `PUT /api/users/{username}`: answers 201, but does not change the username (it stays `userusername`); the token of the proxy stays valid (the proxy never signs in again).
- `PUT /api/users/setOrUpdateInfo`: sets the address and the company of the current user (`street`, `suite`, `city`, `zipcode`, ...). The specification describes its body wrongly (`username`, `password`, `authorities`): with that body, it answers 400 for the missing fields of the address. It cannot change the user of the proxy.
- `PUT /api/users/{username}/giveAdmin` and `PUT /api/users/{username}/takeAdmin` (ADMIN only): always answer 500 (`UnsupportedOperationException`, see "Known issues"): they cannot change the roles of a user.
- `POST /api/users` (ADMIN only): creates other users (201), and does not end the session of the proxy.

So, today, no endpoint ends or changes the session of the proxy. The endpoints to sign up and sign in (`/api/auth/signup`, `/api/auth/signin`) are not in the specification.

## Known issues

- **The database does not match the code of the API: about 22 operations always answer 500** (kept: bug of the official API). The code has categories (`model/Category.java`, `CategoryController`, and `Post` refers to a category, `posts.category_id`), but the official database has no `categories` table and no `posts.category_id` column, and Hibernate creates nothing (`ddl-auto: none` in `application.yml`). The database of RESTgym is the official one: `database/blogapi.sql` has the same content as `data/blogapi.sql` of the original repository (and of EMB, byte for byte), without its first line `USE blogapi;` (`init-mysql.sh` creates and selects the database) and its final newline; the other schema of the original repository (`src/main/resources/blogapi.sql`), and the `blogapi.sql` and `schema.sql` in `blog-sut.jar` (which Spring runs at startup, `spring.datasource.initialization-mode=always`), have no categories either, and EMB runs the API with the same schema. Checked 2026-10. Everything that touches categories, posts, or the posts of tags and users fails with SQL errors (`Table 'blogapi.categories' doesn't exist`, `Unknown column 'post0_.category_id' in 'field list'`), verified at runtime (2026-10):
  - categories: `POST /api/categories`, `GET /api/categories`, `GET`, `PUT` and `DELETE /api/categories/{id}` (5);
  - posts: `GET /api/posts`, `GET`, `PUT` and `DELETE /api/posts/{id}`, `GET /api/posts/category/{id}`, `GET /api/posts/tag/{id}`, and `POST /api/posts` (it writes `category_id`; not confirmed: the request tried was rejected first, 400, for a short body) (7);
  - comments: `POST /api/posts/{postId}/comments`, `GET`, `PUT` and `DELETE /api/posts/{postId}/comments/{id}` (4; `GET /api/posts/{postId}/comments` works);
  - tags: `GET /api/tags`, `GET`, `PUT` and `DELETE /api/tags/{id}` (4; loading a tag loads its posts; `POST /api/tags` works);
  - users: `GET /api/users/{username}/posts`, and `DELETE /api/users/{username}` on the user of the proxy (2).
- **`PUT /api/users/{username}/giveAdmin` and `PUT /api/users/{username}/takeAdmin` always answer 500** (kept: bug of the API): `java.lang.UnsupportedOperationException`, whatever the user, verified at runtime (2026-10). In the code, `User.setRoles` stores the roles as `Collections.unmodifiableList(roles)`, which Hibernate cannot update when it saves the user (`UserServiceImpl.giveAdmin` and `removeAdmin`).
- **`GET /api/albums` and `PUT /api/albums/{id}` can answer 500** (kept: bug of the API): `HttpMessageConversionException: Type definition error: [simple type, class org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor]` (a lazy Hibernate proxy that Jackson cannot serialize), with an album in the database (2026-10). It depends on the data.
- **`DELETE /api/users/{username}` answers 403 for any other user, also for ADMIN** (`You don't have permission to delete profile of: ...`), and `PUT /api/users/{username}` does not change the username (behavior of the API, kept).
- **The specification describes the body of `PUT /api/users/setOrUpdateInfo` wrongly**: `username`, `password` and `authorities`, while the API reads the address and the company of the user (`street`, `suite`, `city`, `zipcode`, `companyName`, `catchPhrase`, `bs`, `website`, `phone`, `lat`, `lng`; `InfoRequest`), and answers 400 for the missing fields of the address with the body of the specification.
