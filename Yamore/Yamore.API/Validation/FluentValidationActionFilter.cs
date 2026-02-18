using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Yamore.API.Validation;

public sealed class FluentValidationActionFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        // Let ASP.NET Core handle null-body / binding errors first.
        if (!context.ModelState.IsValid)
        {
            await next();
            return;
        }

        foreach (var (_, argument) in context.ActionArguments)
        {
            if (argument is null)
                continue;

            var validatorType = typeof(IValidator<>).MakeGenericType(argument.GetType());
            var validator = context.HttpContext.RequestServices.GetService(validatorType);
            if (validator is null)
                continue;

            var validateAsync = validatorType.GetMethod(nameof(IValidator<object>.ValidateAsync), new[]
            {
                argument.GetType(),
                typeof(CancellationToken)
            });

            if (validateAsync is null)
                continue;

            var task = (Task)validateAsync.Invoke(validator, new object[] { argument, context.HttpContext.RequestAborted })!;
            await task.ConfigureAwait(false);

            var resultProperty = task.GetType().GetProperty("Result");
            if (resultProperty?.GetValue(task) is not FluentValidation.Results.ValidationResult validationResult)
                continue;

            if (!validationResult.IsValid)
            {
                foreach (var error in validationResult.Errors)
                {
                    var key = string.IsNullOrWhiteSpace(error.PropertyName) ? string.Empty : error.PropertyName;
                    context.ModelState.AddModelError(key, error.ErrorMessage);
                }

                var problem = new ValidationProblemDetails(context.ModelState)
                {
                    Title = "Validation failed",
                    Detail = "Please fix the highlighted fields and try again.",
                    Status = StatusCodes.Status400BadRequest
                };

                context.Result = new BadRequestObjectResult(problem);
                return;
            }
        }

        await next();
    }
}

