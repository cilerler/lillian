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

> **Error handling**: Unhandled exceptions flow to the centralized exception-handling middleware, which maps them to ProblemDetails responses. Endpoints catch only expected, actionable exceptions (for example, `{ServiceName}ValidationException` maps to validation ProblemDetails with HTTP 400) — never `catch (Exception)`.

When CRUD API exposure is selected, generate `Create{ServiceName}Request` and
`Update{ServiceName}Request` at the selected request-contract boundary, use the response contract from its
selected response-contract boundary, and replace the neutral `I{ServiceName}.DoWorkAsync` placeholder with
the operations used by these endpoints:

The `GetAll` variant below is allowed only when the domain collection has a small, enforced upper bound.
For an unbounded collection, select the application's canonical cursor/page contract during discovery and
generate `GetPageAsync` plus bounded query parameters instead; do not copy the unbounded operation.

Merge these imports into the existing `I{ServiceName}.cs` at the selected service-contract boundary.
`Contracts/I{ServiceName}.cs` is only the default service-internal path; do not create or update a second
copy there after the interface has moved to an `Abstractions/Interfaces` boundary.

```csharp
using System;
using System.Collections.Generic;
using {RequestContractNamespace};
using {ResponseContractNamespace};
```

```csharp
Task<IReadOnlyList<{ServiceName}Response>> GetAllAsync(CancellationToken cancellationToken);
Task<{ServiceName}Response?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
Task<{ServiceName}Response> CreateAsync(Create{ServiceName}Request request, CancellationToken cancellationToken);
Task<{ServiceName}Response?> UpdateAsync(Guid id, Update{ServiceName}Request request, CancellationToken cancellationToken);
Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken);
```

The corresponding request contracts are service-named so multiple capabilities can share one abstractions
project without type collisions. Place each file under the selected producer boundary's `Requests/` role
folder. `Abstractions/Requests/` beneath `{ServiceRoot}` is only the default service-boundary path; when
`{RequestContractNamespace}` resolves elsewhere, move the file and namespace together.

### Requests/Create{ServiceName}Request.cs at the selected request-contract boundary

```csharp
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Create{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

### Requests/Update{ServiceName}Request.cs at the selected request-contract boundary

```csharp
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Update{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

Public request/response members keep explicit `JsonPropertyName` values so CLR refactoring cannot silently
change the wire contract.

## {ServiceName}Service.cs additions

Implement every selected API operation on `{ServiceName}Service` with the exact interface signatures above.
The service owns input validation, mapping, persistence/external dependency calls, and domain exception
classification; endpoint files only bind HTTP input, invoke the service, and map expected outcomes. Generate
the concrete implementation from the confirmed domain behavior and selected dependencies. If that behavior is
not known, stop and ask—do not emit `NotImplementedException`, `default`, an in-memory fake, or business logic
inside an endpoint merely to make the scaffold compile.

## Api/{ServiceName}Api.cs

Route group definition and endpoint registration:

```csharp
namespace {ServiceNamespace}.Api;

using Microsoft.AspNetCore.Builder;

internal static class {ServiceName}Api
{
    internal static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/v1/{ServiceKebabName}")
           .WithTags("{ServiceName}")
           .WithOpenApi()
           .MapGetAll()
           .MapGetById()
           .MapCreate()
           .MapUpdate()
           .MapDelete();

        return app;
    }
}
```

`Map{ServiceName}Api` is assembly-internal so Host cannot bypass the owning service's feature and DI gate.
Only `Extensions/StartupExtensions.Map{ServiceName}` calls this low-level mapper.

## Api/GetAllEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ResponseContractNamespace};
using {ServiceContractNamespace};

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
        .Produces<IReadOnlyList<{ServiceName}Response>>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/GetByIdEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ResponseContractNamespace};
