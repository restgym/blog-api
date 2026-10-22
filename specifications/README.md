# Specifications of Blog API

## Original specification

`original/blog-openapi.json` (OpenAPI 3.0.0, JSON), unchanged.

- **Made by**: written by hand by EMB (WebFuzzing Dataset) developers.
- **Source**: https://github.com/WebFuzzing/Dataset/blob/915859080da033fc36feae54bab3ad4a7b04e872/jdk_8_maven/cs/rest/original/blogapi/src/main/resources/static/blogapi.json

It is not a specification of the authors of the API, which has none: the original repository has no specification and no springfox or springdoc, and the API does not serve one (`blog-sut.jar` contains springdoc-openapi 2.2.0, which does not start with Spring Boot 2.1.8: `/v3/api-docs` answers 404, verified 2026-10). It is the one that EMB added in 2025 (commit `9601752`), kept as the original since it is the only one. So:

- **Server**: `http://localhost:30120`, the port of the API in EMB (RESTgym runs it on 8080).
- **Two operations of the API are missing**: `POST /api/auth/signup` and `POST /api/auth/signin` (the controllers of the API have 54 operations, the specification the other 52). EMB authenticates EvoMaster through its own configuration (`auth/blogapi-auth.yaml`, with `/api/auth/signin`).

## Standardized specification

`standardized/blog-openapi.json`: identical to the original (byte for byte). The other three files are to be provided.

Changes from the original: none.

Kept on purpose (decisions of 2026-10), although they always answer 500 as RESTgym runs the API (see "Known issues" in the README of the API):

- The about 22 operations that fail because the database does not match the code of the API (categories, posts, comments, tags, and the posts of users): they are usable in principle with the configuration of the API, and a bug of the official API (its code and its own database do not match) makes them fail.
- `PUT /api/users/{username}/giveAdmin` and `PUT /api/users/{username}/takeAdmin`: a bug in the code of the API (`UnsupportedOperationException`).

## Corrected specification

`corrected/blog-openapi.json`: the standardized specification (`standardized/blog-openapi.json`), with the change below, which makes the request body of `PUT /api/users/setOrUpdateInfo` match what the API reads. The two files are identical except this change. The other three files are to be provided.

Changes from the standardized specification:

- **Body of `PUT /api/users/setOrUpdateInfo`**: the properties `bs`, `catchPhrase`, `city`, `companyName`, `lat`, `lng`, `phone`, `street`, `suite`, `website` and `zipcode` (all `string`; `maxProperties: 11`) instead of `authorities`, `email`, `firstName`, `id`, `lastName`, `password` and `username` (`maxProperties: 7`).
  - **Why**: the operation reads an `InfoRequest` (`UserController.setAddress`, `@RequestBody InfoRequest`, in the source of the API in EMB), whose fields are these 11, and sets the address and the company of the current user. With the body of the standardized specification (the original), it answers 400 (`city - must not be blank`, `suite - must not be blank`, `street - must not be blank`, `zipcode - must not be blank`); with these fields, 200 (verified at runtime, 2026-10).
  - Written as the other request bodies of this specification: properties in alphabetical order, `maxProperties`, and no `required` list or other constraints (the specification has none for any body). In the code, `street`, `suite`, `city` and `zipcode` are `@NotBlank`.

## Endpoints of the original that may interfere with authentication

The proxy signs up and signs in once, at the first request, as `userUsername` (password `userPassword`), and adds its JWT to every request; it never signs in again (`auth.py`). Since it is the first user of the API (the database has no users), it gets the roles USER **and ADMIN** (`AuthController.registerUser`: `if (userRepository.count() == 0)` adds both); its username is stored in lowercase, `userusername`. The user of the proxy is easy to find for a tool (e.g., `GET /api/users/me` returns it). What the endpoints about users do (verified at runtime, 2026-10, in its RESTgym container, through the proxy):

- `DELETE /api/users/{username}`: could delete the user of the proxy, whose token would then identify no user. Today it cannot: on the user of the proxy it answers 500 (`Unknown column 'posts0_.category_id'`: deleting a user loads its posts, which fails, see "Known issues" in the README of the API), and the user is not deleted; on another user, it answers 403 (`You don't have permission to delete profile of: ...`), also for ADMIN. If the database matched the API, the deletion of the user of the proxy would end its session.
- `PUT /api/users/{username}`: answers 201, but does not change the username (it stays `userusername`); the token of the proxy stays valid (the proxy never signs in again).
- `PUT /api/users/setOrUpdateInfo`: sets the address and the company of the current user (`street`, `suite`, `city`, `zipcode`, ...). The specification describes its body wrongly (`username`, `password`, `authorities`): with that body, it answers 400 for the missing fields of the address. It cannot change the user of the proxy.
- `PUT /api/users/{username}/giveAdmin` and `PUT /api/users/{username}/takeAdmin` (ADMIN only): always answer 500 (`UnsupportedOperationException`, see "Known issues" in the README of the API): they cannot change the roles of a user.
- `POST /api/users` (ADMIN only): creates other users (201), and does not end the session of the proxy.

So, today, no endpoint ends or changes the session of the proxy. The endpoints to sign up and sign in (`/api/auth/signup`, `/api/auth/signin`) are not in the specification.
