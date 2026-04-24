using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Yamore.API.Services;
using Yamore.Model;

namespace Yamore.API.Controllers;

/// <summary>Stripe webhooks: verify signature, then the same idempotent finalization as <c>POST Payment/confirm</c> for applicable events.</summary>
[ApiController]
[Route("api/stripe")]
[AllowAnonymous]
[IgnoreAntiforgeryToken]
public class StripeWebhookController : ControllerBase
{
    private readonly IPaymentWorkflowService _paymentWorkflow;
    private readonly ILogger<StripeWebhookController> _logger;

    public StripeWebhookController(
        IPaymentWorkflowService paymentWorkflow,
        ILogger<StripeWebhookController> logger)
    {
        _paymentWorkflow = paymentWorkflow;
        _logger = logger;
    }

    [HttpPost("webhook")]
    [Consumes("application/json")]
    public async Task<IActionResult> Webhook(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body);
        var json = await reader.ReadToEndAsync().ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(json))
        {
            _logger.LogWarning("Empty Stripe webhook body.");
            return BadRequest();
        }

        var signature = Request.Headers["Stripe-Signature"].ToString();
        try
        {
            var result = await _paymentWorkflow
                .ProcessStripeWebhookAsync(json, signature, cancellationToken)
                .ConfigureAwait(false);

            return result == StripeWebhookHandleResult.NotConfigured
                ? Ok(new { received = true, configured = false })
                : Ok(new { received = true, configured = true, result = result.ToString() });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized();
        }
    }
}