using {ServiceContractNamespace};

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
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/CreateEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public static class CreateEndpoint
{
    public static RouteGroupBuilder MapCreate(this RouteGroupBuilder group)
    {
        group.MapPost("/", async (
            [FromBody] Create{ServiceName}Request request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.CreateAsync(request, cancellationToken);
                return Results.Created($"/api/v1/{ServiceKebabName}/{result.Id}", result);
            }
            catch ({ServiceName}ValidationException e)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["request"] = [.. e.Errors]
                });
            }
        })
        .WithName("Create{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status201Created)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/UpdateEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Collections.Generic;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};
using {ServiceNamespace}.Exceptions;

public static class UpdateEndpoint
{
    public static RouteGroupBuilder MapUpdate(this RouteGroupBuilder group)
    {
        group.MapPut("/{id:guid}", async (
            Guid id,
            [FromBody] Update{ServiceName}Request request,
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
            catch ({ServiceName}ValidationException e)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["request"] = [.. e.Errors]
                });
            }
        })
        .WithName("Update{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Api/DeleteEndpoint.cs

```csharp
namespace {ServiceNamespace}.Api;

using System;
using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {ServiceContractNamespace};

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

## Serialization/{ServiceName}JsonSerializerContext.cs

API DTOs use System.Text.Json source generation. This is the HTTP adapter's service-owned context: it always
stays at `{ServiceRoot}/Serialization/{ServiceName}JsonSerializerContext.cs` with namespace
`{ServiceNamespace}.Serialization`, even when one or more DTO declarations move to a broader contract
boundary. Import the resolved contract namespaces; never copy the DTOs back into the service merely to keep
this context local.

The file below is the CRUD branch. Include every concrete request, response, collection, and event type that
the selected API serializes; do not rely on reflection fallback or retain types from an unselected branch.
This adapter context does not replace a reusable producer-owned context required by the selected contract
boundary or another transport. Such a contract-owned context stays beside its contracts at that producer
boundary and moves, with its namespace and project references, whenever those contracts move.

```csharp
namespace {ServiceNamespace}.Serialization;

using System.Collections.Generic;
using System.Text.Json.Serialization;
using {RequestContractNamespace};
using {ResponseContractNamespace};

[JsonSerializable(typeof(Create{ServiceName}Request))]
[JsonSerializable(typeof(Update{ServiceName}Request))]
[JsonSerializable(typeof({ServiceName}Response))]
[JsonSerializable(typeof(IReadOnlyList<{ServiceName}Response>))]
[JsonSerializable(typeof(List<{ServiceName}Response>))]
internal partial class {ServiceName}JsonSerializerContext : JsonSerializerContext
{
}
```

When API exposure is selected, add this registration to `Add{ServiceName}`:

```csharp
// StartupExtensions.cs import
using {ServiceNamespace}.Serialization;

// Inside Add{ServiceName}
services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.TypeInfoResolverChain.Insert(
        0,
        {ServiceName}JsonSerializerContext.Default));
```

## Registration in Program.cs

```csharp
// `capabilities` is the strongly typed Host composition snapshot bound in Program.cs.
builder.Services.AddConfiguredCapabilities(capabilities);

var app = builder.Build();

app.MapConfiguredEndpoints();
```

Use the matching registration and mapping cascade from
[`modular-polylith.md`](modular-polylith.md#registration-chain). For a modular service, Host traverses
Host → Module → Component → `Map{ServiceName}`. For a standalone service, Host traverses Host →
`Map{ServiceName}` directly. Program calls only the Host-owned cascade; it never calls either service mapper.
The public service wrapper receives the captured route decision from that cascade and maps only after
confirming `I{ServiceName}` is registered. It never re-reads live configuration. The low-level
`Map{ServiceName}Api` method remains service-owned and internal.

## HTTP Test Files

When API endpoints are created, generate their `.http` test file at the complete `{TestTarget}.http` path
resolved from [`Canonical test project and HTTP file naming`](../../solution-structure/SKILL.md#canonical-test-project-and-http-file-naming).
`{TestTarget}` is the full canonical target selected there; never replace it with a service-only, component-only,
module-only, or `App` basename. The following is the file content example:

```http
@baseUrl = https://localhost:5001
@contentType = application/json
@id = 00000000-0000-0000-0000-000000000001

###
# Get all {ServiceName} items
# @name GetAll
GET {{baseUrl}}/api/v1/{ServiceKebabName}
Accept: {{contentType}}

