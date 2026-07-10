# API Patterns

Minimal API patterns using `Api/` folder with route group definition and separate endpoint files.

## File Structure

```
Api/
├── {ServiceName}Api.cs        # Route group definition, shared middleware
├── GetAllEndpoint.cs
├── GetByIdEndpoint.cs
├── CreateEndpoint.cs
├── UpdateEndpoint.cs
└── DeleteEndpoint.cs
```

> **Error handling**: Unhandled exceptions flow to the centralized exception-handling middleware, which maps them to ProblemDetails responses. Endpoints catch only expected, actionable exceptions (e.g., `ValidationException` → 400) — never `catch (Exception)`.

## Api/{ServiceName}Api.cs

Route group definition and endpoint registration:

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

public static class {ServiceName}Api
{
    public static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/{service-kebab}")
           .WithTags("{ServiceName}")
           .MapGetAll()
           .MapGetById()
           .MapCreate()
           .MapUpdate()
           .MapDelete();

        return app;
    }
}
```

## Api/GetAllEndpoint.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;

public static class GetAllEndpoint
{
    public static RouteGroupBuilder MapGetAll(this RouteGroupBuilder group)
    {
        group.MapGet("/", async (
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.GetAllAsync(cancellationToken);
            return Results.Ok(result);
        })
        .WithName("GetAll{ServiceName}")
        .Produces<IEnumerable<Response>>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/GetByIdEndpoint.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;

public static class GetByIdEndpoint
{
    public static RouteGroupBuilder MapGetById(this RouteGroupBuilder group)
    {
        group.MapGet("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.GetByIdAsync(id, cancellationToken);
            return result is null 
                ? Results.NotFound() 
                : Results.Ok(result);
        })
        .WithName("Get{ServiceName}ById")
        .Produces<Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/CreateEndpoint.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Requests;
using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;
using {Organization}.{Product}.Services.{ServiceName}.Exceptions;

public static class CreateEndpoint
{
    public static RouteGroupBuilder MapCreate(this RouteGroupBuilder group)
    {
        group.MapPost("/", async (
            [FromBody] CreateRequest request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.CreateAsync(request, cancellationToken);
                return Results.Created($"/api/{service-kebab}/{result.Id}", result);
            }
            catch (ValidationException e)
            {
                return Results.BadRequest(e.Message);
            }
        })
        .WithName("Create{ServiceName}")
        .Produces<Response>(StatusCodes.Status201Created)
        .Produces(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/UpdateEndpoint.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Requests;
using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;
using {Organization}.{Product}.Services.{ServiceName}.Exceptions;

public static class UpdateEndpoint
{
    public static RouteGroupBuilder MapUpdate(this RouteGroupBuilder group)
    {
        group.MapPut("/{id:guid}", async (
            Guid id,
            [FromBody] UpdateRequest request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.UpdateAsync(id, request, cancellationToken);
                return result is null 
                    ? Results.NotFound() 
                    : Results.Ok(result);
            }
            catch (ValidationException e)
            {
                return Results.BadRequest(e.Message);
            }
        })
        .WithName("Update{ServiceName}")
        .Produces<Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .Produces(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/DeleteEndpoint.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Contracts;

public static class DeleteEndpoint
{
    public static RouteGroupBuilder MapDelete(this RouteGroupBuilder group)
    {
        group.MapDelete("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var success = await service.DeleteAsync(id, cancellationToken);
            return success 
                ? Results.NoContent() 
                : Results.NotFound();
        })
        .WithName("Delete{ServiceName}")
        .Produces(StatusCodes.Status204NoContent)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Registration in Program.cs

```csharp
app.Map{ServiceName}Api();
```

## HTTP Test Files

When API endpoints are created, generate a corresponding `.http` test file under `/tests`. Files follow the same hierarchy as the code:

| Level | File path | Scope |
|-------|-----------|-------|
| Service | `tests/{ServiceName}.http` | Tests for one service's endpoints |
| Component | `tests/{ComponentName}.http` | Cross-service tests within a component |
| Module | `tests/{ModuleName}.http` | Cross-component tests within a module |
| App | `tests/App.http` | Cross-module or global tests |

Example `tests/{ServiceName}.http`:

```http
@baseUrl = https://localhost:5001
@contentType = application/json

###
# Get all {ServiceName} items
# @name GetAll
GET {{baseUrl}}/api/{service-kebab}
Accept: {{contentType}}

###
# Get a specific {ServiceName} by ID
# @name GetById
GET {{baseUrl}}/api/{service-kebab}/{{id}}
Accept: {{contentType}}

###
# Create a new {ServiceName}
# @name Create
POST {{baseUrl}}/api/{service-kebab}
Content-Type: {{contentType}}

{
  "id": "sample-id",
  "data": "sample-data"
}

###
# Update an existing {ServiceName}
# @name Update
PUT {{baseUrl}}/api/{service-kebab}/{{id}}
Content-Type: {{contentType}}

{
  "data": "updated-data"
}

###
# Delete a {ServiceName}
# @name Delete
DELETE {{baseUrl}}/api/{service-kebab}/{{id}}
```

## Single Action Pattern

For services with one primary action, use the same folder structure with fewer endpoints:

```
Api/
├── Api.cs
└── ExecuteEndpoint.cs
```

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

public static class {ServiceName}Api
{
    public static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/{service-kebab}")
           .WithTags("{ServiceName}")
           .MapExecute();

        return app;
    }
}
```

```csharp
namespace {Organization}.{Product}.Services.{ServiceName}.Api;

using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Requests;
using {Organization}.{Product}.Services.{ServiceName}.Abstractions.Responses;
using {Organization}.{Product}.Services.{ServiceName}.Contracts;

public static class ExecuteEndpoint
{
    public static RouteGroupBuilder MapExecute(this RouteGroupBuilder group)
    {
        group.MapPost("/execute", async (
            [FromBody] ExecuteRequest request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.ExecuteAsync(request, cancellationToken);
            return Results.Ok(result);
        });

        return group;
    }
}
```
