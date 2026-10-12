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
| Original specification | OpenAPI 3.0, JSON |
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

None. The specifications are `blog.yaml` (Swagger 2.0) and its conversion to OpenAPI 3.0.1, `blog-openapi.json`, both from RESTgym 1.0.0, with the host and port of the API in EMB (`localhost:30120`). The API has no specification of its own: EMB added one in 2025.

### Integration

- The MySQL database is created when the image is built, and MySQL is started with the shared functions of RESTgym.

## Known issues

- **The database does not match the API.** `database/blogapi.sql` has no `categories` table and no `posts.category_id` column, which the API uses: `GET /api/posts` and `GET /api/categories` always answer 500 (`Unknown column 'post0_.category_id' in 'field list'`). To fix in the integration.
