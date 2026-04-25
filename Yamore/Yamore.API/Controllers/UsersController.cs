using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.Extensions.Options;
using Yamore.API.Auth;
using Yamore.Model;
using Yamore.Model.Requests.User;
using Yamore.Model.SearchObjects;
using Yamore.Services.Interfaces;
using Yamore.Services.Services;

namespace Yamore.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Model.User, UsersSearchObject, UserInsertRequest, UserUpdateRequest, UserDeleteRequest>
    {
        private readonly IUsersService _usersService;
        private readonly IValidator<UserLoginRequest> _loginValidator;
        private readonly JwtTokenIssuer _jwt;
        private readonly IOptions<JwtOptions> _jwtOptions;
        private readonly IRefreshTokenStore _refreshTokens;
        private readonly IJtiRevocationService _jtiRevocation;

        public UsersController(
            IUsersService service,
            IValidator<UserLoginRequest> loginValidator,
            JwtTokenIssuer jwt,
            IOptions<JwtOptions> jwtOptions,
            IRefreshTokenStore refreshTokens,
            IJtiRevocationService jtiRevocation)
            : base(service)
        {
            _usersService = service;
            _loginValidator = loginValidator;
            _jwt = jwt;
            _jwtOptions = jwtOptions;
            _refreshTokens = refreshTokens;
            _jtiRevocation = jtiRevocation;
        }

        [HttpPut("{id}")]
        public override ActionResult<Model.User> Update(int id, UserUpdateRequest request)
        {
            if (User?.Identity?.IsAuthenticated == true
                && int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var selfId)
                && !User.IsInRole(AppRoles.Admin)
                && selfId != id)
            {
                return Forbid();
            }

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

                var isAdmin = User.IsInRole(AppRoles.Admin);
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


        /// <summary>Login — credentials must be sent in the request body (JSON), never the query string.</summary>
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<Model.LoginResponseDto>> Login([FromBody] UserLoginRequest? body)
        {
            if (body == null || string.IsNullOrWhiteSpace(body.Username) || string.IsNullOrEmpty(body.Password))
                return BadRequest(new { error = "username and password are required in the request body" });

            var validation = await _loginValidator.ValidateAsync(body, HttpContext.RequestAborted);
            if (!validation.IsValid)
            {
                var ms = new ModelStateDictionary();
                foreach (var e in validation.Errors)
                {
                    var key = string.IsNullOrWhiteSpace(e.PropertyName) ? string.Empty : e.PropertyName;
                    ms.AddModelError(key, e.ErrorMessage);
                }
                return ValidationProblem(ms);
            }

            var result = _usersService.Login(body.Username!.Trim(), body.Password!);
            if (result == null)
                return Unauthorized();
            return Ok(IssueTokens(result));
        }

        /// <summary>Exchanges a refresh token for a new access token and refresh token (rotation).</summary>
        [HttpPost("refresh")]
        [AllowAnonymous]
        public ActionResult<Model.LoginResponseDto> Refresh([FromBody] TokenRefreshRequest? request)
        {
            if (request is null || string.IsNullOrWhiteSpace(request.RefreshToken))
                return BadRequest(new { error = "RefreshToken is required" });

            var uNow = DateTime.UtcNow;
            var userId = _refreshTokens.GetValidUserIdIfActive(request.RefreshToken, uNow);
            if (userId is null)
                return Unauthorized();
            _refreshTokens.RevokeByRaw(request.RefreshToken, uNow);

            var u = _usersService.GetById(userId.Value);
            if (u == null)
                return Unauthorized();
            var dto = MapToLoginResponse(u);
            if (u.Status is false)
                return Unauthorized();
            return Ok(IssueTokens(dto));
        }

        /// <summary>Revokes the current access token (JTI) and the supplied refresh token server-side.</summary>
        [HttpPost("revoke")]
        [Authorize]
        public IActionResult Revoke([FromBody] LogoutRequest? request)
        {
            if (!TryGetBearerToken(Request, out _, out var jwt) || jwt is null)
            {
                return BadRequest("Missing or invalid access token in Authorization header.");
            }

            var jti = jwt.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Jti)?.Value
                ?? jwt.Payload.Jti;
            if (string.IsNullOrEmpty(jti))
            {
                return BadRequest("Access token is missing a JTI for revocation.");
            }

            _jtiRevocation.Revoke(jti, new DateTimeOffset(jwt.ValidTo, TimeSpan.Zero));

            if (request is { RefreshToken: { } r } && r.Length > 0)
            {
                _refreshTokens.RevokeByRaw(r, DateTime.UtcNow);
            }

            return NoContent();
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public ActionResult<Model.LoginResponseDto> Register([FromBody] UserInsertRequest request)
        {
            var user = _usersService.Register(request);
            var full = _usersService.GetById(user.UserId) ?? user;
            Response.Headers["X-Operation-Message"] = "Registration successful.";
            return Ok(IssueTokens(MapToLoginResponse(full)));
        }

        [HttpGet("owners")]
        [Authorize(Roles = AppRoles.Admin)]
        public ActionResult<PagedResponse<Model.LoginResponseDto>> GetOwners(
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = PagingConstraints.DefaultPageSize)
        {
            return Ok(_usersService.GetOwnersPaged(page, pageSize));
        }

        /// <summary>Suspends (Status=false) the specified user.</summary>
        [HttpPut("{id}/suspend")]
        [Authorize(Roles = AppRoles.Admin)]
        public ActionResult<Model.User> Suspend(int id)
        {
            var user = _usersService.GetById(id);
            if (user == null)
                return NotFound();

            var update = new UserUpdateRequest
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Phone = user.Phone,
                Username = user.Username,
                Status = false
            };
            var result = _usersService.Update(id, update);
            return Ok(result);
        }

        /// <summary>Activates (Status=true) the specified user.</summary>
        [HttpPut("{id}/activate")]
        [Authorize(Roles = AppRoles.Admin)]
        public ActionResult<Model.User> Activate(int id)
        {
            var user = _usersService.GetById(id);
            if (user == null)
                return NotFound();

            var update = new UserUpdateRequest
            {
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Phone = user.Phone,
                Username = user.Username,
                Status = true
            };
            var result = _usersService.Update(id, update);
            return Ok(result);
        }

        private static bool TryGetBearerToken(
            Microsoft.AspNetCore.Http.HttpRequest request,
            out string raw,
            out JwtSecurityToken? token)
        {
            raw = string.Empty;
            token = null;
            if (!request.Headers.TryGetValue("Authorization", out var h))
            {
                return false;
            }

            var v = h.ToString();
            if (!v.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            raw = v["Bearer ".Length..].Trim();
            if (string.IsNullOrEmpty(raw))
            {
                return false;
            }

            try
            {
                var handler = new JwtSecurityTokenHandler();
                token = handler.ReadJwtToken(raw);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static LoginResponseDto MapToLoginResponse(Model.User u)
        {
            var roles = u.UserRoles?
                .Select(ur => ur.Role?.Name)
                .Where(n => !string.IsNullOrEmpty(n))
                .Cast<string>()
                .Distinct()
                .ToList() ?? new List<string>();
            return new LoginResponseDto
            {
                UserId = u.UserId,
                FirstName = u.FirstName,
                LastName = u.LastName,
                Email = u.Email,
                Phone = u.Phone,
                Username = u.Username,
                Status = u.Status,
                Roles = roles,
            };
        }

        private LoginResponseDto IssueTokens(LoginResponseDto d)
        {
            var (a, _, exp) = _jwt.CreateAccess(d);
            d.AccessToken = a;
            d.AccessTokenExpiresIn = exp;
            d.TokenType = "Bearer";
            var days = _jwtOptions.Value.RefreshTokenDays;
            if (days < 1)
            {
                days = 14;
            }

            var (raw, _) = _refreshTokens.Create(d.UserId, TimeSpan.FromDays(days), DateTime.UtcNow);
            d.RefreshToken = raw;
            return d;
        }
    }
}
