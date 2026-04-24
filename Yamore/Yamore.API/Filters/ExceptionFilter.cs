using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Hosting;
using Yamore.Model;

namespace Yamore.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IHostEnvironment _environment;

        public ExceptionFilter(
            ILogger<ExceptionFilter> logger,
            IHttpContextAccessor httpContextAccessor,
            IHostEnvironment environment)
        {
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
            _environment = environment;
        }

        public override void OnException(ExceptionContext context)
        {
            var http = _httpContextAccessor.HttpContext ?? context.HttpContext;
            var request = http.Request;
            var path = request.Path.HasValue ? request.Path.Value : string.Empty;
            var method = request.Method;
            var traceId = http.TraceIdentifier;
            var userId = http.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            var userName = http.User?.FindFirstValue(ClaimTypes.Name);
            var query = request.QueryString.HasValue ? request.QueryString.Value : string.Empty;

            var ex = context.Exception;

            if (ex is BusinessException)
            {
                _logger.LogWarning(
                    ex,
                    "BusinessException {Type} {Method} {Path}{Query} TraceId={TraceId} UserId={UserId} UserName={UserName} | {Message}",
                    ex.GetType().Name,
                    method,
                    path,
                    query,
                    traceId,
                    userId ?? "(anonymous)",
                    userName ?? "(n/a)",
                    ex.Message);
                context.ModelState.AddModelError("userError", ex.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else if (ex is UnauthorizedAccessException)
            {
                _logger.LogWarning(
                    ex,
                    "Unauthorized {Method} {Path}{Query} TraceId={TraceId} | {Message}",
                    method,
                    path,
                    query,
                    traceId,
                    ex.Message);
                var uMsg = _environment.IsDevelopment() ? ex.Message : "You are not allowed to perform this action.";
                context.ModelState.AddModelError("error", uMsg);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
            }
            else if (ex is NotFoundException)
            {
                _logger.LogInformation(
                    ex,
                    "NotFoundException {Method} {Path}{Query} TraceId={TraceId} | {Message}",
                    method,
                    path,
                    query,
                    traceId,
                    ex.Message);
                context.ModelState.AddModelError("error", ex.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
            }
            else if (ex is KeyNotFoundException)
            {
                _logger.LogInformation(
                    ex,
                    "Not found {Method} {Path}{Query} TraceId={TraceId} | {Message}",
                    method,
                    path,
                    query,
                    traceId,
                    ex.Message);
                context.ModelState.AddModelError("error", "The requested resource was not found.");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
            }
            else if (ex is InvalidOperationException)
            {
                _logger.LogWarning(
                    ex,
                    "InvalidOperation {Method} {Path}{Query} TraceId={TraceId} | {Message}",
                    method,
                    path,
                    query,
                    traceId,
                    ex.Message);
                var ioMsg = _environment.IsDevelopment()
                    ? ex.Message
                    : "The request could not be completed. Please check your input and try again.";
                context.ModelState.AddModelError("error", ioMsg);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else
            {
                _logger.LogError(
                    ex,
                    "Unhandled {Method} {Path}{Query} TraceId={TraceId} UserId={UserId} UserName={UserName} | {Message}",
                    method,
                    path,
                    query,
                    traceId,
                    userId ?? "(anonymous)",
                    userName ?? "(n/a)",
                    ex.Message);
                var serverMsg = _environment.IsDevelopment()
                    ? "Server side error, please check logs"
                    : "An unexpected error occurred. Please try again later.";
                context.ModelState.AddModelError("error", serverMsg);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            var list = context.ModelState.Where(x => x.Value!.Errors.Count > 0)
                .ToDictionary(x => x.Key, y => y.Value!.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}
