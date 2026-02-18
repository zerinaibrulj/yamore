using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using System.Security.Claims;
using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Model.User, UsersSearchObject, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>
    {
        private readonly IUsersService _usersService;

        public UsersController(IUsersService service)
            : base(service)
        {
            _usersService = service;
        }

        [HttpPut("{id}")]
        public override ActionResult<Model.User> Update(int id, UserUpdateRequest request)
        {
            // Normalize whitespace-only values so they don't accidentally trigger password update logic.
            request.OldPassword = string.IsNullOrWhiteSpace(request.OldPassword) ? null : request.OldPassword;
            request.Password = string.IsNullOrWhiteSpace(request.Password) ? null : request.Password;
            request.PasswordConfirmation = string.IsNullOrWhiteSpace(request.PasswordConfirmation) ? null : request.PasswordConfirmation;

            var passwordChangeRequested =
                request.Password != null ||
                request.PasswordConfirmation != null ||
                request.OldPassword != null;

            if (passwordChangeRequested)
            {
                if (User?.Identity?.IsAuthenticated != true)
                {
                    return Unauthorized(new ProblemDetails
                    {
                        Title = "Authentication required",
                        Detail = "To change a password, please log in and try again.",
                        Status = StatusCodes.Status401Unauthorized
                    });
                }

                var currentUserIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
                var currentUserIdParsed = int.TryParse(currentUserIdValue, out var currentUserId);
                if (!currentUserIdParsed)
                {
                    return Unauthorized(new ProblemDetails
                    {
                        Title = "Authentication required",
                        Detail = "Unable to determine the current user. Please log in again and try again.",
                        Status = StatusCodes.Status401Unauthorized
                    });
                }

                var isAdmin = User.IsInRole("Admin");
                var isSelfEdit = currentUserId == id;

                if (!isAdmin && isSelfEdit)
                {
                    if (request.OldPassword == null)
                    {
                        var modelState = new ModelStateDictionary();
                        modelState.AddModelError(nameof(UserUpdateRequest.OldPassword),
                            "Old password is required when changing your own password.");
                        return ValidationProblem(modelState);
                    }

                    if (!_usersService.VerifyPassword(id, request.OldPassword))
                    {
                        var modelState = new ModelStateDictionary();
                        modelState.AddModelError(nameof(UserUpdateRequest.OldPassword),
                            "Old password is incorrect. Please enter your current password.");
                        return ValidationProblem(modelState);
                    }
                }
            }

            var result = _service.Update(id, request);
            Response.Headers["X-Operation-Message"] = "User updated successfully.";
            return Ok(result);
        }


        [HttpPost("login")]
        [AllowAnonymous]
        public Model.User Login(string username, string password)
        {
            return (_service as IUsersService).Login(username, password);
        }
    }
}
