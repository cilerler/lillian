# API Patterns

Minimal API patterns using MapGroup with chained endpoint methods.

## Api.cs

```csharp
namespace {Organization}.{Product}.Services.{ServiceName};

using {Organization}.{Product}.Services.{ServiceName}.Contracts;
using {Organization}.{Product}.Services.{ServiceName}.Exceptions;
using {Organization}.{Product}.Services.{ServiceName}.Models;

public static class Api
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

    private static RouteGroupBuilder MapGetAll(this RouteGroupBuilder group)
    {
        group.MapGet("/", async (
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.GetAllAsync(cancellationToken);
                return Results.Ok(result);
            }
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
        })
        .WithName("GetAll{ServiceName}")
        .Produces<IEnumerable<TModel>>(StatusCodes.Status200OK)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }

    private static RouteGroupBuilder MapGetById(this RouteGroupBuilder group)
    {
        group.MapGet("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.GetByIdAsync(id, cancellationToken);
                return result is null 
                    ? Results.NotFound() 
                    : Results.Ok(result);
            }
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
        })
        .WithName("Get{ServiceName}ById")
        .Produces<TModel>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }

    private static RouteGroupBuilder MapCreate(this RouteGroupBuilder group)
    {
        group.MapPost("/", async (
            [FromBody] TCreateRequest request,
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
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
        })
        .WithName("Create{ServiceName}")
        .Produces<TModel>(StatusCodes.Status201Created)
        .Produces(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }

    private static RouteGroupBuilder MapUpdate(this RouteGroupBuilder group)
    {
        group.MapPut("/{id:guid}", async (
            Guid id,
            [FromBody] TUpdateRequest request,
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
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
        })
        .WithName("Update{ServiceName}")
        .Produces<TModel>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status404NotFound)
        .Produces(StatusCodes.Status400BadRequest)
        .ProducesProblem(StatusCodes.Status500InternalServerError);

        return group;
    }

    private static RouteGroupBuilder MapDelete(this RouteGroupBuilder group)
    {
        group.MapDelete("/{id:guid}", async (
            Guid id,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var success = await service.DeleteAsync(id, cancellationToken);
                return success 
                    ? Results.NoContent() 
                    : Results.NotFound();
            }
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
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

## Single Action Pattern

For services with one primary action:

```csharp
public static class Api
{
    public static WebApplication Map{ServiceName}Api(this WebApplication app)
    {
        app.MapGroup("/api/{service-kebab}")
           .WithTags("{ServiceName}")
           .MapExecute();

        return app;
    }

    private static RouteGroupBuilder MapExecute(this RouteGroupBuilder group)
    {
        group.MapPost("/execute", async (
            [FromBody] TRequest request,
            [FromServices] I{ServiceName} service,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await service.ExecuteAsync(request, cancellationToken);
                return Results.Ok(result);
            }
            catch (Exception e)
            {
                return Results.Problem(e.Message);
            }
        });

        return group;
    }
}
```
