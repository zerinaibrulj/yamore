using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;
using Yamore.Model;

namespace Yamore.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        ILogger<ExceptionFilter> Logger { get; set; }
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            Logger = logger;
        }


        public override void OnException(ExceptionContext context)
        {

            Logger.LogError(context.Exception, context.Exception.Message);



            if(context.Exception is UserException)
            {
                context.ModelState.AddModelError("userError", context.Exception.Message);      // json struktura se treba prikazati na swaggeru
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;    //400
            }
            else
            {
                context.ModelState.AddModelError("ERROR", "Server side error, please check logs");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;   //500
            }

            var list = context.ModelState.Where(x => x.Value.Errors.Count() > 0)              // response pretvaramo u json
                .ToDictionary(x => x.Key, y => y.Value.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}
