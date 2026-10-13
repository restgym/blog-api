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
| `specifications/blog.yaml` | The specification given to the tools (Swagger 2.0). |
| `specifications/openapi-original.json` | The original specification (OpenAPI 3.0.0), unchanged. |
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

The API has no specification of its own: EMB added one in 2025. The original specification is `openapi-original.json` (OpenAPI 3.0.0): `jdk_8_maven/cs/rest/original/blogapi/src/main/resources/static/blogapi.json` in EMB (commit `9158590`), unchanged. It already has the host and port of the API in EMB (`http://localhost:30120`). (EMB also has a slightly different copy in `openapi-swagger/blogapi.json`, which is not used.)

- `blog-openapi.json`, given to the tools, is identical to the original (byte for byte).
- `blog.yaml`, given to the tools, is its conversion to Swagger 2.0 (from RESTgym 1.0.0, with the host and port of the API in EMB): the same operations, parameters, request bodies, responses and schemas, in the format of Swagger 2.0.

### Integration

- The MySQL database is created when the image is built, and MySQL is started with the shared functions of RESTgym.

## Endpoints that may interfere with authentication

RESTgym handles the authentication of the requests, and the tools are not aware of it: an endpoint that ends or changes the session of RESTgym (e.g., logout, login as another user, change or deletion of the user of the proxy, of its password or of its roles) may make the tools fail for the rest of the run. Such endpoints may be removed from the specifications given to the tools.

The proxy signs up and signs in once, at the first request, as `userUsername` (password `userPassword`, role user), and adds its JWT to every request; it never signs in again (`auth.py`). The user of the proxy is easy to find for a tool (e.g., `GET /api/users/me` returns it). The endpoints that may end or change its session:

- `DELETE /api/users/{username}`: with `userUsername`, deletes the user of the proxy, whose token then identifies no user.
- `PUT /api/users/{username}`: replaces a user, including its `username` and `password`: with `userUsername`, the token may no longer identify the user.
- `PUT /api/users/{username}/takeAdmin` and `PUT /api/users/{username}/giveAdmin`: change the roles of a user (e.g., of the user of the proxy).

The endpoints to sign up and sign in (`/api/auth/signup`, `/api/auth/signin`) are not in the specification.

## Known issues

- **The database does not match the API.** `database/blogapi.sql` has no `categories` table and no `posts.category_id` column, which the API uses: `GET /api/posts` and `GET /api/categories` always answer 500 (`Unknown column 'post0_.category_id' in 'field list'`). To fix in the integration.