###
# Get a specific {ServiceName} by ID
# @name GetById
GET {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
Accept: {{contentType}}

###
# Create a new {ServiceName}
# @name Create
POST {{baseUrl}}/api/v1/{ServiceKebabName}
Content-Type: {{contentType}}

{
  "data": "sample-data"
}

###
# Update an existing {ServiceName}
# @name Update
PUT {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
Content-Type: {{contentType}}

{
  "data": "updated-data"
}

###
# Delete a {ServiceName}
# @name Delete
DELETE {{baseUrl}}/api/v1/{ServiceKebabName}/{{id}}
```

## Single Action Pattern

For services with one primary action, use the same folder structure with fewer endpoints:

Generate `Execute{ServiceName}Request` in the selected request-contract boundary's `Requests/` role folder,
use the service response contract, and replace the neutral interface operation with the one consumed by the
endpoint. `{ServiceRoot}/Abstractions/Requests/Execute{ServiceName}Request.cs` is only the default
service-boundary path.

```csharp
// Existing I{ServiceName}.cs at the selected service-contract boundary
using {RequestContractNamespace};
using {ResponseContractNamespace};
```

```csharp
Task<{ServiceName}Response> ExecuteAsync(
    Execute{ServiceName}Request request,
    CancellationToken cancellationToken);
```

```csharp
// Requests/Execute{ServiceName}Request.cs at the selected request-contract boundary
namespace {RequestContractNamespace};

using System.Text.Json.Serialization;

public sealed record Execute{ServiceName}Request(
    [property: JsonPropertyName("data")] string Data);
```

For this branch, generate the service-owned API adapter context at the same `Serialization/` path and
namespace defined above, with exactly its selected wire types. Any producer-owned contract context remains at
the selected contract boundary; neither context changes the DTO declaration's ownership.

```csharp
namespace {ServiceNamespace}.Serialization;

using System.Text.Json.Serialization;
using {RequestContractNamespace};
using {ResponseContractNamespace};

[JsonSerializable(typeof(Execute{ServiceName}Request))]
[JsonSerializable(typeof({ServiceName}Response))]
internal partial class {ServiceName}JsonSerializerContext : JsonSerializerContext
{
}
```

```
Api/
├── {ServiceName}Api.cs
└── ExecuteEndpoint.cs
```

```csharp
namespace {ServiceNamespace}.Api;

using Microsoft.AspNetCore.Builder;

internal static class {ServiceName}Api
{
    internal static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/v1/{ServiceKebabName}")
           .WithTags("{ServiceName}")
           .WithOpenApi()
           .MapExecute();

        return app;
    }
}
```

```csharp
namespace {ServiceNamespace}.Api;

using System.Threading;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using {RequestContractNamespace};
using {ResponseContractNamespace};
using {ServiceContractNamespace};

public static class ExecuteEndpoint
{
    public static RouteGroupBuilder MapExecute(this RouteGroupBuilder group)
    {
        group.MapPost("/execute", async (
            [FromBody] Execute{ServiceName}Request request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            var result = await service.ExecuteAsync(request, cancellationToken);
            return Results.Ok(result);
        })
        .WithName("Execute{ServiceName}")
        .Produces<{ServiceName}Response>(StatusCodes.Status200OK)
        .ProducesValidationProblem(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }
}
```

## Required API verification

- Prove a disabled module is absent from DI and the Host mapping cascade does not traverse it, even when a
  child service flag is true.
- Prove a disabled standalone service is absent from DI and maps no routes.
- Prove an enabled parent registers `I{ServiceName}` before the snapshot-gated `Map{ServiceName}` wrapper maps
  the versioned `/api/v1/{ServiceKebabName}` routes; deliberately mismatched composition must fail at startup
  before a route is added.
- Verify validation failures use validation ProblemDetails and unexpected failures use centralized
  ProblemDetails handling.
- Verify OpenAPI contains the versioned operations and declared response schemas.
- Disable reflection fallback in a serialization test and round-trip every request/response type through
  `{ServiceName}JsonSerializerContext`.
- For unbounded collections, replace `GetAll` with the application's canonical paging contract and verify
  page-size limits; never generate an unbounded collection endpoint by default.
- For non-idempotent POST operations, require and test the application's idempotency-key contract.
